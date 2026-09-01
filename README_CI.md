# CI/CD Guide — chiti

## Overview

This repository ships a GitHub Actions workflow (`.github/workflows/build.yml`) that:

- Builds **Android** (`app-release.apk` + `app-release.aab`) on `ubuntu-latest`.
- Runs `flutter analyze` and `flutter test` as fail-fast quality gates.
- Caches the **Flutter SDK**, **pub cache**, and **Gradle** to keep runs fast.

The pipeline triggers on `push`/`pull_request` against `main`, `master`, or `develop`,
and can also be started manually from the **Actions → Run workflow** button.

---

## How to download the generated `.apk` / `.aab`

1. Open the **Actions** tab in your GitHub repository.
2. Select the **flutter-ci-build** workflow from the left sidebar.
3. Click on the run you are interested in (the most recent is on top).
4. Scroll to the bottom of the run page. Under the **Artifacts** heading of the
   **run summary** you will see `chiti-android-release`, which contains:
   - `app-release.apk` (instalable Android APK)
   - `app-release.aab` (App Bundle for Play Console upload)
5. Click the artifact name to download the `.zip`. Extract it, then use:
   - `app-release.apk` → install on a phone, or upload to the Play Console.
   - `app-release.aab` → upload to the Play Console (release track or internal testing).

Artifacts expire after 90 days by default; they are only retained for
successfully-completed runs.

---

## Enabling a signed, release-ready build (optional)

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

---

## Tuning notes

- **Flutter version pinning:** the workflow installs the latest `stable` channel.
  For bit-reproducible builds, uncomment `flutter-version:` and pin an explicit
  version (e.g. `3.24.0`).
- **Uploading to Play Console:** consider appending upload steps, or use
  third-party actions for Play Console delivery, if you want push-button deployments.
- **Timing:** Android job ~3–6 min on fresh caches; subsequent runs are notably
  faster thanks to caching.