# CLAUDE.md

## Project

Coartada (Dart package `coartada`, app id `com.alioli97.coartada`): an original logic-deduction game in Flutter. A house map is an N×N grid split into rooms, with furniture. The player places N people (one per row and per column, never on tables/plants/bookshelves) using clues, then names the culprit: the only person sharing the victim's room. Cases are **generated**, not hand-written, and always have exactly one solution. It is inspired by the "sudoku + murder mystery" genre but must stay original: never copy the name, cases, characters or art of existing games (e.g. Murdoku).

Work plan: `docs/ROADMAP.md`. Read it before starting a step and tick the step's box in the same commit that completes it. One step = one commit on its own branch, merged into `main` with CI green; commit messages in English, Conventional Commits.

Flutter 3.50 (Dart 3.14). Material widgets come from `package:material_ui/material_ui.dart` (never `package:flutter/material.dart`). No backend: everything is local (SharedPreferences).

## Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
flutter build web   # preview: python3 -m http.server 5180 --directory build/web
```

CI (`.github/workflows/ci.yml`) checks formatting (`dart format lib test`), runs `flutter analyze` and `flutter test` on pushes to `main` and on PRs, with Flutter 3.50.0: bump it there when the local SDK changes. Keep it green.

## Architecture

- `lib/game/` — pure Dart, no widgets except `ChangeNotifier`:
  - `model.dart` — `Board` (size, variant, `roomOf`, `rooms`, `furniture`), `Clue` sealed hierarchy (`InRoom`, `NotInRoom`, `OnFurniture`, `NextTo`, `InRow`, `InColumn`, `NorthOf`, `WestOf`, `SameRoom`), `Puzzle`, `Level` (4×4…7×7), `Variant` (`classic`, `noTouch`), the `roster` of 8 names.
  - `solver.dart` — `countSolutions` (backtracking, stops at `limit`); encodes the rules, including "exactly one other person in the victim's room".
  - `generator.dart` — `generatePuzzle(level, seed, variant)`: random solution → rooms → victim/culprit → furniture → weighted clue pool → add clues until unique → remove redundant clues (keeps spares on easy levels). Deterministic per seed. The daily case is `Level.inspector` with seed `yyyymmdd`.
  - `game_controller.dart` — player state: placements, crosses, undo, hints (lock a person in the right place), check → accuse → solved.
- `lib/core/strings.dart` — hand-rolled translations (es default, ca, en) via `_tr(es, ca, en)`, including clue sentences. Never hardcode user text in widgets.
- `lib/core/app_state.dart` — `AppState` (`ChangeNotifier`, passed through constructors): language, theme mode, no-touch variant, per level+variant stats, daily solved.
- `lib/theme/app_theme.dart` — design tokens chosen with the UI UX Pro Max skill (`.claude/skills/ui-ux-pro-max`): light = "E-Ink / Paper" style, dark = "Card & Board Game" palette. Board colors live in the `GameColors` theme extension (`context.game`). Warm colors mean "you can stand here" (rugs, chairs); grey icons are obstacles.
- `lib/screens/` — `home_screen.dart`, `game_screen.dart`, `how_to_play_screen.dart`. `lib/widgets/` — `board_view.dart` (CustomPainter for rooms/walls + tappable cells with `Semantics`), `suspect_avatar.dart`, `settings_sheet.dart`.

## UI rules (from UI UX Pro Max checklist)

- Touch targets ≥ 48dp (board cells are ~46dp on a 7×7 board at 375px wide; don't make them smaller).
- Text contrast ≥ 4.5:1 in both themes; check new colors in light **and** dark.
- No emoji as icons; Material icons only. Never rely on color alone (rooms have thick walls + legend; people have initials).
- Respect `MediaQuery.disableAnimations`.
