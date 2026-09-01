import 'dart:math';

import 'package:game_2048/models/tile.dart';

/// Builds a line of tiles from values, `0` meaning an empty cell. Ids are the
/// 1-based slot index so assertions can talk about "the tile that started at 2".
List<Tile?> lineOf(List<int> values) => [
  for (var i = 0; i < values.length; i++)
    if (values[i] == 0)
      null
    else
      Tile(id: i + 1, value: values[i], row: 0, col: i),
];

/// Inverse of [lineOf]: the values a line holds, `0` for empty.
List<int> valuesOf(List<Tile?> line) => [for (final t in line) t?.value ?? 0];

/// A [Random] that always returns the first choice, so spawn positions and
/// values are fully predictable in tests.
class FixedRandom implements Random {
  FixedRandom({this.intValue = 0, this.doubleValue = 0.0});

  final int intValue;
  final double doubleValue;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => doubleValue;

  @override
  int nextInt(int max) => intValue % max;
}
