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
    this.unlockedByDefault = false,
  }) : assert(gridSize > 1, 'a stage needs at least a 2x2 board'),
       assert(
         moveLimit == null || moveLimit > 0,
         'a move limit must be positive',
       ),
       assert(randomBlockedCells >= 0, 'blocked cell count cannot be negative');

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

  /// Whether the stage is playable before anything has been cleared.
  final bool unlockedByDefault;

  bool get isEndless => targetTile == null;

  bool get hasMoveLimit => moveLimit != null;

  bool get hasBlockedCells => blockedCells.isNotEmpty || randomBlockedCells > 0;

  bool get hasTwist => hasMoveLimit || hasBlockedCells;

  @override
  String toString() =>
      'Stage($id "$name" ${gridSize}x$gridSize '
      '-> ${targetTile ?? '∞'})';
}
