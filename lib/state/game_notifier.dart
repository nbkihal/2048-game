import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/audio_controller.dart';
import '../core/constants.dart';
import '../logic/board_ops.dart';
import '../logic/game_engine.dart';
import '../logic/game_rules.dart';
import '../logic/spawn.dart';
import '../models/board.dart';
import '../models/direction.dart';
import '../models/game_status.dart';
import '../models/game_tool.dart';
import '../models/position.dart';
import '../models/stage.dart';
import 'game_state.dart';

/// Wires the pure logic in `logic/` to the UI.
///
/// The notifier owns the three things the logic layer deliberately does not:
/// the random source, the side effects (sound, haptics, score reporting) and
/// the snapshot written to disk so a killed app can resume.
class GameNotifier extends StateNotifier<GameState> {
  factory GameNotifier({
    required Stage stage,
    required int bestScore,
    required AudioController audio,
    required void Function(GameState state) onOutcome,
    void Function(GameState state)? onSnapshot,
    GameState? resumeFrom,
    Random? random,
  }) {
    final generator = random ?? Random();
    return GameNotifier._(
      audio: audio,
      random: generator,
      onOutcome: onOutcome,
      onSnapshot: onSnapshot,
      initial: resumeFrom ?? _freshState(stage, bestScore, generator),
    );
  }

  GameNotifier._({
    required this.audio,
    required this.random,
    required this.onOutcome,
    required this.onSnapshot,
    required GameState initial,
  }) : super(initial);

  final AudioController audio;
  final Random random;

  /// Called once when an attempt ends, so progress can be persisted outside the
  /// notifier's own state.
  final void Function(GameState state) onOutcome;

  /// Called after every committed change so the run can be resumed later.
  final void Function(GameState state)? onSnapshot;

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

  bool get canUndo => _history.isNotEmpty && hasCharges(state.undosLeft);

  /// Starts the stage over with a fresh board. Tools and rewinds come back with
  /// it — the allowance is per attempt, not per stage.
  void restart() {
    _history.clear();
    state = _freshState(state.stage, state.displayBestScore, random);
    audio.play(Sfx.tap);
    _snapshot();
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
    final stage = state.stage;

    // A fuse burns on the move, before the spawn: a bomb dropped this move
    // gets its full count, and one already on the board loses a tick.
    var board = tickFuses(result.board);

    final spawn = spawnTile(board, id: state.nextTileId, random: random);
    board = spawn.board;

    // Keep exactly one bomb alive on a bomb stage, so the pressure is steady
    // rather than a pile-up.
    final bomb = spawn.tile;
    if (stage.hasBomb && bomb != null && !hasArmedBomb(board)) {
      board = armBomb(board, bomb.id, stage.bombFuse!);
    }

    final rotateEvery = stage.rotateEveryMoves;
    if (rotateEvery != null && movesUsed % rotateEvery == 0) {
      board = rotateBoardClockwise(board);
    }

    final status = evaluateStatus(
      board: board,
      stage: stage,
      movesUsed: movesUsed,
    );

    state = state.copyWith(
      board: board,
      score: state.score + result.gainedScore,
      movesUsed: movesUsed,
      nextTileId: spawn.spawned ? state.nextTileId + 1 : state.nextTileId,
      mergedTileIds: result.mergedTileIds,
      mergedAwayTiles: result.mergedAwayTiles,
      lastGain: result.gainedScore,
      moveSerial: state.moveSerial + 1,
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

    if (state.status.isOver) {
      _finishAttempt();
    } else {
      _snapshot();
    }
  }

  /// Rewinds one move. The spawned tile disappears along with the merge, which
  /// is the behaviour players expect from an undo in this genre.
  void undo() {
    if (!canUndo || state.isPaused) return;
    final previous = _history.removeLast();
    // The rewind spends a charge and stains the run: the board goes back, the
    // fact that it was rewound does not.
    state = previous.copyWith(
      undosLeft: spendCharge(state.undosLeft),
      usedUndo: true,
      hammersLeft: state.hammersLeft,
      shufflesLeft: state.shufflesLeft,
      disarmTool: true,
    );
    audio.play(Sfx.tap);
    audio.haptic(HapticStrength.light);
    _snapshot();
  }

  /// Puts the board into tile-picking mode for the hammer.
  void armHammer() {
    if (!state.acceptsTools || !state.canHammer) return;
    state = state.copyWith(armedTool: GameTool.hammer);
    audio.play(Sfx.tap);
  }

  void disarmTool() {
    if (state.armedTool == null) return;
    state = state.copyWith(disarmTool: true);
    audio.play(Sfx.tap);
  }

  /// Spends the hammer on one tile.
  ///
  /// A removal is not a move: it costs no move budget, burns no fuse and
  /// spawns nothing. It can still open a jammed board, so the status is
  /// re-evaluated afterwards.
  void useHammer(int tileId) {
    if (state.armedTool != GameTool.hammer || !state.canHammer) return;

    _pushHistory();
    final board = removeTile(state.board, tileId);
    state = state.copyWith(
      board: board,
      hammersLeft: spendCharge(state.hammersLeft),
      disarmTool: true,
      mergedTileIds: const [],
      mergedAwayTiles: const [],
      status: evaluateStatus(
        board: board,
        stage: state.stage,
        movesUsed: state.movesUsed,
      ),
    );
    audio.play(Sfx.merge);
    audio.haptic(HapticStrength.medium);
    _afterToolUse();
  }

  /// Deals the same tiles back out across the board.
  void useShuffle() {
    if (!state.acceptsTools || !state.canShuffle) return;

    _pushHistory();
    final board = shuffleTiles(state.board, random);
    state = state.copyWith(
      board: board,
      shufflesLeft: spendCharge(state.shufflesLeft),
      disarmTool: true,
      mergedTileIds: const [],
      mergedAwayTiles: const [],
      status: evaluateStatus(
        board: board,
        stage: state.stage,
        movesUsed: state.movesUsed,
      ),
    );
    audio.play(Sfx.spawn);
    audio.haptic(HapticStrength.medium);
    _afterToolUse();
  }

  void pause() {
    if (!state.status.isPlayable && !state.keptGoing) return;
    state = state.copyWith(isPaused: true, disarmTool: true);
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
    _snapshot();
  }

  /// Marks the current win/lose dialog as shown.
  void acknowledgeOutcome() {
    if (!state.outcomeAcknowledged) {
      state = state.copyWith(outcomeAcknowledged: true);
    }
  }

  void _afterToolUse() {
    if (state.status.isOver) {
      _finishAttempt();
    } else {
      _snapshot();
    }
  }

  void _pushHistory() {
    _history.add(state);
    if (_history.length > kUndoHistoryLimit) _history.removeAt(0);
  }

  void _snapshot() => onSnapshot?.call(state);

  void _finishAttempt() {
    audio.play(state.status == GameStatus.won ? Sfx.win : Sfx.lose);
    audio.haptic(HapticStrength.heavy);
    onOutcome(state);
    // A finished attempt is not resumable; the listener clears the saved run.
    _snapshot();
  }
}
