/// Central place for every tunable number in the game.
///
/// Nothing in `logic/` or `widgets/` should contain an inline magic number —
/// it belongs here so gameplay feel can be tuned in one file.
library;

// ---------------------------------------------------------------------------
// Board & spawning
// ---------------------------------------------------------------------------

/// Grid size used when a stage does not specify one.
const int kDefaultGridSize = 4;

/// Number of tiles placed on the board when a stage starts.
const int kInitialTileCount = 2;

/// Probability that a freshly spawned tile is a `2` (the rest are `4`).
const double kSpawnTwoProbability = 0.9;

/// The two values a spawn can ever produce.
const int kSpawnLowValue = 2;
const int kSpawnHighValue = 4;

// ---------------------------------------------------------------------------
// Animation timings (Phase 3 consumes these; kept here from the start so the
// UI never hardcodes a duration).
// ---------------------------------------------------------------------------

/// Tile travel time. Kept in the 120–150ms band so moves feel snappy.
const Duration kSlideDuration = Duration(milliseconds: 130);

/// "Pop" of a tile that just merged.
const Duration kMergePopDuration = Duration(milliseconds: 120);

/// Scale-in of a newly spawned tile.
const Duration kSpawnDuration = Duration(milliseconds: 160);

/// Fade + scale of stage-clear / game-over dialogs.
const Duration kDialogDuration = Duration(milliseconds: 250);

/// Scale a merged tile reaches at the peak of its pop.
const double kMergePopScale = 1.15;

/// Scale a spawning tile grows from.
const double kSpawnStartScale = 0.5;

// ---------------------------------------------------------------------------
// Input
// ---------------------------------------------------------------------------

/// Minimum drag distance (logical pixels) before a swipe is registered.
const double kSwipeThreshold = 24.0;

// ---------------------------------------------------------------------------
// Undo
// ---------------------------------------------------------------------------

/// How many moves back the undo stack reaches.
///
/// Deep, because the charges are uncapped: a 20-move ceiling would quietly
/// make "unlimited undo" mean "twenty undos". A snapshot is a board of at most
/// 36 tiles, so a hundred of them costs nothing worth counting.
const int kUndoHistoryLimit = 100;

// ---------------------------------------------------------------------------
// Board layout
// ---------------------------------------------------------------------------

/// Gap between cells, as a fraction of the cell size. Keeps the board looking
/// identical on a 3x3 and a 5x5.
const double kCellGapRatio = 0.09;

/// Padding around the grid inside the board block, as a fraction of the cell.
const double kBoardPaddingRatio = 0.09;

/// How long an absorbed tile stays on screen sliding into its merge target
/// before it is dropped from the widget tree.
const Duration kGhostLifetime = Duration(milliseconds: 150);

// ---------------------------------------------------------------------------
// Power-ups
// ---------------------------------------------------------------------------

/// A charge count that never runs down. Held as a sentinel rather than a huge
/// number so the UI can say "∞" instead of printing a made-up figure.
const int kUnlimitedCharges = -1;

/// Rewinds granted per attempt.
///
/// Unlimited for now: the game is entirely offline, so there is nothing to sell
/// and no reason to ration. Setting these back to small numbers (3 / 1 / 1) is
/// all it takes to make the tools scarce again — every check goes through
/// [hasCharges] and [spendCharge].
const int kUndoAllowance = kUnlimitedCharges;

/// Tile removals granted per attempt.
const int kHammerAllowance = kUnlimitedCharges;

/// Board re-deals granted per attempt.
const int kShuffleAllowance = kUnlimitedCharges;

/// Whether a tool with [charges] left can still be used.
bool hasCharges(int charges) => charges != 0;

/// Spends one charge, leaving an unlimited tool untouched.
int spendCharge(int charges) =>
    charges == kUnlimitedCharges ? charges : charges - 1;

/// True when the whole tool set is uncapped, which changes how it is described
/// rather than how it behaves.
bool get toolsAreUnlimited =>
    kUndoAllowance == kUnlimitedCharges &&
    kHammerAllowance == kUnlimitedCharges &&
    kShuffleAllowance == kUnlimitedCharges;

// ---------------------------------------------------------------------------
// Score popup
// ---------------------------------------------------------------------------

/// How long a "+128" floats above the board before it is gone.
const Duration kScorePopupDuration = Duration(milliseconds: 900);

/// Merges in one swipe before the popup calls it a chain.
const int kChainThreshold = 2;
