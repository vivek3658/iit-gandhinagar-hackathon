// URJA ONE - Client Authentication & OAuth Configuration
//
// ZERO hardcoded secrets in version control!
// Values can be supplied at build/run time via:
// flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=your_web_client_id --dart-define=API_BASE_URL=https://urjaone.vercel.app/api/v1
//
// On Android, GoogleSignIn automatically resolves client credentials via the Android package
// name (com.geda.urjavatika.urja) and SHA-1 certificate in Google Cloud Console.

class AuthConfig {
  /// Web / Backend Server Client ID (from Google Cloud Console)
  /// Provided at build time via --dart-define=GOOGLE_SERVER_CLIENT_ID=...
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  /// Android OAuth client ID, supplied at build time if required.
  static const String googleAndroidClientId = String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
    defaultValue: '',
  );

  /// Fastify Backend API Base URL
  /// - Physical device via Wi-Fi: http://10.17.14.80:3000/api/v1
  /// - USB with `adb reverse tcp:3000 tcp:3000`: http://127.0.0.1:3000/api/v1
  /// - Android Emulator: http://10.0.2.2:3000/api/v1
  /// - Production deployment: https://urjaone.vercel.app/api/v1
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://urjaone.vercel.app/api/v1',
  );

  /// ImageKit Public Key for client-side uploads (avatar photo)
  static const String imageKitPublicKey = String.fromEnvironment(
    'IMAGEKIT_PUBLIC_KEY',
    defaultValue: 'public_mock_imagekit_key',
  );

  static const String imageKitUrlEndpoint = String.fromEnvironment(
    'IMAGEKIT_URL_ENDPOINT',
    defaultValue: 'https://ik.imagekit.io/urjavatika',
  );
}
