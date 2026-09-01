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
    this.fuse,
  });

  final int id;
  final int value;
  final int row;
  final int col;

  /// Spawned by the move that produced this board -> spawn animation.
  final bool isNew;

  /// Produced by a merge during this move -> pop animation.
  final bool mergedFrom;

  /// Twist: moves left before this tile detonates and ends the run. `null` on
  /// an ordinary tile, which is every tile outside a bomb stage. Merging the
  /// tile defuses it, because the product of a merge is a new tile.
  final int? fuse;

  bool get isBomb => fuse != null;

  Tile copyWith({
    int? id,
    int? value,
    int? row,
    int? col,
    bool? isNew,
    bool? mergedFrom,
    int? fuse,
    bool clearFuse = false,
  }) {
    return Tile(
      id: id ?? this.id,
      value: value ?? this.value,
      row: row ?? this.row,
      col: col ?? this.col,
      isNew: isNew ?? this.isNew,
      mergedFrom: mergedFrom ?? this.mergedFrom,
      fuse: clearFuse ? null : (fuse ?? this.fuse),
    );
  }

  /// Same tile with both animation flags cleared. Used when a board is carried
  /// into the next move so last move's flags do not replay.
  Tile withoutAnimationFlags() =>
      isNew || mergedFrom ? copyWith(isNew: false, mergedFrom: false) : this;

  Map<String, dynamic> toJson() => {
    'i': id,
    'v': value,
    'r': row,
    'c': col,
    if (fuse != null) 'f': fuse,
  };

  factory Tile.fromJson(Map<String, dynamic> json) => Tile(
    id: json['i'] as int,
    value: json['v'] as int,
    row: json['r'] as int,
    col: json['c'] as int,
    fuse: json['f'] as int?,
  );

  @override
  bool operator ==(Object other) =>
      other is Tile &&
      other.id == id &&
      other.value == value &&
      other.row == row &&
      other.col == col &&
      other.isNew == isNew &&
      other.mergedFrom == mergedFrom &&
      other.fuse == fuse;

  @override
  int get hashCode => Object.hash(id, value, row, col, isNew, mergedFrom, fuse);

  @override
  String toString() =>
      'Tile(#$id v$value @$row,$col'
      '${isNew ? ' new' : ''}${mergedFrom ? ' merged' : ''}'
      '${fuse == null ? '' : ' fuse$fuse'})';
}
