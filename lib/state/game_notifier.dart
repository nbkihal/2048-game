import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/audio_controller.dart';
import '../core/constants.dart';
import '../logic/game_engine.dart';
import '../logic/game_rules.dart';
import '../logic/spawn.dart';
import '../models/board.dart';
import '../models/direction.dart';
import '../models/game_status.dart';
import '../models/position.dart';
import '../models/stage.dart';
import 'game_state.dart';

/// Wires the pure logic in `logic/` to the UI.
///
/// The notifier owns the two things the logic layer deliberately does not: the
/// random source and the side effects (sound, haptics, score reporting).
class GameNotifier extends StateNotifier<GameState> {
  factory GameNotifier({
    required Stage stage,
    required int bestScore,
    required AudioController audio,
    required void Function(GameState state) onOutcome,
    Random? random,
  }) {
    final generator = random ?? Random();
    return GameNotifier._(
      audio: audio,
      random: generator,
      onOutcome: onOutcome,
      initial: _freshState(stage, bestScore, generator),
    );
  }

  GameNotifier._({
    required this.audio,
    required this.random,
    required this.onOutcome,
    required GameState initial,
  }) : super(initial);

  final AudioController audio;
  final Random random;

  /// Called once when an attempt ends, so progress can be persisted outside the
  /// notifier's own state.
  final void Function(GameState state) onOutcome;

  /// Previous snapshots, most recent last. Bounded so a long game does not grow
  /// unbounded in memory.
  final List<GameState> _history = [];

  static GameState _freshState(Stage stage, int bestScore, Random random) {
    final blocked = <Position>{
      ...stage.blockedCells,
      ...pickRandomBlockedCells(
        stage.gridSize,
        count: stage.randomBlockedCells,
        random: random,
        exclude: stage.blockedCells.toSet(),
      ),
    };

    final opening = spawnInitialTiles(
      Board.empty(stage.gridSize, blocked: blocked),
      firstId: 1,
      random: random,
    );

    return GameState(
      stage: stage,
      board: opening.board,
      score: 0,
      bestScore: bestScore,
      status: GameStatus.idle,
      movesUsed: 0,
      nextTileId: opening.nextId,
    );
  }

  bool get canUndo => _history.isNotEmpty;

  /// Starts the stage over with a fresh board.
  void restart() {
    _history.clear();
    state = _freshState(state.stage, state.displayBestScore, random);
    audio.play(Sfx.tap);
  }

  void swipe(Direction direction) {
    if (!state.acceptsInput) return;

    final result = move(state.board, direction);
    if (!result.moved) {
      // An illegal swipe is not silence — a light tick tells the player the
      // input registered but the board could not answer it.
      audio.haptic(HapticStrength.light);
      return;
    }

    _pushHistory();

    final movesUsed = state.movesUsed + 1;
    final spawn = spawnTile(result.board, id: state.nextTileId, random: random);
    final score = state.score + result.gainedScore;
    final status = evaluateStatus(
      board: spawn.board,
      stage: state.stage,
      movesUsed: movesUsed,
    );

    state = state.copyWith(
      board: spawn.board,
      score: score,
      movesUsed: movesUsed,
      nextTileId: spawn.spawned ? state.nextTileId + 1 : state.nextTileId,
      mergedTileIds: result.mergedTileIds,
      mergedAwayTiles: result.mergedAwayTiles,
      // Winning again after "keep going" must not re-open the dialog.
      status: state.keptGoing && status == GameStatus.won
          ? GameStatus.playing
          : status,
    );

    audio.playMove(merged: result.mergedTileIds.isNotEmpty);
    audio.haptic(
      result.mergedTileIds.isEmpty
          ? HapticStrength.light
          : HapticStrength.medium,
    );

    if (state.status.isOver) _finishAttempt();
  }

  /// Rewinds one move. The spawned tile disappears along with the merge, which
  /// is the behaviour players expect from an undo in this genre.
  void undo() {
    if (_history.isEmpty || state.isPaused) return;
    state = _history.removeLast();
    audio.play(Sfx.tap);
    audio.haptic(HapticStrength.light);
  }

  void pause() {
    if (!state.status.isPlayable && !state.keptGoing) return;
    state = state.copyWith(isPaused: true);
    audio.play(Sfx.tap);
  }

  void resume() {
    state = state.copyWith(isPaused: false);
    audio.play(Sfx.tap);
  }

  /// Dismisses the win dialog and keeps the board playable for score.
  void keepGoing() {
    state = state.copyWith(
      keptGoing: true,
      status: GameStatus.playing,
      outcomeAcknowledged: true,
    );
  }

  /// Marks the current win/lose dialog as shown.
  void acknowledgeOutcome() {
    if (!state.outcomeAcknowledged) {
      state = state.copyWith(outcomeAcknowledged: true);
    }
  }

  void _pushHistory() {
    _history.add(state);
    if (_history.length > kUndoHistoryLimit) _history.removeAt(0);
  }

  void _finishAttempt() {
    audio.play(state.status == GameStatus.won ? Sfx.win : Sfx.lose);
    audio.haptic(HapticStrength.heavy);
    onOutcome(state);
  }
}
