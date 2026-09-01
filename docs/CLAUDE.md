# CLAUDE.md — 2048 Flutter Game

> Project guide for building a polished 2048-style puzzle game in Flutter.
> Read this file first, then read `DESIGN.md` (visual/theme spec — provided separately) before writing UI code.

---

## 1. The Idea (simple, but with depth)

**Core:** A grid of numbered tiles. The player swipes in one of four directions. All tiles slide that way; two tiles with the **same number that touch merge into one tile with double the value** (2 + 2 → 4, 4 + 4 → 8, ...). After every valid move a new tile (`2` or `4`) spawns in a random empty cell. The board fills up over time. Reach the stage's **target tile** to win the stage; if the board is full and no move is possible, it's game over.

**What makes it more than plain 2048 (the "stages" idea):**
Instead of one endless board, the game is organized into **stages** that get progressively harder and introduce new twists. Each stage is short, has a clear goal, and unlocks the next one. This turns a single mechanic into a real game with a sense of progression.

Keep the *mechanic* dead simple. Put the *interest* in the stage variety, the animations, and the juice (sound, particles, smooth motion).

---

## 2. Tech Stack

- **Framework:** Flutter (stable channel, 3.x) + Dart 3
- **State management:** `flutter_riverpod` (predictable, testable; game state lives in a `GameNotifier`). If the team prefers, `provider` + `ChangeNotifier` is an acceptable simpler alternative — pick one and stay consistent.
- **Local persistence:** `shared_preferences` for high scores, unlocked stages, and settings. **No backend, no server.** Everything is local and offline.
- **Animations:** Flutter's built-in `AnimatedPositioned` / `AnimatedContainer` / `TweenAnimationBuilder`, plus an `AnimationController` for merge "pop" effects.
- **Audio (optional but recommended for feel):** `audioplayers` for slide/merge/win sounds.
- **Testing:** `flutter_test` for widget tests, plain Dart unit tests for game logic.

> Do not add heavy game engines (Flame, etc.) — a grid puzzle does not need them. Standard Flutter widgets are enough and keep the build simple.

---

## 3. Project Structure

```
lib/
  main.dart                  # entry point, runApp
  app.dart                   # MaterialApp, routing, theme wiring

  core/
    constants.dart           # animation durations, spacing, spawn probabilities
    app_theme.dart           # pulls from DESIGN.md tokens
    extensions.dart          # small helpers

  models/
    tile.dart                # Tile: id, value, row, col (+ merge flags)
    board.dart               # Board: 2D grid of tiles, size N
    game_status.dart         # enum: playing, won, lost, idle
    stage.dart               # Stage: id, gridSize, targetTile, rules, name

  logic/
    game_engine.dart         # pure functions: move(board, dir) -> MoveResult
    merge_logic.dart         # slide + merge one row/column
    spawn.dart               # random empty-cell tile spawning
    game_rules.dart          # win/lose checks per stage

  state/
    game_notifier.dart       # Riverpod StateNotifier holding GameState
    game_state.dart          # immutable snapshot (board, score, status, stage)
    stage_progress.dart      # unlocked stages, best scores (persisted)

  data/
    stages_data.dart         # the full ordered list of stages (see §6)
    persistence.dart         # shared_preferences read/write

  screens/
    home_screen.dart         # title, play, continue, settings
    stage_select_screen.dart # map/list of stages (locked/unlocked)
    game_screen.dart         # the board + HUD (score, moves, target)
    settings_screen.dart     # sound, theme, reset progress

  widgets/
    board_view.dart          # renders the grid + animated tiles
    tile_view.dart           # single tile: color by value, pop animation
    score_board.dart         # current score + best
    target_banner.dart       # "Reach 512" progress
    game_over_dialog.dart
    stage_clear_dialog.dart
    swipe_detector.dart       # GestureDetector wrapping the board

test/
  logic/
    merge_logic_test.dart
    game_engine_test.dart
    game_rules_test.dart
  widgets/
    board_view_test.dart
```

**Rule:** all game rules live in `logic/` as **pure functions** (no Flutter imports, no side effects). This makes them fully unit-testable and keeps the UI dumb. The `state/` layer wires pure logic to the UI.

---

## 4. Core Data Model

```dart
class Tile {
  final int id;      // stable id so we can animate movement, not recreate
  final int value;   // 2, 4, 8, ...
  final int row;
  final int col;
  final bool isNew;      // just spawned -> spawn animation
  final bool mergedFrom; // result of a merge this move -> pop animation
}
```

