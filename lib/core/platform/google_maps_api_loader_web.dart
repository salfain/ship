import 'dart:js_interop';

@JS('shipMonitoring.loadGoogleMaps')
external JSPromise<JSBoolean> _loadGoogleMaps(JSString apiKey);

Future<bool> loadGoogleMapsApi(String apiKey) async {
  if (apiKey.isEmpty) return false;
  final loaded = await _loadGoogleMaps(apiKey.toJS).toDart;
  return loaded.toDart;
}
