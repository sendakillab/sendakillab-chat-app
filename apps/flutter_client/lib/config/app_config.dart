import 'package:flutter/foundation.dart';

class AppConfig {
  static const String appName = 'SendakilLab';

  /// Override at runtime with:
  /// flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
  static const String _definedApiUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    if (_definedApiUrl.isNotEmpty) return _definedApiUrl;

    // Android emulator maps the Windows/macOS host to 10.0.2.2.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }

    // Flutter Web, Windows, macOS and Linux when backend is on same machine.
    return 'http://localhost:8000';
  }
}
