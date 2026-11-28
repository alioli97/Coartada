# Release guide

Coartada ships to Google Play and the App Store. Builds come from GitHub Actions:
`apk.yml` (Android) and `ios.yml` (iOS, on macOS runners: there is no local Mac).
Secrets are set by the owner in GitHub → Settings → Secrets and variables → Actions;
they never go into the repository.

## Ids

- Android application id and iOS bundle id: `com.alioli97.coartada`.
- **This id is final — do not change it.** Neither store allows changing it once the app is
  published: a new id is a different app (new listing, no updates for existing users).
- Display name: "Coartada" (Android `android:label`, iOS `CFBundleDisplayName`).

## Versioning

`version` in `pubspec.yaml` is `name+build` (e.g. `1.0.1+2`). Before every release:

- bump the name (`1.0.1` for fixes, `1.1.0` for new features) and the build number
  (`+N`; Android refuses to install a lower one over a higher one);
- update `appVersion` in `lib/core/app_info.dart` (shown in About; `test/about_test.dart`
  fails until it matches);
- if the save format or the generator changed, bump `GameController.saveVersion`.

iOS takes the build number from the workflow (`100 + run number`), not from pubspec.

## Android

### Signing key (one-time)

Release builds are signed with a private key that lives **outside the repository**:

```bash
keytool -genkeypair -v -keystore ~/.android/coartada-release.jks -alias coartada -keyalg RSA -keysize 2048 -validity 10000
```

Use the same password for the store and the key (CI uses one secret for both). Then create
`android/key.properties` (gitignored) for local release builds:

```properties
storePassword=...
keyPassword=...
keyAlias=coartada
storeFile=/home/<you>/.android/coartada-release.jks
```

Without `key.properties`, release builds fall back to the debug key so CI and fresh clones
still build — but those builds **cannot update** an install signed with the release key, and
Google Play rejects them.

**Back up the keystore and its password somewhere safe** (e.g. a password manager). With Play
App Signing (below) the keystore becomes the *upload key*: if it is lost, Play support can
reset it, but it's slow.

### Secrets

- `ANDROID_KEYSTORE_BASE64`: `base64 -w0 ~/.android/coartada-release.jks`
- `ANDROID_KEYSTORE_PASSWORD`: its password

### Builds from CI

`.github/workflows/apk.yml` runs on every push to `main`, on PRs that touch the Android build,
and by hand (Actions → Android → Run workflow). It:

- builds the release APK and uploads it as the artifact `Coartada-<version>-<release|debug>`
  (kept 30 days), for installing by hand;
- fails if the release manifest asks for the `INTERNET` permission (the privacy policy says
  the app never goes online);
- with the signing secrets, also builds the App Bundle and uploads `Coartada-<version>-release-play`
  with the `.aab` (upload it to Play) and `mapping.txt` (upload it as the release's
  deobfuscation file).

Locally: `flutter build apk --release` or `flutter build appbundle --release` (needs JDK 17+
and the Android SDK `cmdline-tools` component).

### Google Play (manual steps)

1. **Create the app** in Play Console (developer account already exists): default language
   Spanish (es-ES), game, free.
2. **Play App Signing**: let Google generate the app signing key; the keystore above is the
   upload key.
3. **App content**:
   - Privacy policy: https://alioli97.github.io/Coartada/privacy/
   - Data safety: no data collected, no data shared (everything stays on the device; the
     release build has no INTERNET permission).
   - Ads: no. No in-app purchases.
   - Content rating questionnaire: puzzle game; a crime is mentioned (a "victim" and a
     "culprit") but no violence is shown; no user-generated content, no chat.
4. **Store listing**: texts and screenshots in `store/` (roadmap step 19), icon
   `branding/play_store_icon_512.png`. Contact email: `alio.studios.games@gmail.com`.
5. **Closed test**: upload the `.aab` to a closed testing track; testers join through a
   Google Group. New personal accounts need at least 12 testers opted in for 14 consecutive
   days before applying for production access.
6. **Production**: apply for access, then roll out.

## iOS (App Store / TestFlight)

`.github/workflows/ios.yml`:

- on PRs and pushes to `main`: unsigned build, and a check that the bundle is iPhone-only,
  portrait and lists es/ca/en;
- by hand (**Actions → iOS → Run workflow**): signed archive uploaded to TestFlight.

The app is **iPhone-only and portrait** (the board needs the phone upright; on iPad it runs
in iPhone mode, so no iPad screenshots are needed). `Info.plist` declares
`ITSAppUsesNonExemptEncryption = false`, so uploads skip the export-compliance question.

The archive and the export are signed on the runner with the Apple Distribution certificate
and an App Store profile stored as secrets. Xcode's automatic signing is not used: on every
fresh runner it makes Apple issue a new development certificate, until the account reaches
its limit. Apple's cloud-managed distribution signing isn't used either: it writes the
accented certificate name in a different Unicode form and App Store Connect rejects the
upload (ITMS-90035).

### One-time setup

The Apple Distribution certificate and the App Store Connect API key are per team, so the ones
already made for the other apps (kept outside the repository, in `~/ios-signing`) are reused.
Only the bundle id, the app and its profile are new:

1. Register the bundle id `com.alioli97.coartada` (Certificates, IDs & Profiles →
   Identifiers), with no extra capabilities.
2. Create the app in App Store Connect with that bundle id (primary language Spanish,
   name "Coartada"; if the name is taken, a subtitle-style name such as
   "Coartada: casos de lógica").
3. Profiles → + → **App Store Connect**, bundle id `com.alioli97.coartada`, the existing
   Apple Distribution certificate; download the `.mobileprovision`.
4. Secrets in this repository:
   - `APPSTORE_API_KEY` (contents of the `.p8`), `APPSTORE_KEY_ID`, `APPSTORE_ISSUER_ID`,
     `APPLE_TEAM_ID`: the same values as in the other apps;
   - `IOS_DIST_P12_BASE64` (`base64 -w0 dist.p12`) and `IOS_DIST_P12_PASSWORD`: the existing
     certificate;
   - `IOS_APPSTORE_PROFILE_BASE64`: `base64 -w0` of the new profile.

The certificate and the profile expire after one year: renew them and update the secrets
(in every app that uses them).

After an upload, Apple processes the build (roughly 10–30 minutes) before it shows up in
TestFlight. App Store Connect answers (category Games → Puzzle, age rating, privacy "Data
not collected", review notes) go with the listing in `store/` (roadmap step 19).
