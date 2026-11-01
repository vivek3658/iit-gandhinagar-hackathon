// URJA ONE - Client Authentication & OAuth Configuration
//
// Values can be supplied at build/run time via:
// flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=your_web_client_id --dart-define=API_BASE_URL=https://urjaone.vercel.app/api/v1
//
// On Android, GoogleSignIn automatically resolves client credentials via the Android package
// name (com.geda.urjavatika.urja) and SHA-1 certificate in Google Cloud Console.

class AuthConfig {
  /// Web / Backend Server Client ID (from Google Cloud Console)
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '382767216032-3744ggt0eifce7jcq0v4ff34fub5ml7s.apps.googleusercontent.com',
  );

  /// Android OAuth client ID, supplied at build time if required.
  static const String googleAndroidClientId = String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
    defaultValue: '',
  );

  /// Fastify Backend API Base URL
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
