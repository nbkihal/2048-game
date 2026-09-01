/// Lifecycle of a single stage attempt.
enum GameStatus {
  /// Stage loaded but the player has not moved yet.
  idle,

  /// Normal play.
  playing,

  /// The stage target was reached. The player may keep going for score.
  won,

  /// No legal move remains, or the move budget ran out before the target.
  lost,
}

extension GameStatusX on GameStatus {
  bool get isOver => this == GameStatus.won || this == GameStatus.lost;
  bool get isPlayable => this == GameStatus.idle || this == GameStatus.playing;
}
