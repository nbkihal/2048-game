import 'position.dart';

/// One level of the progression. Stages are pure data (see
/// `data/stages_data.dart`); adding a stage must never require new UI code.
class Stage {
  const Stage({
    required this.id,
    required this.name,
    required this.gridSize,
    required this.targetTile,
    this.subtitle = '',
    this.moveLimit,
    this.blockedCells = const [],
    this.randomBlockedCells = 0,
    this.bombFuse,
    this.rotateEveryMoves,
    this.unlockedByDefault = false,
  }) : assert(gridSize > 1, 'a stage needs at least a 2x2 board'),
       assert(
         moveLimit == null || moveLimit > 0,
         'a move limit must be positive',
       ),
       assert(randomBlockedCells >= 0, 'blocked cell count cannot be negative'),
       assert(bombFuse == null || bombFuse > 1, 'a fuse needs room to burn'),
       assert(
         rotateEveryMoves == null || rotateEveryMoves > 1,
         'rotating every move would make the board unreadable',
       );

  final int id;
  final String name;

  /// Short flavour line shown on the stage-select card.
  final String subtitle;

  final int gridSize;

  /// Value the player must reach to clear the stage. `null` = endless.
  final int? targetTile;

  /// Twist: the stage is lost if the target is not reached within this many
  /// valid moves.
  final int? moveLimit;

  /// Twist: cells that are walled off for the whole stage, fixed by design.
  final List<Position> blockedCells;

  /// Twist: additional walls placed at random when the stage starts.
  final int randomBlockedCells;

  /// Twist: one tile on the board is always a bomb, spawning with this many
  /// moves on its counter. Merging it defuses it; letting the counter reach
  /// zero ends the run. Keeping exactly one alive at a time is what makes the
  /// twist a steady pressure rather than a pile-up.
  final int? bombFuse;

  /// Twist: the whole board turns a quarter turn every this many valid moves,
  /// tiles and walls alike.
  final int? rotateEveryMoves;

  /// Whether the stage is playable before anything has been cleared.
  final bool unlockedByDefault;

  bool get isEndless => targetTile == null;

  bool get hasMoveLimit => moveLimit != null;

  bool get hasBlockedCells => blockedCells.isNotEmpty || randomBlockedCells > 0;

  bool get hasBomb => bombFuse != null;

  bool get rotates => rotateEveryMoves != null;

  bool get hasTwist =>
      hasMoveLimit || hasBlockedCells || hasBomb || rotates;

  /// The move count a clean run should beat, for the "efficient" medal.
  ///
  /// A spawn is worth ~1.1 twos, so a target of N needs about N/2.2 spawns at
  /// absolute best; par sits at 1.6x that, which a tidy run reaches and a
  /// flailing one does not. Endless stages have no par.
  int? get parMoves {
    final target = targetTile;
    if (target == null) return null;
    return (target / 2.2 * 1.6).round();
  }

  @override
  String toString() =>
      'Stage($id "$name" ${gridSize}x$gridSize '
      '-> ${targetTile ?? '∞'})';
}
