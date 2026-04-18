// lib/core/constants/api_constants.dart

import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (override.isNotEmpty) return override;

    if (kIsWeb) return 'http://localhost:8080';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8080';
      case TargetPlatform.iOS:
        return 'http://127.0.0.1:8080';
      default:
        return 'http://localhost:8080';
    }
  }

  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authLogout = '/auth/logout';
  static const String authRefresh = '/auth/refresh-token';

  static const String usersMe = '/users/me';
  static const String usersMePassword = '/users/me/password';
  static const String usersMePhoto = '/users/me/photo';

  static const String todos = '/todos';
  static String todoById(String id) => '/todos/$id';
  static String todoCover(String id) => '/todos/$id/cover';
}
