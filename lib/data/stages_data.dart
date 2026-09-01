import '../models/stage.dart';

/// The ordered stage table (CLAUDE.md §6).
///
/// This list is the whole progression. Adding a stage is a new entry here and
/// nothing else — the stage-select screen, the HUD and the rules all read the
/// data rather than branching on a stage id.
///
/// Move limits are set from the arithmetic of the target: reaching 256 needs
/// roughly 116 spawns at best (a spawn is worth 1.1 "twos" on average), so a
/// budget of 220 leaves real room to play while still punishing flailing.
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
    name: 'The 2048',
    subtitle: 'THE ONE EVERYONE TALKS ABOUT',
    gridSize: 4,
    targetTile: 2048,
  ),
  Stage(
    id: 10,
    name: 'Endless',
    subtitle: 'NO TARGET. JUST SCORE.',
    gridSize: 4,
    targetTile: null,
  ),
];

Stage stageById(int id) => kStages.firstWhere((s) => s.id == id);

/// The stage after [id], or `null` when [id] is the last one.
Stage? nextStageAfter(int id) {
  final index = kStages.indexWhere((s) => s.id == id);
  if (index < 0 || index + 1 >= kStages.length) return null;
  return kStages[index + 1];
}

/// 1-based position of a stage in the progression, for "STAGE 3 / 10" labels.
int stageNumber(int id) => kStages.indexWhere((s) => s.id == id) + 1;
