import 'package:flutter/foundation.dart';

import 'google_maps_api_loader_stub.dart'
    if (dart.library.js_interop) 'google_maps_api_loader_web.dart'
    as platform;

final ValueNotifier<bool> googleMapsApiReady = ValueNotifier<bool>(!kIsWeb);

bool get isGoogleMapsApiReady => googleMapsApiReady.value;

Future<void> initializeGoogleMapsApi(String apiKey) async {
  try {
    googleMapsApiReady.value = await platform.loadGoogleMapsApi(apiKey.trim());
  } catch (_) {
    // A failed Web SDK request must not prevent the rest of the application
    // from starting. ShipMapCard will use its existing preview fallback.
    googleMapsApiReady.value = false;
  }
}
