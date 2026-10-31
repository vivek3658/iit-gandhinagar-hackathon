// URJA ONE - Client Authentication & OAuth Configuration
// Paste your Google OAuth credentials here.

class AuthConfig {
  /// Web / Backend Server Client ID (from Google Cloud Console)
  /// Used by GoogleSignIn on Android/iOS to get the server `idToken` to send to Fastify backend.
  static const String googleServerClientId = 'YOUR_GOOGLE_SERVER_CLIENT_ID.apps.googleusercontent.com';

  /// Android Client ID (Optional if google-services.json is configured, but recommended)
  static const String googleAndroidClientId = 'YOUR_GOOGLE_ANDROID_CLIENT_ID.apps.googleusercontent.com';

  /// Fastify Backend API Base URL
  /// For Android Emulator use: `http://10.0.2.2:3000/api/v1`
  /// For Physical Device (over local Wi-Fi) use: `http://YOUR_LAPTOP_IP:3000/api/v1`
  static const String apiBaseUrl = 'http://10.0.2.2:3000/api/v1';

  /// ImageKit Public Key for client-side uploads (avatar photo)
  static const String imageKitPublicKey = 'public_mock_imagekit_key';
  static const String imageKitUrlEndpoint = 'https://ik.imagekit.io/urjavatika';
}
