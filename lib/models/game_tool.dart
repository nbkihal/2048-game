/// A power-up the player can spend during an attempt.
///
/// [hammer] needs a target, so arming it puts the board into a picking state;
/// [shuffle] and undo apply the moment they are tapped.
enum GameTool { hammer, shuffle }

extension GameToolX on GameTool {
  String get label => switch (this) {
    GameTool.hammer => 'Hammer',
    GameTool.shuffle => 'Shuffle',
  };

  /// What the tool does, for the how-to-play card.
  String get blurb => switch (this) {
    GameTool.hammer => 'REMOVE ANY ONE TILE',
    GameTool.shuffle => 'DEAL THE SAME TILES OUT AGAIN',
  };
}
