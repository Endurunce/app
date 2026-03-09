import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'dart:html' as html show window; // ignore: avoid_web_libraries_in_flutter
import '../../core/api_client.dart';

class AuthState {
  final String?   token;
  final String?   userId;
  final String?   email;
  final String?   displayName;
  /// Geboortedatum verplicht voor DPIA leeftijdsverificatie (minimumleeftijd 16 jaar)
  final DateTime? dateOfBirth;
  final String?   gender; // 'male' | 'female' | 'other'
  final bool      loading;
  final String?   error;

  const AuthState({
    this.token,
    this.userId,
    this.email,
    this.displayName,
    this.dateOfBirth,
    this.gender,
    this.loading = false,
    this.error,
  });

  AuthState copyWith({
    String?   token,
    String?   userId,
    String?   email,
    String?   displayName,
    DateTime? dateOfBirth,
    String?   gender,
    bool?     loading,
    String?   error,
    bool      clearError = false,
  }) => AuthState(
    token:       token       ?? this.token,
    userId:      userId      ?? this.userId,
    email:       email       ?? this.email,
    displayName: displayName ?? this.displayName,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    gender:      gender      ?? this.gender,
    loading:     loading     ?? this.loading,
    error:       clearError ? null : (error ?? this.error),
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
        token:   data['token'],
        userId:  data['user_id'],
        email:   data['email'],
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
        token:   data['token'],
        userId:  data['user_id'],
        email:   data['email'],
      );
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: _parseError(e));
      return false;
    }
  }

  /// Sla naam/geboortedatum/geslacht op na de register-stap of intake prefill.
  void setPersonalInfo({
    required String   name,
    required DateTime dateOfBirth,
    required String   gender,
  }) {
    state = state.copyWith(displayName: name, dateOfBirth: dateOfBirth, gender: gender);
  }

  Future<bool> loginWithStrava() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final client = ref.read(apiClientProvider);
      final stateParam = kIsWeb ? 'login_web' : 'login';
      final data = await client.get('/api/auth/strava?state=$stateParam');
      final authUrl = data['auth_url'] as String;

      if (kIsWeb) {
        html.window.location.href = authUrl;
        return false;
      }

      final result = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: 'endurunce',
      );

      final uri = Uri.parse(result);
      final token = uri.queryParameters['token'];
      final email = uri.queryParameters['email'] ?? '';
      final displayName = uri.queryParameters['display_name'];

      if (token == null) throw Exception('Geen token ontvangen');

      await saveToken(token);
      state = state.copyWith(
        loading:     false,
        token:       token,
        email:       email,
        displayName: displayName,
      );
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Strava login mislukt. Probeer opnieuw.');
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
        html.window.location.href = authUrl;
        return false;
      }

      final result = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: 'endurunce',
      );

      final uri = Uri.parse(result);
      final token = uri.queryParameters['token'];
      final email = uri.queryParameters['email'] ?? '';
      final displayName = uri.queryParameters['display_name'];

      if (token == null) throw Exception('Geen token ontvangen');

      await saveToken(token);
      state = state.copyWith(
        loading:     false,
        token:       token,
        email:       email,
        displayName: displayName,
      );
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Google login mislukt. Probeer opnieuw.');
      return false;
    }
  }

  /// Verwerk de naam uit de URL hash na web OAuth redirect (Strava/Google web).
  void applyWebAuthHash(String displayName) {
    if (displayName.isNotEmpty) {
      state = state.copyWith(displayName: displayName);
    }
  }

  /// Haal JWT op via een eenmalige OAuth-sessie (session-based web redirect).
  /// Returns (isOk, isNew) — isNew is true when the account was just created.
  Future<(bool, bool)> loginWithSession(String sessionId) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final client = ref.read(apiClientProvider);
      final data = await client.get('/api/auth/session/$sessionId');
      final token = data['token'] as String;
      final isNew = data['is_new'] as bool? ?? false;
      await saveToken(token);
      state = state.copyWith(
        loading:     false,
        token:       token,
        email:       data['email'] as String? ?? '',
        displayName: data['display_name'] as String?,
      );
      return (true, isNew);
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Inloggen mislukt. Probeer opnieuw.');
      return (false, false);
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
