import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/platform/google_maps_api_loader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _configureAndroidGoogleMapsRenderer();
  await initializeDateFormatting('id_ID');
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Running without .env is allowed for tests and fresh CI environments.
  }

  runApp(const ProviderScope(child: ShipMonitoringApp()));
  unawaited(initializeGoogleMapsApi(Env.googleMapsWebApiKey));
}

void _configureAndroidGoogleMapsRenderer() {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

  final mapsImplementation = GoogleMapsFlutterPlatform.instance;
  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    mapsImplementation.useAndroidViewSurface = true;
  }
}
