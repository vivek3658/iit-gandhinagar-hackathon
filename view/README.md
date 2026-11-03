# URJA View

Android-first Flutter citizen app for UrjaVatika. It connects to the existing
Fastify API and includes Google sign-in, daily missions, learning activities,
community rankings, household device tracking, and the 3D sparrow garden.

## Run locally

Install a Flutter SDK with Dart 3.9.2 or newer and configure an Android device
or emulator. From this directory:

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=https://urjaone.vercel.app/api/v1
```

In Google Cloud, configure an Android OAuth client for this app's Android
application ID and signing certificate, and a Web application OAuth client.
The Web client ID from the existing Flutter app is configured as the default
server client ID and is used to request the ID token accepted by the backend.
Override it with `--dart-define=GOOGLE_SERVER_CLIENT_ID=...` if the OAuth
configuration changes. Do not put OAuth client secrets in the app.

The new app reuses the existing Android application ID
`com.geda.urjavatika.urja` so the registered Android OAuth client can be used.
The local debug signing certificate SHA-1 is
`13:E7:9F:F5:28:DA:C7:96:10:94:BB:97:56:FD:2F:43:9D:31:A4:5B`. The debug
package and SHA-1 must be registered together in Google Cloud. Release builds
signed with a different key need that key's SHA-1 registered as well.

Installing this app over the old app with the same package and signing
certificate updates that app installation. Back up any old-app data you need
before installing.

For a local API, use an HTTPS address reachable from the device. Android
emulators can reach a host machine at `10.0.2.2`; physical devices need the
host's reachable LAN address.

## Device tracking notes

Discovery is opt-in and limited to supported BLE advertisements and selected
mDNS service types. It does not scan arbitrary network hosts or send device
addresses to the backend. Discovery identifies a nearby device, not whether an
appliance is currently consuming power.

Operating hours are user-entered. When rated power is supplied, the app labels
energy as a rated-power estimate; otherwise it records runtime only. Neither
method is live telemetry, and the app does not infer CO2 savings from these
records.

## Validation

From this directory, run `flutter analyze` and `flutter build apk --debug`.
Backend device-registry tests live in `../backend/test/devices-registry.test.ts`.
