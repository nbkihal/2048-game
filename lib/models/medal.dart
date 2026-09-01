/// The three things a stage can be beaten *for*.
///
/// A medal is derived from an attempt, never awarded by hand: the same run can
/// earn all three at once, and they are remembered per stage so a later sloppy
/// clear never takes one back.
enum Medal {
  /// The target was reached at all.
  cleared,

  /// Reached inside the stage's par move count.
  efficient,

  /// Reached without rewinding a single move.
  clean,
}

extension MedalX on Medal {
  /// Bit used to pack the set into one persisted integer.
  int get bit => 1 << index;

  String get label => switch (this) {
    Medal.cleared => 'CLEARED',
    Medal.efficient => 'UNDER PAR',
    Medal.clean => 'NO UNDO',
  };
}

/// Packs a medal set into a single integer for `shared_preferences`.
int packMedals(Set<Medal> medals) =>
    medals.fold(0, (bits, medal) => bits | medal.bit);

Set<Medal> unpackMedals(int bits) =>
    {for (final medal in Medal.values) if (bits & medal.bit != 0) medal};

/// What an attempt earned. [parMoves] is `null` on a stage with no target, in
/// which case there is nothing to be efficient about.
Set<Medal> medalsForAttempt({
  required bool cleared,
  required int movesUsed,
  required int? parMoves,
  required bool usedUndo,
}) {
  if (!cleared) return const {};
  return {
    Medal.cleared,
    if (parMoves != null && movesUsed <= parMoves) Medal.efficient,
    if (!usedUndo) Medal.clean,
  };
}
