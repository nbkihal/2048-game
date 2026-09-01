# Build Prompt — 2048 Flutter Game (stage-based version)

## Full prompt

Build a 2048-style puzzle game in Flutter, following the CLAUDE.md in this
project exactly. This is the STAGE-BASED version — not plain endless 2048.

Core mechanic: N×N grid, swipe up/down/left/right, tiles with the same number
that collide merge into their double, a new 2 (90%) or 4 (10%) spawns after
each valid move. Fully offline — no backend, no server storage.

Progression: the game is organized into ordered STAGES defined as data in
`lib/data/stages_data.dart` (grid size, target tile, optional twists, metadata).
Follow the stage table in CLAUDE.md (§6): rising targets, 3×3 / 4×4 / 5×5
boards, move-limit stages, blocked/frozen-cell stages, and an endless final
stage. Clearing a stage unlocks the next. Adding a stage = adding a data entry,
NEVER hardcoding logic in the UI.

Requirements:
- Follow the exact folder structure and layering in CLAUDE.md. All game rules
  go in `lib/logic/` as PURE Dart functions with NO Flutter imports. Stage
  twists are data + a small conditional in `game_rules.dart` — the core
  slide/merge logic must stay untouched and generic across grid sizes.
- Use flutter_riverpod; state is immutable (copyWith on each move).
- Every tile has a stable id so movement animates instead of teleporting.
- Use shared_preferences for unlocked stages, per-stage best scores, and
  settings only.

Build in this order and stop for my review after each phase:
1. Logic core (models + merge_logic + game_engine + spawn + game_rules) WITH
   full unit tests, working for any grid size. Cover: gaps, single merge,
   double-merge cap (`[2,2,2,2] -> [4,4]`), invalid-move detection, spawn into
   empty cells only, win at the stage target, lose only when truly stuck,
   move-limit and blocked-cell twists. No UI yet.
2. A minimal playable board (board_view, tile_view, swipe_detector) on a 4×4,
   static colors. Confirm you can reach a target.
3. Animations: slide (~130ms ease), merge pop, spawn scale-in.
4. Stages & progression: stages_data, stage-select screen (locked/unlocked/
   cleared + best score), per-stage win/lose, unlock persistence, twists.
5. Meta & polish: home/settings screens, high scores, sound, haptics,
   stage-clear + game-over dialogs.

Use placeholder theme values in `core/app_theme.dart` as tokens — I'll supply a
DESIGN.md with the real colors/fonts and a logo asset later, so keep all colors
and sizes referenced through tokens, never hardcoded. Run `flutter analyze`
clean and `dart format .` before finishing each phase.

---

## Short version (one-liner)

Build the stage-based 2048 game in Flutter following CLAUDE.md exactly. Start
with Phase 1 only — the pure logic core in `lib/logic/` (no Flutter imports) plus
full unit tests, working for any grid size — and stop for my review before any UI.
