# Store listings

Everything the App Store and Google Play listings need, except what is typed into the
consoles by hand (see the answers below and `docs/RELEASE.md`).

## Texts

| Store | Files | Fields |
|---|---|---|
| App Store | `app-store/{es,ca,en}.md` | name, subtitle, promotional text, keywords, description |
| Google Play | `google-play/{es,ca,en}.md` | title, short description, full description |

Primary language Spanish (Spain); add Catalan and English (U.S. / United Kingdom). Check the
length limits with `python3 store/check.py`. The App Store name is "Pesquisa" ("Coartada", the first
name, was taken by another mystery game); if it is ever taken, use the Google Play title
("Pesquisa: casos de lógica"). Keywords never repeat words already in
the name or subtitle and avoid trademarks.

## Screenshots

Made with the App Store Screenshots skill (`.claude/skills/app-store-screenshots`, style
"Magazine Cover Editorial" with the app's green as the accent):

1. `flutter test store/screenshots/captures_test.dart` renders the real screens with sample
   progress into `store/screenshots-editor/public/screenshots/` (iPhone 1320×2868 and Android
   1080×2340, es/ca/en).
2. The editor (`store/screenshots-editor`, Next.js; needs Node 20+):
   `cd store/screenshots-editor && npm install && npm run dev -- -p 3005`. The deck (copy,
   layouts, theme) lives in `app-store-screenshots.json`; edit it there or in the browser.
3. `node store/screenshots/export.mjs` exports every deck with headless Chrome into:
   - `screenshots/ios/iphone/1320x2868/{es,ca,en}/` — App Store, 6.9" iPhone (the required slot;
     App Store Connect scales it for smaller iPhones). The app is iPhone-only: no iPad set.
   - `screenshots/android/android/1080x1920/{es,ca,en}/` — Google Play phone screenshots.
   - `screenshots/android/feature-graphic/1024x500/{es,ca,en}/` — Google Play feature graphic.

The six screens: the daily case in progress, a hint that explains a deduction, home with the
streak, case closed, the guided case and the statistics.

Icon: `branding/play_store_icon_512.png` (Google Play); the App Store takes it from the build.

## App Store Connect answers

- **Category:** Games, primary **Puzzle**, secondary **Board**.
- **Age rating:** the crime is only mentioned in text (a victim, a culprit); nothing is
  shown. Answer **None** to every violence question. If you consider the theme a mild
  fear/mystery theme, "Horror/Fear Themes: Infrequent/Mild" gives 9+; otherwise 4+.
- **Content rights:** no third-party content (cases are generated, art is the app's own).
- **Privacy:** policy `https://alioli97.github.io/Pesquisa/privacy/`; data collection
  **No, we do not collect data from this app.**
- **Support URL:** `https://alioli97.github.io/Pesquisa/support/`; marketing URL (optional)
  `https://alioli97.github.io/Pesquisa/`.
- **Copyright:** `2026 Arnau Alio`.
- **Price:** free, all territories. **EU DSA:** non-trader.
- **Review notes:** paste `app-store/review-notes.txt`. Sign-in required: no.

## Google Play answers

- **App category:** Game → **Puzzle**. Tags: logic, puzzle, detective, crime.
- **Data safety:** no data collected or shared; no encryption question since nothing is sent.
- **Content rating (IARC):** puzzle game; references to a crime in text, no violence shown, no
  user interaction, no purchases. **Ads:** no. **Target audience:** 13+.
- **Contact email:** `alio.studios.games@gmail.com`; website `https://alioli97.github.io/Pesquisa/`.
