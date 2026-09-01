import '../models/board.dart';
import '../models/game_status.dart';
import '../models/stage.dart';
import '../models/tile.dart';

/// An immutable snapshot of one stage attempt.
///
/// Every move produces a whole new instance, which is what makes undo a plain
/// list of previous snapshots.
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

  int get displayBestScore => score > bestScore ? score : bestScore;

  /// True while the player may swipe.
  bool get acceptsInput =>
      !isPaused && (status.isPlayable || (status == GameStatus.won && keptGoing));

  bool get hasPendingOutcome => status.isOver && !outcomeAcknowledged;

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
    );
  }
}
