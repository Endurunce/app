// Web implementation using dart:html.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void openUrl(String url) {
  html.window.open(url, '_blank');
}

void setLocationHref(String url) {
  html.window.location.href = url;
}

void clearFlutterSecureStorageWeb() {
  try {
    final keys = html.window.localStorage.keys
        .where((k) => k.startsWith('FlutterSecureStorage'))
        .toList();
    for (final k in keys) {
      html.window.localStorage.remove(k);
    }
  } catch (_) {}
}
