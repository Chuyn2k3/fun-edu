import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Build-time settings for the online features (passed with --dart-define):
///
///   flutter run --dart-define=FUNEDU_API_URL=https://api.example.com \
///     --dart-define=GOOGLE_SERVER_CLIENT_ID=<web client id> \
///     --dart-define=APPLE_SERVICE_ID=<services id, Android only>
///
/// Without FUNEDU_API_URL the app has no online features at all and never
/// touches the network.
class OnlineConfig {
  const OnlineConfig({
    required this.apiUrl,
    this.googleServerClientId = '',
    this.appleServiceId = '',
  });

  const OnlineConfig.fromEnvironment()
      : apiUrl = const String.fromEnvironment('FUNEDU_API_URL'),
        googleServerClientId =
            const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
        appleServiceId = const String.fromEnvironment('APPLE_SERVICE_ID');

  /// Base URL of the FunEdu server, without a trailing slash.
  final String apiUrl;

  /// Google OAuth "web" client id: Google puts it in the id token's `aud`.
  final String googleServerClientId;

  /// Apple Services ID used for Sign in with Apple on Android.
  final String appleServiceId;

  bool get enabled => apiUrl.isNotEmpty;

  Uri uri(String path) => Uri.parse('$apiUrl$path');
}

final onlineConfigProvider =
    Provider<OnlineConfig>((ref) => const OnlineConfig.fromEnvironment());
