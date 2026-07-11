import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static const _fallbackApiBaseUrl =
      'https://ship-monitoring-be.vercel.app/api';

  static String get apiBaseUrl {
    final value = dotenv.env['API_BASE_URL']?.trim();
    return _withTrailingSlash(
      value == null || value.isEmpty ? _fallbackApiBaseUrl : value,
    );
  }

  static String get googleMapsApiKey {
    return dotenv.env['GOOGLE_MAPS_API_KEY']?.trim() ?? '';
  }

  static bool get managerDecisionEnabled {
    final value = dotenv.env['MANAGER_DECISION_ENABLED']?.trim().toLowerCase();
    return value == 'true' || value == '1' || value == 'yes';
  }

  static String _withTrailingSlash(String value) {
    return value.endsWith('/') ? value : '$value/';
  }
}
