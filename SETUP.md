# Local Setup: API and Flutter App

This guide covers running the Fastify API and Flutter Android app locally and building/installing a profile APK. The Windows development API uses in-memory stores for selected data, so PostgreSQL, Redis, MongoDB, and RabbitMQ are not required for a basic run. In-memory data is temporary and is lost when the API restarts.

## Prerequisites

- Git
- Node.js 20 or newer and npm
- Flutter SDK compatible with Dart 3.9.2 or newer
- Android Studio or Android SDK command-line tools for an emulator or USB-connected Android device
- Android SDK Platform Tools (`adb`) to install an APK from PowerShell

Check the tools:

```powershell
node --version
npm --version
flutter doctor
adb --version
```

## Start the API

Open PowerShell at the repository root and run:

```powershell
Set-Location backend
npm ci
npm run dev
```

The API listens on port `3000` and binds to `0.0.0.0` by default. In another PowerShell window, verify it:

```powershell
Invoke-RestMethod http://localhost:3000/health
```

Swagger UI is at `http://localhost:3000/docs`; the OpenAPI JSON is at `http://localhost:3000/docs/json`.

For basic local development, leave `DATABASE_URL`, `REDIS_URL`, `MONGODB_URL`, and `RABBITMQ_URL` unset. If you create `backend/.env`, use `NODE_ENV=development`, `PORT=3000`, `HOST=0.0.0.0`, and a local-only `JWT_SECRET` of at least 32 characters. Do not copy the example integration URLs unchanged: they point at services that may not be running. Never commit `.env` or real credentials.

## Run the Flutter Android App

In a second PowerShell window at the repository root:

```powershell
Set-Location mobile
flutter pub get
flutter devices
```

Start an Android emulator or connect a phone with USB debugging enabled. Use the API URL for your device type:

- Android emulator: `http://10.0.2.2:3000/api/v1`
- Physical Android phone on the same Wi-Fi: `http://<your-computer-LAN-IP>:3000/api/v1`

For a physical phone, find the computer's LAN address with `ipconfig`, keep the API running, and allow inbound port `3000` through Windows Firewall if prompted. Do not use `localhost` in the phone's API URL; it refers to the phone itself.

Run the app on the selected device (replace `<device-id>` with the ID shown by `flutter devices`):

```powershell
flutter run -d <device-id> `
  --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```

For a physical phone, replace the URL with your computer's LAN address. Google sign-in requires OAuth client configuration for this app's Android package and signing certificate. To use a specific web/server OAuth client, pass the same client ID to the API's `GOOGLE_CLIENT_ID` and Flutter's `GOOGLE_SERVER_CLIENT_ID`; without valid OAuth configuration, Google sign-in may not work even though the app and API start.

## Build and Install a Profile APK

A **profile** APK is useful for performance profiling and device demonstrations. It is not a production release and should not be uploaded to the Play Store. From the repository root:

```powershell
Set-Location mobile
flutter build apk --profile `
  --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```

For a physical phone, use the computer's LAN IP instead of `10.0.2.2`. The generated file is:

```text
mobile/build/app/outputs/flutter-apk/app-profile.apk
```

Connect the device with USB debugging enabled, confirm it appears in `adb devices`, then install from the repository root:

```powershell
adb devices
adb install -r mobile/build/app/outputs/flutter-apk/app-profile.apk
```

If Android reports a signing conflict with an already-installed copy, uninstalling that copy may be required before installing this build; uninstalling removes the app's local data. You can also install from the phone by transferring the APK, but Android may require approval for that file manager to install apps.

### Play Protect and APK warnings

Android or Google Play Protect may warn about or block an APK installed outside Google Play, especially an unfamiliar profile/debug-signed build. For judges, prefer a properly signed build distributed through a Google Play Console internal-testing track, or install the APK on a dedicated demo device yourself; do not ask judges to weaken protection on their personal phones.

If you choose to install a profile APK that you built yourself on your own dedicated demo device, Android may require a temporary Play Protect exception. This reduces device protection: use it only for that trusted APK, restore Play Protect immediately afterward, and never proceed if Play Protect identifies the APK as harmful or its origin is uncertain. In the Google Play Store app, open the profile menu, select **Play Protect** > **Settings**, and temporarily turn off **Scan apps with Play Protect** if that option is available; install your APK, then turn scanning back on immediately. Labels can vary by Android version. Do not ask judges to disable protection on their personal devices.

Calculate the local APK hash in PowerShell:

```powershell
Get-FileHash mobile/build/app/outputs/flutter-apk/app-profile.apk -Algorithm SHA256
```

## Signed Release Builds

Profile and release builds are different. A release APK/AAB requires a private upload keystore and local `mobile/android/key.properties`; never commit either. Follow [RELEASE.md](RELEASE.md) for signing setup, Google OAuth release configuration, and signed APK/AAB build commands. For Play Console distribution, use the signed app bundle and an internal-testing track rather than a profile APK.

## Optional Backend Checks

From `backend/`:

```powershell
npm test
npm run lint
```
