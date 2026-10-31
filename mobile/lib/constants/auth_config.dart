// URJA ONE - Client Authentication & OAuth Configuration
// Paste your Google OAuth credentials here.

class AuthConfig {
  /// Web / Backend Server Client ID (from Google Cloud Console)
  /// Used by GoogleSignIn on Android/iOS to get the server `idToken` to send to Fastify backend.
  static const String googleServerClientId = '382767216032-3744ggt0eifce7jcq0v4ff34fub5ml7s.apps.googleusercontent.com';

  /// Android Client ID (Optional if google-services.json is configured, but recommended)
  static const String googleAndroidClientId = '382767216032-d8jk3j1psfdb6qomicevbev1d43vj5ob.apps.googleusercontent.com';

  /// Fastify Backend API Base URL
  /// Over USB with `adb reverse tcp:3000 tcp:3000`, use `http://127.0.0.1:3000/api/v1`
  /// Over Wi-Fi on physical device use: `http://10.17.14.80:3000/api/v1`
  /// For Android Emulator use: `http://10.0.2.2:3000/api/v1`
  static const String apiBaseUrl = 'http://127.0.0.1:3000/api/v1';

  /// ImageKit Public Key for client-side uploads (avatar photo)
  static const String imageKitPublicKey = 'public_mock_imagekit_key';
  static const String imageKitUrlEndpoint = 'https://ik.imagekit.io/urjavatika';
}
