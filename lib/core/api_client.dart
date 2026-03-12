import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'web_utils.dart' as web_utils;

const _baseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:3000',
);

final _storage = FlutterSecureStorage();

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

/// Clears all FlutterSecureStorage keys from localStorage on web.
/// Needed when the crypto key is lost but encrypted values remain,
/// which causes OperationError from SubtleCrypto.decrypt().
void _clearWebStorage() {
  if (!kIsWeb) return;
  web_utils.clearFlutterSecureStorageWeb();
}

/// Reads the JWT token, returning null on any crypto / storage error.
/// On error, clears all FlutterSecureStorage web keys so subsequent
/// writes/reads work cleanly.
Future<String?> _safeReadToken() async {
  try {
    return await _storage.read(key: 'jwt_token');
  } catch (_) {
    _clearWebStorage();
    return null;
  }
}

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ));

    // Attach JWT token to every request
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _safeReadToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ));
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> data) async {
    final resp = await _dio.post(path, data: data);
    return resp.data as Map<String, dynamic>;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? params}) async {
    final resp = await _dio.get(path, queryParameters: params);
    return resp.data;
  }

  Future<void> patch(String path, {Map<String, dynamic>? data}) async {
    await _dio.patch(path, data: data);
  }
}

// Token helpers
Future<void> saveToken(String token) =>
    _storage.write(key: 'jwt_token', value: token);

Future<String?> getToken() => _safeReadToken();

Future<void> deleteToken() async {
  try {
    await _storage.delete(key: 'jwt_token');
  } catch (_) {
    _clearWebStorage();
  }
}
