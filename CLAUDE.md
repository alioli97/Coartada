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
  - `game_controller.dart` — player state: placements, crosses, undo, hints (lock a person in the right place), check → accuse → solved. Input modes (`InputMode`: place / cross / notes); pencil notes are `notes` (square → people), part of undo snapshots and of the save (`notes` is optional in `fromJson`, so older saves still load). Crossing a square out clears its notes. `toJson`/`fromJson` (versioned by `saveVersion`; bump it when the format changes) store only the player's marks and time: the case is regenerated from seed + level + variant. The clock is `elapsed` (earlier sessions + a pausable stopwatch).
- `lib/core/strings.dart` — hand-rolled translations (es default, ca, en) via `_tr(es, ca, en)`, including clue sentences. Never hardcode user text in widgets.
- `lib/core/app_state.dart` — `AppState` (`ChangeNotifier`, passed through constructors): language, theme mode, no-touch variant, per level+variant stats, daily solved, game settings (`haptics`, `visualHelp`, both on by default), and one saved game (`saved_game`). `saveGame` doesn't notify (it runs on every move); the home screen calls `refresh()` after the game screen closes. `GameScreen` saves when progress changes (not on selection), when the app is hidden (clock paused) and on pop; an untouched new case never replaces the saved one, a resumed one always updates it.
- `lib/theme/app_theme.dart` — design tokens chosen with the UI UX Pro Max skill (`.claude/skills/ui-ux-pro-max`): light = "E-Ink / Paper" style, dark = "Card & Board Game" palette. Fonts are bundled in `assets/fonts/` (declared in pubspec, never downloaded at runtime): Playfair Display 700/800 for display/headline/titleLarge (`AppTheme.headingFont`), Source Serif 4 400/600 for everything else (`AppTheme.bodyFont`); OFL licenses registered by `lib/core/font_licenses.dart`. Using a new weight means adding its `.ttf` (verify its SHA-256) and a pubspec entry. Compact labels must stay on one line (`FittedBox` scaleDown), serif text is wider. Board colors live in the `GameColors` theme extension (`context.game`). Warm colors mean "you can stand here" (rugs, chairs); grey icons are obstacles.
- `lib/screens/` — `home_screen.dart`, `game_screen.dart` (rebuilds on the controller and on `AppState`; vibration goes through `_haptic`, which honours the setting; ⋮ menu opens settings too), `how_to_play_screen.dart`. `lib/widgets/` — `board_view.dart` (CustomPainter for room tints, a faint floor pattern per `RoomKind` — tiles, planks, carpet dots, grass, stone — and walls, + tappable cells with `Semantics`), `furniture_glyph.dart` (hand-painted flat furniture: soft fill + 2px outline, no Material icons; rugs stay full size under people, chairs shrink to a corner badge), `suspect_avatar.dart` (original flat portraits painted per roster index — `_looks` — with the initial in white on a darker shirt, `shirtColor`; never below `minAvatarSize` 34dp so the initial stays ≥ 12px; excluded from semantics because the name is always beside it), `settings_sheet.dart`.

## UI rules (from UI UX Pro Max checklist)

- Touch targets ≥ 48dp. Board squares are ~48.7dp on a 7×7 board at 375px wide (18dp label strip, 8dp board gutter while other content keeps 16dp via `_gutter`); `test/board_size_test.dart` guards it for every level.
- Text contrast ≥ 4.5:1 in both themes; check new colors in light **and** dark.
- Furniture ink (`blockedIcon`, `seat`) keeps ≥ 3:1 on every room tint, floor pattern and taken shade: `test/furniture_test.dart` checks it, so a new tint or ink must pass there.
- No emoji as icons; Material icons only. Never rely on color alone (rooms have thick walls + legend; people have initials).
- Motion: use the tokens in `Motion` (`lib/theme/app_theme.dart`) and always `Motion.of(context, d)`, which is zero under reduced motion (`MediaQuery.disableAnimations`). Transform/opacity only, never block input, and game state never waits on an animation. Current animations: suspect drop (`TweenAnimationBuilder` keyed by person@square), board shake on a wrong check (`_shake` in `game_screen.dart`), final reveal (`_RevealPainter` dims other rooms and outlines the crime scene; the case-closed dialog waits `reveal + revealHold`). `test/motion_test.dart` covers both modes.
