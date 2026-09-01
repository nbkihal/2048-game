import '../models/tile.dart';

/// A tile that was absorbed by a merge this move.
///
/// It no longer exists on the resulting board, but the UI still needs to slide
/// it to [destIndex] before it disappears — otherwise merges look like tiles
/// vanishing on the spot.
class AbsorbedTile {
  const AbsorbedTile(this.tile, this.destIndex);

  final Tile tile;

  /// Index, within the same line, of the cell the tile travelled into.
  final int destIndex;
}

/// Outcome of sliding and merging one line.
class LineResult {
  const LineResult({
    required this.tiles,
    required this.gainedScore,
    required this.mergedTileIds,
    required this.absorbed,
    required this.changed,
  });

  /// Same length as the input line, compacted toward index 0. The tiles carry
  /// stale `row`/`col`; the caller rewrites them once it maps the line back
  /// onto board coordinates.
  final List<Tile?> tiles;

  final int gainedScore;

  /// Ids of tiles that are the *product* of a merge (for the pop animation).
  final List<int> mergedTileIds;

  final List<AbsorbedTile> absorbed;

  /// Whether anything actually moved or merged.
  final bool changed;
}

/// Slides a single line toward index 0, merging equal neighbours.
///
/// The line is always given in travel order — the caller is responsible for
/// reversing rows/columns so that "toward index 0" means the swipe direction.
/// That way the merge rules are written once instead of four times.
///
/// [blocked] marks wall cells. Walls split the line into independent segments:
/// tiles never rest on a wall and never slide across one.
///
/// Each tile merges at most once per move, so `[2,2,2,2]` becomes `[4,4]` and
/// never `[8]`.
LineResult slideLine(List<Tile?> line, {List<bool>? blocked}) {
  final length = line.length;
  final walls = blocked ?? List<bool>.filled(length, false);
  assert(walls.length == length, 'blocked mask must match the line length');

  final result = List<Tile?>.filled(length, null);
  final mergedTileIds = <int>[];
  final absorbed = <AbsorbedTile>[];
  var gainedScore = 0;

  var cursor = 0;
  while (cursor < length) {
    if (walls[cursor]) {
      cursor++;
      continue;
    }

    // Walk to the end of this wall-free segment and compact it on its own.
    var segmentEnd = cursor;
    while (segmentEnd < length && !walls[segmentEnd]) {
      segmentEnd++;
    }

    final packed = <Tile>[
      for (var i = cursor; i < segmentEnd; i++)
        if (line[i] != null) line[i]!,
    ];

    var write = cursor;
    var read = 0;
    while (read < packed.length) {
      final current = packed[read];
      final next = read + 1 < packed.length ? packed[read + 1] : null;

      if (next != null && next.value == current.value) {
        // The leading tile keeps its id so it can animate into place; the
        // trailing tile travels to the same cell and is then removed.
        final mergedValue = current.value * 2;
        result[write] = current.copyWith(
          value: mergedValue,
          isNew: false,
          mergedFrom: true,
        );
        mergedTileIds.add(current.id);
        absorbed.add(AbsorbedTile(next, write));
        gainedScore += mergedValue;
        read += 2;
      } else {
        result[write] = current.withoutAnimationFlags();
        read += 1;
      }
      write++;
    }

    cursor = segmentEnd;
  }

  return LineResult(
    tiles: result,
    gainedScore: gainedScore,
    mergedTileIds: mergedTileIds,
    absorbed: absorbed,
    changed: _lineChanged(line, result),
  );
}

/// A line changed when any slot ends up holding a different tile (by id) or the
/// same tile with a different value.
bool _lineChanged(List<Tile?> before, List<Tile?> after) {
  for (var i = 0; i < before.length; i++) {
    final a = before[i];
    final b = after[i];
    if (a == null && b == null) continue;
    if (a == null || b == null) return true;
    if (a.id != b.id || a.value != b.value) return true;
  }
  return false;
}
