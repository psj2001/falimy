import 'dart:io';

/// Backend API base URL.
///
/// Override at build/run time:
/// `flutter run --dart-define=API_BASE_URL=https://your-api.example.com`
class ApiConfig {
  ApiConfig._();

  static const _fromEnv = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_fromEnv.isNotEmpty) return _fromEnv.replaceAll(RegExp(r'/$'), '');
    // Android emulator → host machine loopback
    if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    // iOS simulator / desktop
    return 'http://localhost:3000';
  }
}