- Every tile has a **stable `id`**. When a tile slides, we keep its id and change `row`/`col`, so the UI can animate it moving instead of teleporting. This is the single most important detail for smooth animation — do not recreate tiles every frame.
- The board is `N x N` (`gridSize` comes from the current stage; default 4).
- `GameState` is **immutable**. Each move produces a new `GameState`. This makes undo trivial (keep a stack of previous states) and makes logic easy to test.

---

## 5. Core Game Logic (the heart of it)

Implement and test this **before** touching UI.

### Slide + merge one line
For a single row/column reduced to the direction of travel:
1. Remove empty gaps (compact tiles toward the direction).
2. Walk the compacted list; if the current tile equals the next **and neither has already merged this move**, merge them (double the value), mark as merged, skip the next.
3. Compact again.

Each tile can merge **at most once per move** (`[2,2,2,2]` swiped → `[4,4]`, never `[8]`).

### A full move (`move(board, direction)`)
1. For each of the 4 directions, transform the board so the logic always slides "left" (rotate/reflect), run the line logic on every row, then transform back. This avoids writing the merge four times.
2. A move is **valid** only if at least one tile actually moved or merged.
3. On a valid move: add merged values to the score, then **spawn** one new tile.

### Spawn
- Pick a random empty cell.
- Spawn value: `2` with 90% probability, `4` with 10% (tune in `constants.dart`).
- Mark it `isNew` for the spawn animation.

### Win / lose (per stage — see `game_rules.dart`)
- **Win:** any tile reaches the stage's `targetTile`.
- **Lose:** board is full **and** no move in any of the 4 directions would change the board.
- After winning a stage the player may optionally "keep going" for a higher score (endless within that grid), but the stage is already marked cleared.

### Return type
```dart
class MoveResult {
  final Board board;
  final int gainedScore;
  final bool moved;       // was it a valid move?
  final List<int> mergedTileIds; // for pop animation
}
```

---

## 6. Stages (progression — makes it a real game)

Stages live in `data/stages_data.dart` as an ordered, data-driven list. Adding a stage = adding a data entry, **never** hardcoding logic in the UI. Each `Stage` defines the grid size, the target tile to reach, an optional twist, and metadata.

Suggested progression (tune freely):

| # | Name            | Grid | Target | Twist |
|---|-----------------|------|--------|-------|
| 1 | First Steps     | 4×4  | 64     | none — teaches the basics |
| 2 | Warming Up      | 4×4  | 128    | none |
| 3 | Getting Serious | 4×4  | 256    | none |
| 4 | Tight Space     | 3×3  | 128    | smaller board, less room |
| 5 | The Classic     | 4×4  | 512    | none |
| 6 | Move Budget     | 4×4  | 256    | clear the target within N moves |
| 7 | Big Board       | 5×5  | 1024   | more room, longer game |
| 8 | Frozen Tile     | 4×4  | 512    | one random cell is blocked/immovable |
| 9 | The 2048        | 4×4  | 2048   | the classic goal |
| 10| Endless         | 4×4  | ∞      | no target — chase the high score |

Each stage stores: `id`, `name`, `gridSize`, `targetTile`, `moveLimit?`, `blockedCells?`, `unlockedByDefault`. The stage-select screen reads `stage_progress` to show locked/unlocked/cleared state and the best score per stage.

**Optional twists to implement as rule flags (keep them opt-in per stage):**
- `moveLimit` — lose if you exceed the move count before hitting target.
- `blockedCells` — cells that are never usable (render as a wall).
- Later: power-ups (undo token, single-tile delete, shuffle) awarded on stage clear.

Keep twists as **data + a small conditional in `game_rules.dart`**, so the core slide/merge logic stays untouched and testable.

---

## 7. Animations (the "juice")

This is what separates a real game from a school exercise. Priorities:
1. **Slide:** tiles move to their new position over ~120–150ms with an ease curve. Achieved via stable tile ids + `AnimatedPositioned`.
2. **Merge pop:** merged tile briefly scales up (1.0 → 1.15 → 1.0) with a short controller.
3. **Spawn:** new tile scales in from ~0.5 with a bounce.
4. **Stage clear / game over:** dialog fades + slight scale; optional confetti particles on win.
5. Keep everything driven by durations in `core/constants.dart` so they're easy to tune.

