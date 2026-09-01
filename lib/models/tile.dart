/// A single numbered tile.
///
/// The [id] is stable for the whole life of a tile: when a tile slides we keep
/// its id and only change [row]/[col], which is what lets the UI animate the
/// movement instead of tearing down and rebuilding the widget.
class Tile {
  const Tile({
    required this.id,
    required this.value,
    required this.row,
    required this.col,
    this.isNew = false,
    this.mergedFrom = false,
  });

  final int id;
  final int value;
  final int row;
  final int col;

  /// Spawned by the move that produced this board -> spawn animation.
  final bool isNew;

  /// Produced by a merge during this move -> pop animation.
  final bool mergedFrom;

  Tile copyWith({
    int? id,
    int? value,
    int? row,
    int? col,
    bool? isNew,
    bool? mergedFrom,
  }) {
    return Tile(
      id: id ?? this.id,
      value: value ?? this.value,
      row: row ?? this.row,
      col: col ?? this.col,
      isNew: isNew ?? this.isNew,
      mergedFrom: mergedFrom ?? this.mergedFrom,
    );
  }

  /// Same tile with both animation flags cleared. Used when a board is carried
  /// into the next move so last move's flags do not replay.
  Tile withoutAnimationFlags() =>
      isNew || mergedFrom ? copyWith(isNew: false, mergedFrom: false) : this;

  @override
  bool operator ==(Object other) =>
      other is Tile &&
      other.id == id &&
      other.value == value &&
      other.row == row &&
      other.col == col &&
      other.isNew == isNew &&
      other.mergedFrom == mergedFrom;

  @override
  int get hashCode => Object.hash(id, value, row, col, isNew, mergedFrom);

  @override
  String toString() =>
      'Tile(#$id v$value @$row,$col'
      '${isNew ? ' new' : ''}${mergedFrom ? ' merged' : ''})';
}
