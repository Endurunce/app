import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// const _baseUrl = 'http://10.0.2.2:3000'; // Android emulator → localhost
const _baseUrl = 'https://endurunce-api.fly.dev'; // Production

final _storage = FlutterSecureStorage();

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

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
        final token = await _storage.read(key: 'jwt_token');
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

Future<String?> getToken() => _storage.read(key: 'jwt_token');

Future<void> deleteToken() => _storage.delete(key: 'jwt_token');
