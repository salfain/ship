import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Running without .env is allowed for tests and fresh CI environments.
  }

  runApp(const ProviderScope(child: ShipMonitoringApp()));
}
