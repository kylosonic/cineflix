import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await dotenv.load();
    _initialized = true;
  }

  static String get tmdbApiKey => dotenv.env['TMDB_API_KEY'] ?? '';
  static String get tmdbBaseUrl =>
      dotenv.env['TMDB_BASE_URL'] ?? 'https://api.themoviedb.org/3';
  static String get tmdbImageBaseUrl =>
      dotenv.env['TMDB_IMAGE_BASE_URL'] ?? 'https://image.tmdb.org/t/p';

  static const String githubReleasePageUrl =
      'https://github.com/kylosonic/cineflix/releases/latest';
  static const String githubReleaseDownloadBaseUrl =
      'https://github.com/kylosonic/cineflix/releases/latest/download';
  static const String androidDownloadUrl =
      '$githubReleaseDownloadBaseUrl/CineFlix-android-unsigned.apk';
  static const String iosDownloadUrl =
      '$githubReleaseDownloadBaseUrl/CineFlix-ios-unsigned.ipa';
}
