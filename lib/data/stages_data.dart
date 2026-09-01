import '../models/position.dart';
import '../models/stage.dart';
import 'daily.dart';

/// The ordered stage table (CLAUDE.md §6).
///
/// This list is the whole progression. Adding a stage is a new entry here and
/// nothing else — the stage-select screen, the HUD and the rules all read the
/// data rather than branching on a stage id. Order is list position, not id.
///
/// The ladder alternates board sizes on purpose: a 3x3 punishes the same play
/// that a 6x6 rewards, so changing the grid changes the puzzle far more than
/// raising the target does.
///
/// Move limits are set from the arithmetic of the target: a spawn is worth 1.1
/// "twos" on average, so reaching a target of N needs roughly N/2.2 spawns at
/// best. Budgets sit near twice that, which leaves real room to play while
/// still punishing flailing.
const List<Stage> kStages = [
  Stage(
    id: 1,
    name: 'First Steps',
    subtitle: 'LEARN THE SWIPE',
    gridSize: 4,
    targetTile: 64,
    unlockedByDefault: true,
  ),
  Stage(
    id: 2,
    name: 'Warming Up',
    subtitle: 'SAME BOARD, BIGGER ASK',
    gridSize: 4,
    targetTile: 128,
  ),
  Stage(
    id: 3,
    name: 'Getting Serious',
    subtitle: 'KEEP THE BIG ONE IN A CORNER',
    gridSize: 4,
    targetTile: 256,
  ),
  Stage(
    id: 4,
    name: 'Tight Space',
    subtitle: 'NINE CELLS. NO MERCY.',
    gridSize: 3,
    targetTile: 128,
  ),
  Stage(
    id: 5,
    name: 'The Classic',
    subtitle: 'HALF WAY TO THE REAL THING',
    gridSize: 4,
    targetTile: 512,
  ),
  Stage(
    id: 6,
    name: 'Move Budget',
    subtitle: 'EVERY SWIPE COUNTS',
    gridSize: 4,
    targetTile: 256,
    moveLimit: 220,
  ),
  Stage(
    id: 7,
    name: 'Big Board',
    subtitle: 'MORE ROOM, LONGER GAME',
    gridSize: 5,
    targetTile: 1024,
  ),
  Stage(
    id: 8,
    name: 'Frozen Tile',
    subtitle: 'ONE CELL IS DEAD WEIGHT',
    gridSize: 4,
    targetTile: 512,
    randomBlockedCells: 1,
  ),
  Stage(
    id: 9,
    name: 'Wide Open',
    subtitle: 'THIRTY-SIX CELLS TO FILL',
    gridSize: 6,
    targetTile: 2048,
  ),
  Stage(
    id: 10,
    name: 'Twin Walls',
    subtitle: 'TWO CELLS GONE, PICKED AT RANDOM',
    gridSize: 4,
    targetTile: 512,
    randomBlockedCells: 2,
  ),
  Stage(
    id: 11,
    name: 'Pillars',
    // Both walls sit off-centre rather than in a corner: the corner is where
    // the stacking strategy lives, and taking it away is unfair, not hard.
    subtitle: 'TWO FIXED WALLS, DEAD CENTRE',
    gridSize: 4,
    targetTile: 512,
    blockedCells: [Position(1, 1), Position(2, 2)],
  ),
  Stage(
    id: 12,
    name: 'Ice Field',
    subtitle: 'A BIG BOARD WITH TWO HOLES IN IT',
    gridSize: 5,
    targetTile: 1024,
    randomBlockedCells: 2,
  ),
  Stage(
    id: 13,
    name: 'Countdown',
    subtitle: 'MERGE THE BOMB BEFORE IT LANDS',
    gridSize: 4,
    targetTile: 512,
    bombFuse: 14,
  ),
  Stage(
    id: 14,
    name: 'Marathon',
    subtitle: 'A LONG RUN ON A SHORT LEASH',
    gridSize: 5,
    targetTile: 1024,
    moveLimit: 700,
  ),
  Stage(
    id: 15,
    name: 'Carousel',
    subtitle: 'THE BOARD TURNS UNDER YOU',
    gridSize: 5,
    targetTile: 1024,
    rotateEveryMoves: 8,
  ),
  Stage(
    id: 16,
    name: 'The 2048',
    subtitle: 'THE ONE EVERYONE TALKS ABOUT',
    gridSize: 4,
    targetTile: 2048,
  ),
  Stage(
    id: 17,
    name: 'Six Pack',
    subtitle: 'THE BIGGEST BOARD, THE BIGGEST TILE',
    gridSize: 6,
    targetTile: 4096,
  ),
];

/// Endless boards, reachable from the home screen rather than the ladder.
///
/// They are ordinary stages with no target and no lock, kept in their own list
/// so the campaign's "next stage" chain and its cleared count ignore them. Ids
/// start at 101 so a best score can never collide with a campaign stage's.
const List<Stage> kEndlessStages = [
  Stage(
    id: 101,
    name: 'Endless 3×3',
    subtitle: 'THE SHORT ONE',
    gridSize: 3,
    targetTile: null,
    unlockedByDefault: true,
  ),
  Stage(
    id: 102,
    name: 'Endless 4×4',
    subtitle: 'THE ORIGINAL BOARD',
    gridSize: 4,
    targetTile: null,
    unlockedByDefault: true,
  ),
  Stage(
    id: 103,
    name: 'Endless 5×5',
    subtitle: 'ROOM TO BREATHE',
    gridSize: 5,
    targetTile: null,
    unlockedByDefault: true,
  ),
  Stage(
    id: 104,
    name: 'Endless 6×6',
    subtitle: 'THE LONG HAUL',
    gridSize: 6,
    targetTile: null,
    unlockedByDefault: true,
  ),
];

/// Every playable board: the ladder, the endless boards and today's challenge.
const List<Stage> kAllStages = [...kStages, ...kEndlessStages, kDailyStage];

Stage stageById(int id) => kAllStages.firstWhere((s) => s.id == id);

/// The stage after [id] in the campaign, or `null` when [id] is the last one —
/// or is not part of the campaign at all.
Stage? nextStageAfter(int id) {
  final index = kStages.indexWhere((s) => s.id == id);
  if (index < 0 || index + 1 >= kStages.length) return null;
  return kStages[index + 1];
}

/// 1-based position of a stage in the campaign, or `0` for anything else.
int stageNumber(int id) => kStages.indexWhere((s) => s.id == id) + 1;

/// True when the stage belongs to the campaign ladder.
bool isCampaignStage(int id) => stageNumber(id) > 0;

/// The HUD's one-line placement: campaign stages count off against the ladder,
/// everything else names what it is instead.
String stageLabel(Stage stage) {
  final number = stageNumber(stage.id);
  if (stage.id == kDailyStageId) return 'DAILY CHALLENGE';
  if (number == 0) return 'ENDLESS — ${stage.gridSize}×${stage.gridSize}';
  return 'STAGE $number / ${kStages.length}';
}
