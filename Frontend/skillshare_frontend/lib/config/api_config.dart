import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

class ApiConfig {
  static String baseUrl() {
    const defined = String.fromEnvironment('BASE_URL', defaultValue: '');
    if (defined.isNotEmpty) {
      return defined;
    }

    const defaultPort = String.fromEnvironment('API_PORT', defaultValue: '8081');

    if (kIsWeb) {
      return 'http://localhost:$defaultPort';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:$defaultPort';
    }

    return 'http://localhost:$defaultPort';
  }
}
