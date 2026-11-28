# Roadmap

Goal: publish Pesquisa on the App Store and Google Play. One step = one commit
on its own branch, merged into `main` with CI green. Tick each box when its
commit lands. UI steps use the UI UX Pro Max skill (`.claude/skills/ui-ux-pro-max`):
search before designing, run its pre-delivery checklist before committing.

## A. Base polish

- [x] 1. Save and resume the game in progress (`GameController` to/from JSON;
      the case is regenerated from its seed; "Continue" card on home; save on
      every change and when the app goes to the background, clock paused).
- [x] 2. Board squares ≥ 48dp on a 7×7 board at 375px wide (smaller label
      gutter, board uses the full width), with a widget test measuring them.
- [x] 3. Game settings: vibration on/off and "visual help" on/off (shading of
      taken rows/columns and conflict rings).

## B. Visual upgrade

- [x] 4. Typography: bundle Playfair Display (headings) + Source Serif 4 (body),
      OFL, in `assets/fonts/`, with `LicenseRegistry`.
- [x] 5. Illustrated map: floor pattern per room kind (planks, tiles, carpet,
      grass, stone) and hand-painted vector furniture instead of Material icons.
      Re-check contrast in light and dark.
- [x] 6. Original vector portraits for the 8 characters, keeping the initial.
- [x] 7. Meaningful motion (respecting `disableAnimations`): suspect drops
      into place, board shakes on a wrong check, final reveal lights up the
      victim's room and the culprit.

## C. Gameplay

- [x] 8. Pencil notes: small candidate initials per square (saved, undoable).
- [x] 9. Reasoning hints: `lib/game/deducer.dart` with human techniques; the
      hint explains one deduction and highlights the squares, and only reveals
      a person when no deduction is found. The generator now only accepts
      cases the deducer can solve (no trial and error). Grading difficulty by
      technique is left for later.
- [x] 10. New clue types: in a corner, by the outer wall, in a different room
      from…, nobody was in room X, on the same diagonal as… (still unique).
- [x] 11. 8×8 "Legend" level with zoom (`InteractiveViewer`); generator under
      300 ms.

## D. Engagement

- [x] 12. Statistics screen and daily streak (current and best).
- [x] 13. Daily archive: last 30 days playable (count for stats, not streak).
- [x] 14. Share a spoiler-free result via `share_plus`.

## E. Tutorial

- [x] 15. Guided first case: a hand-made original 4×4 with a step-by-step
      coach; offered on home until done or dismissed (not forced, per UI UX
      Pro Max: skippable, with Back), replayable from "How to play".

## F. Release

- [x] 16. Branding: app icon, splash (`flutter_launcher_icons`,
      `flutter_native_splash`), "Pesquisa" display name on Android and iOS.
- [x] 17. Privacy policy and support page in `site/` (GitHub Pages workflow);
      "About" screen with licenses.
- [x] 18. Release builds: signed Android workflow, iOS workflow on a macOS
      runner to TestFlight, `docs/RELEASE.md` (secrets set by the owner).
- [x] 19. Store listing texts (es/ca/en) in `store/` and screenshots rendered by
      a screenshots test.

## Done

- [x] Playable v0: generated unique-solution cases 4×4–7×7, no-touch variant,
      daily case, es/ca/en, light/dark themes.
- [x] CI: format, analyze and tests on pushes to `main` and PRs.
