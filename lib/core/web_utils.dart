// Conditional export: picks the web implementation when dart.library.html
// is available, otherwise falls back to the stub.
export 'web_utils_stub.dart'
    if (dart.library.html) 'web_utils_web.dart';
