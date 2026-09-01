import '../models/board.dart';
import '../models/direction.dart';
import '../models/game_status.dart';
import '../models/stage.dart';
import 'game_engine.dart';

/// Win / lose evaluation. Stage twists live here as small conditionals on top
/// of the generic rules, so the slide/merge core stays untouched.

/// True once any tile has reached the stage target. Endless stages never win.
bool hasReachedTarget(Board board, int? targetTile) {
  if (targetTile == null) return false;
  return board.highestValue >= targetTile;
}

/// True when at least one of the four swipes would change the board.
bool canMove(Board board) {
  for (final direction in Direction.values) {
    if (canMoveInDirection(board, direction)) return true;
  }
  return false;
}

/// Twist: with a move budget, the player is only allowed to keep swiping while
/// moves remain.
bool hasMovesLeft(Stage stage, int movesUsed) {
  final limit = stage.moveLimit;
  return limit == null || movesUsed < limit;
}

/// Moves still available under the stage's budget, or `null` when unlimited.
int? movesRemaining(Stage stage, int movesUsed) {
  final limit = stage.moveLimit;
  return limit == null ? null : (limit - movesUsed).clamp(0, limit);
}

/// The status of a stage attempt after [movesUsed] valid moves.
///
/// Order matters: reaching the target wins even on the very last allowed move.
GameStatus evaluateStatus({
  required Board board,
  required Stage stage,
  required int movesUsed,
}) {
  if (hasReachedTarget(board, stage.targetTile)) return GameStatus.won;
  // Truly stuck: no free cell and no merge available in any direction.
  if (!canMove(board)) return GameStatus.lost;
  // Twist: the budget ran out before the target was reached.
  if (!hasMovesLeft(stage, movesUsed)) return GameStatus.lost;
  return movesUsed == 0 ? GameStatus.idle : GameStatus.playing;
}

/// Progress toward the stage target in the 0..1 range, by exponent rather than
/// raw value so the bar advances one step per doubling. Endless stages report
/// 0 (there is nothing to fill).
double targetProgress(Board board, int? targetTile) {
  if (targetTile == null || targetTile < 2) return 0;
  final highest = board.highestValue;
  if (highest < 2) return 0;
  if (highest >= targetTile) return 1;
  final steps = _log2(targetTile) - 1;
  if (steps <= 0) return 1;
  return ((_log2(highest) - 1) / steps).clamp(0.0, 1.0);
}

int _log2(int value) {
  var result = 0;
  var current = value;
  while (current > 1) {
    current >>= 1;
    result++;
  }
  return result;
}
