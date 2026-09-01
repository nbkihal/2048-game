import '../core/constants.dart';
import '../data/stages_data.dart';
import '../models/board.dart';
import '../models/game_status.dart';
import '../models/game_tool.dart';
import '../models/stage.dart';
import '../models/tile.dart';

/// An immutable snapshot of one stage attempt.
///
/// Every move produces a whole new instance, which is what makes undo a plain
/// list of previous snapshots — and what makes resuming a killed app a matter
/// of writing one of these to disk.
class GameState {
  const GameState({
    required this.stage,
    required this.board,
    required this.score,
    required this.bestScore,
    required this.status,
    required this.movesUsed,
    required this.nextTileId,
    this.mergedTileIds = const [],
    this.mergedAwayTiles = const [],
    this.keptGoing = false,
    this.isPaused = false,
    this.outcomeAcknowledged = false,
    this.undosLeft = kUndoAllowance,
    this.hammersLeft = kHammerAllowance,
    this.shufflesLeft = kShuffleAllowance,
    this.usedUndo = false,
    this.armedTool,
    this.lastGain = 0,
    this.moveSerial = 0,
  });

  final Stage stage;
  final Board board;
  final int score;

  /// Best score recorded for this stage before the current attempt.
  final int bestScore;

  final GameStatus status;
  final int movesUsed;

  /// Id handed to the next spawned tile. Kept in the snapshot so undo rewinds
  /// it too and ids never collide after a rewind.
  final int nextTileId;

  /// Products of the merges in the move that produced this state.
  final List<int> mergedTileIds;

  /// Tiles absorbed by those merges, positioned where they travelled to.
  final List<Tile> mergedAwayTiles;

  /// The player reached the target and chose to carry on for score.
  final bool keptGoing;

  final bool isPaused;

  /// The win/lose dialog for this outcome has already been shown, so it does
  /// not reappear on every rebuild.
  final bool outcomeAcknowledged;

  /// Rewinds left in this attempt. Undo is a resource, not a safety net — an
  /// unlimited one would quietly cancel the game-over screen.
  final int undosLeft;

  final int hammersLeft;
  final int shufflesLeft;

  /// Whether a rewind was spent at any point, which costs the "clean" medal
  /// even though the board itself was put back.
  final bool usedUndo;

  /// The tool waiting for a target. Only [GameTool.hammer] ever sits here.
  final GameTool? armedTool;

  /// Score added by the move that produced this state, for the popup.
  final int lastGain;

  /// Counts up once per valid move. The score popup keys off it so two
  /// identical gains in a row still animate twice.
  final int moveSerial;

  int get displayBestScore => score > bestScore ? score : bestScore;

  /// True while the player may swipe.
  bool get acceptsInput =>
      !isPaused &&
      armedTool == null &&
      (status.isPlayable || (status == GameStatus.won && keptGoing));

  /// True while a tool may be spent — the same states that accept a swipe, plus
  /// the moment a tool is already armed.
  bool get acceptsTools =>
      !isPaused &&
      (status.isPlayable || (status == GameStatus.won && keptGoing));

  bool get hasPendingOutcome => status.isOver && !outcomeAcknowledged;

  /// Merges produced by the last move — the "chain" the popup celebrates.
  int get lastMergeCount => mergedTileIds.length;

  bool get canHammer => hasCharges(hammersLeft);

  bool get canShuffle => hasCharges(shufflesLeft);

  /// Whether this attempt is worth writing to disk: a finished or untouched
  /// attempt has nothing to resume.
  bool get isResumable => status.isPlayable && movesUsed > 0;

  /// The bomb currently ticking, if the stage has one.
  Tile? get armedBomb {
    for (final tile in board.tiles) {
      if (tile.isBomb) return tile;
    }
    return null;
  }

  GameState copyWith({
    Stage? stage,
    Board? board,
    int? score,
    int? bestScore,
    GameStatus? status,
    int? movesUsed,
    int? nextTileId,
    List<int>? mergedTileIds,
    List<Tile>? mergedAwayTiles,
    bool? keptGoing,
    bool? isPaused,
    bool? outcomeAcknowledged,
    int? undosLeft,
    int? hammersLeft,
    int? shufflesLeft,
    bool? usedUndo,
    GameTool? armedTool,
    bool disarmTool = false,
    int? lastGain,
    int? moveSerial,
  }) {
    return GameState(
      stage: stage ?? this.stage,
      board: board ?? this.board,
      score: score ?? this.score,
      bestScore: bestScore ?? this.bestScore,
      status: status ?? this.status,
      movesUsed: movesUsed ?? this.movesUsed,
      nextTileId: nextTileId ?? this.nextTileId,
      mergedTileIds: mergedTileIds ?? this.mergedTileIds,
      mergedAwayTiles: mergedAwayTiles ?? this.mergedAwayTiles,
      keptGoing: keptGoing ?? this.keptGoing,
      isPaused: isPaused ?? this.isPaused,
      outcomeAcknowledged: outcomeAcknowledged ?? this.outcomeAcknowledged,
      undosLeft: undosLeft ?? this.undosLeft,
      hammersLeft: hammersLeft ?? this.hammersLeft,
      shufflesLeft: shufflesLeft ?? this.shufflesLeft,
      usedUndo: usedUndo ?? this.usedUndo,
      armedTool: disarmTool ? null : (armedTool ?? this.armedTool),
      lastGain: lastGain ?? this.lastGain,
      moveSerial: moveSerial ?? this.moveSerial,
    );
  }

  /// The fields worth surviving a force-close. Animation transients and the
  /// paused flag are deliberately dropped — a resumed run starts still.
  Map<String, dynamic> toJson() => {
    'stage': stage.id,
    'board': board.toJson(),
    'score': score,
    'moves': movesUsed,
    'nextId': nextTileId,
    'keptGoing': keptGoing,
    'undos': undosLeft,
    'hammers': hammersLeft,
    'shuffles': shufflesLeft,
    'usedUndo': usedUndo,
    'serial': moveSerial,
  };

  /// Rebuilds a snapshot, or returns `null` when the payload no longer matches
  /// the stage table — a stage retuned between versions must not crash a load.
  static GameState? fromJson(Map<String, dynamic> json, {required int best}) {
    final stageId = json['stage'] as int?;
    if (stageId == null) return null;
    final matches = kAllStages.where((s) => s.id == stageId);
    if (matches.isEmpty) return null;
    final stage = matches.first;

    final board = BoardJson.fromJson(
      Map<String, dynamic>.from(json['board'] as Map),
    );
    if (board.size != stage.gridSize) return null;

    return GameState(
      stage: stage,
      board: board,
      score: json['score'] as int? ?? 0,
      bestScore: best,
      status: GameStatus.playing,
      movesUsed: json['moves'] as int? ?? 0,
      nextTileId: json['nextId'] as int? ?? board.tileCount + 1,
      keptGoing: json['keptGoing'] as bool? ?? false,
      undosLeft: json['undos'] as int? ?? kUndoAllowance,
      hammersLeft: json['hammers'] as int? ?? kHammerAllowance,
      shufflesLeft: json['shuffles'] as int? ?? kShuffleAllowance,
      usedUndo: json['usedUndo'] as bool? ?? false,
      moveSerial: json['serial'] as int? ?? 0,
    );
  }
}
