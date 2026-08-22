# CI/CD Guide — chiti

## Overview

This repository ships a GitHub Actions workflow (`.github/workflows/build.yml`) that:

- Builds **Android** (`app-release.apk` + `app-release.aab`) on `ubuntu-latest`.
- Builds an **iOS** unsigned archive (`Runner.app` zipped as an `.ipa`) on `macos-latest`.
- Runs `flutter analyze` and `flutter test` as fail-fast quality gates in both jobs.
- Caches the **Flutter SDK**, **pub cache**, **Gradle**, and **CocoaPods** to keep runs fast.

The pipeline triggers on `push`/`pull_request` against `main`, `master`, or `develop`,
and can also be started manually from the **Actions → Run workflow** button.

---

## How to download the generated `.apk` / `.aab` / `.ipa`

1. Open the **Actions** tab in your GitHub repository.
2. Select the **flutter-ci-build** workflow from the left sidebar.
3. Click on the run you are interested in (the most recent is on top).
4. Scroll to the bottom of the run page. Under the **Artifacts** heading of the
   **run summary** you will see:
   - `chiti-android-release` — contains:
     - `app-release.apk` (instalable Android APK)
     - `app-release.aab` (App Bundle for Play Console upload)
   - `chiti-ios-unsigned` — contains:
     - `chiti-runner-unsigned.ipa` (unsigned archive; installable on a device for QA)
5. Click an artifact name to download the `.zip`. Extract it, then use:
   - `app-release.apk` → install on a phone, or upload to the Play Console.
   - `app-release.aab` → upload to the Play Console (release track or internal testing).
   - `chiti-runner-unsigned.ipa` → contains `Payload/Runner.app`; re-sign it or
     sideload for testing.

Artifacts expire after 90 days by default; they are only retained for
successfully-completed runs.

---

## Enabling a signed, release-ready build (optional)

### Android (keystore)

1. Generate a keystore once (keep it local / in a secure store, never commit it):
   ```sh
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA \
     -keysize 2048 -validity 10000 -alias upload
   ```
2. Encode it as base64: `base64 < upload-keystore.jks` (or `base64 -i upload-keystore.jks` on macOS).
3. Add the following **repository secrets** (Settings → Secrets and variables → Actions):
   - `KEYSTORE_BASE64`
   - `KEYSTORE_PASSWORD`
   - `KEY_ALIAS`
   - `KEY_PASSWORD`
4. Wire the new signing config in `android/app/build.gradle.kts` using the snippet
   documented inside the workflow (see the "Import Android signing keys" step).
   When the secrets are present, the pipeline emits a properly signed release APK/AAB.

### iOS (App Store distribution)

The default pipeline intentionally builds **unsigned** to avoid requiring
certificates on CI. To produce a signed IPA / ship to TestFlight:

1. Create an **App Store Connect API Key** (App Store Connect → Users and Access →
   Integrations → App Store Connect API), keep the `.p8` file private.
2. Add the secrets `APPLE_API_KEY`, `APPLE_KEY_ID`, `APPLE_ISSUER_ID`.
3. Add a Fastlane `beta` lane and uncomment/adapt the Fastlane steps commented in
   the workflow's iOS job (a working template is provided in the file comments).
4. The `flutter build ios --release --no-codesign` step must be switched to
   `flutter build ipa --release` **after** signing setup, and `pod install`
   should run through Fastlane's `cocoapods` action or on every run as it does now.

### iOS alternative (p12 + provisioning profile)

- Add `P12_BASE64`, `P12_PASSWORD`, and `PROVISIONING_PROFILE_BASE64` secrets.
- Import the `.p12` into a dedicated CI keychain and install the provisioning
  profile under `~/Library/MobileDevice/Provisioning Profiles/` before building —
  the exact commands are commented in `build.yml`.

---

## Tuning notes

- **Flutter version pinning:** the workflow installs the latest `stable` channel.
  For bit-reproducible builds, uncomment `flutter-version:` and pin an explicit
  version (e.g. `3.24.0`) in both jobs.
- **Uploading to Stores:** consider appending `upload-artifact` → `runs-on`
  upload steps, or use third-party actions for Play Console / TestFlight delivery,
  if you later want push-button deployments.
- **Timing:** Android job ~3–6 min, iOS job ~5–9 min on fresh caches; subsequent
  runs are notably faster thanks to caching.