Do not block input during animations for too long — feel should be snappy. A move can be accepted as soon as the logic resolves; the visuals catch up.

---

## 8. Screens & Flow

```
Home ─► Stage Select ─► Game ─► (Stage Clear dialog) ─► next stage / Stage Select
                          └────► (Game Over dialog) ──► retry / Stage Select
Home ─► Settings
Home ─► Continue (jumps to last unlocked stage)
```

**HUD on Game screen:** current score, best score for this stage, target tile with progress, moves used (and limit if any), undo button (if allowed), pause/back.

---

## 9. Persistence (local only)

Store via `shared_preferences`:
- `highScoreGlobal`
- `bestScore_stage_<id>`
- `unlockedStages` (list of ids or highest cleared index)
- settings: `soundOn`, `themeId`, `hapticsOn`

Reset-progress option in Settings clears these keys. **Never** persist mid-move animation state — persist only committed `GameState` snapshots so a force-close resumes cleanly.

---

## 10. Design / Theming

- All colors, tile palettes, fonts, corner radii, and spacing come from **`DESIGN.md`** (provided separately). Map them into `core/app_theme.dart` as tokens; widgets read tokens, never hardcode hex values.
- Tile color is a function of `value` — define the palette as a `Map<int, Color>` (or computed steps) sourced from the design tokens.
- Support at least light + dark, and leave room for unlockable themes (a `themeId` already exists in settings).

---

## 11. Testing Requirements

Logic (pure Dart unit tests) — **required, write these first:**
- slide/merge on a single line: gaps, single merge, double-merge cap (`[2,2,2,2] → [4,4]`), no-merge.
- full move in all 4 directions.
- move validity (a blocked move must not spawn a tile or change score).
- spawn only into empty cells; respects 2/4 probability distribution over many runs.
- win detection at target; lose detection only when truly stuck.
- stage twists: move limit, blocked cells.

Widget tests:
- swiping a direction updates the board.
- game over dialog appears when stuck.
- stage clear dialog appears at target.

Target: game logic in `logic/` should be **near 100% covered**, since it's pure and cheap to test.

---

## 12. Coding Conventions

- `logic/` = pure functions, **no `flutter/` imports**. If you're importing Material into a logic file, it's in the wrong layer.
- Immutable state; produce new objects on each move (use `copyWith`).
- Keep widgets small and stateless where possible; state lives in the notifier.
- Constants (durations, sizes, probabilities) go in `core/constants.dart`, never inline magic numbers.
- Names in English; comments explain *why*, not *what*.
- Run `flutter analyze` clean and `dart format .` before every commit.

---

## 13. Development Roadmap (build order)

**Phase 1 — Logic core (no UI).**
Models, `merge_logic`, `game_engine`, `spawn`, `game_rules`. Full unit tests. This must be solid before anything else.

**Phase 2 — Minimal playable board.**
`board_view` + `tile_view` + `swipe_detector`, wired to `game_notifier`. Static colors, no animation yet. Confirm you can actually play a 4×4 to 2048.

**Phase 3 — Animations & juice.**
Slide, merge pop, spawn scale. Tune durations. This is where it starts feeling like a game.

**Phase 4 — Stages & progression.**
`stages_data`, stage-select screen, per-stage win/lose, unlock + persistence. Implement twists (grid size, move limit, blocked cells).

**Phase 5 — Meta & polish.**
Home/settings screens, high scores, sound, haptics, theming from `DESIGN.md`, game over / stage clear dialogs, confetti on win.

**Phase 6 — Test pass & release build.**
Widget tests, manual device testing (small + large screens), performance check on large boards, build release APK/IPA.

---

## 14. Explicit Non-Goals

- No backend, no online multiplayer, no accounts, no server storage — the game is fully local and offline.
- No third-party game engine.
- Don't over-engineer stage twists early; ship the core loop first, add twists as data.

---

## 15. Common Commands

```bash
flutter pub get                 # install deps
flutter run                     # run on connected device/emulator
flutter test                    # run all tests
flutter test test/logic/        # run only logic tests
flutter analyze                 # static analysis (must be clean)
dart format .                   # format
flutter build apk --release     # Android release
flutter build ios --release     # iOS release (on macOS)
```

---

**When in doubt:** keep the mechanic simple, put the effort into progression and animation, and keep all game rules as pure, tested functions in `logic/`.
