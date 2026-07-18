import '../config/env.dart';

class PublicFileUrl {
  static const _localHosts = {'localhost', '127.0.0.1', '0.0.0.0'};

  static String? resolve(Object? value, {String? apiBaseUrl}) {
    final raw = value is String ? value.trim() : '';
    if (raw.isEmpty) return null;

    final fileUri = Uri.tryParse(raw);
    if (fileUri == null) return raw;

    final shouldUseApiOrigin =
        !fileUri.hasScheme || _localHosts.contains(fileUri.host.toLowerCase());
    if (!shouldUseApiOrigin) return raw;

    final apiUri = Uri.tryParse(apiBaseUrl ?? Env.apiBaseUrl);
    if (apiUri == null || !apiUri.hasScheme || apiUri.host.isEmpty) return raw;

    final path = fileUri.path.startsWith('/')
        ? fileUri.path
        : '/${fileUri.path}';
    return Uri(
      scheme: apiUri.scheme,
      host: apiUri.host,
      port: apiUri.hasPort ? apiUri.port : null,
      path: path,
      query: fileUri.hasQuery ? fileUri.query : null,
      fragment: fileUri.hasFragment ? fileUri.fragment : null,
    ).toString();
  }
}
