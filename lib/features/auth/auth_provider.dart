import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_client.dart';

class AuthState {
  final String? token;
  final String? userId;
  final String? email;
  final bool loading;
  final String? error;

  const AuthState({
    this.token,
    this.userId,
    this.email,
    this.loading = false,
    this.error,
  });

  AuthState copyWith({
    String? token,
    String? userId,
    String? email,
    bool? loading,
    String? error,
    bool clearError = false,
  }) => AuthState(
    token:   token   ?? this.token,
    userId:  userId  ?? this.userId,
    email:   email   ?? this.email,
    loading: loading ?? this.loading,
    error:   clearError ? null : (error ?? this.error),
  );
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<void> init() async {
    final token = await getToken();
    if (token != null) {
      state = state.copyWith(token: token);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final client = ref.read(apiClientProvider);
      final data = await client.post('/api/auth/login', {
        'email': email,
        'password': password,
      });
      await saveToken(data['token']);
      state = state.copyWith(
        loading: false,
        token: data['token'],
        userId: data['user_id'],
        email: data['email'],
      );
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: _parseError(e));
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final client = ref.read(apiClientProvider);
      final data = await client.post('/api/auth/register', {
        'email': email,
        'password': password,
      });
      await saveToken(data['token']);
      state = state.copyWith(
        loading: false,
        token: data['token'],
        userId: data['user_id'],
        email: data['email'],
      );
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: _parseError(e));
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final client = ref.read(apiClientProvider);
      final stateParam = kIsWeb ? 'web' : 'app';
      final data = await client.get('/api/auth/google?state=$stateParam');
      final authUrl = data['auth_url'] as String;

      if (kIsWeb) {
        // On web: redirect current tab to Google; token arrives via URL hash on return
        await launchUrl(Uri.parse(authUrl), webOnlyWindowName: '_self');
        return false;
      }

      final result = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: 'endurunce',
      );

      final uri = Uri.parse(result);
      final token = uri.queryParameters['token'];
      final email = uri.queryParameters['email'] ?? '';

      if (token == null) throw Exception('Geen token ontvangen');

      await saveToken(token);
      state = state.copyWith(loading: false, token: token, email: email);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Google login mislukt. Probeer opnieuw.');
      return false;
    }
  }

  Future<void> logout() async {
    await deleteToken();
    state = const AuthState();
  }

  String _parseError(Object e) {
    if (e.toString().contains('400')) return 'Onjuist e-mailadres of wachtwoord.';
    if (e.toString().contains('SocketException')) return 'Geen verbinding met de server.';
    return 'Er is iets misgegaan. Probeer opnieuw.';
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
