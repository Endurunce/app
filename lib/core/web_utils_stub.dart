// Stub for non-web platforms — dart:html is not available.

void openUrl(String url) {
  // No-op on non-web platforms; use url_launcher instead.
}

void setLocationHref(String url) {
  // No-op on non-web platforms.
}

void clearFlutterSecureStorageWeb() {
  // No-op on non-web platforms.
}
