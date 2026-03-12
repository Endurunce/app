import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:endurance_app/main.dart' as app;

import 'helpers.dart';

const _apiBase = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:3000');

/// Roept de backend test-endpoint aan en geeft een OAuth session_id terug.
/// Vereist TEST_MODE=true op de server.
Future<String> _createTestOAuthSession() async {
  final client = HttpClient();
  try {
    final req = await client.postUrl(
      Uri.parse('$_apiBase/api/test/oauth-session'),
    );
    req.headers.set('content-type', 'application/json');
    final resp = await req.close();
    final body = await utf8.decodeStream(resp);
    final data = jsonDecode(body) as Map<String, dynamic>;
    return data['session_id'] as String;
  } finally {
    client.close();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('OAuth inloggen (sessie-exchange)', () {
    testWidgets('Geldige sessie → ingelogd en planscherm zichtbaar', (t) async {
      app.main();
      await settle(t);

      seeText('Inloggen'); // Begint op loginscherm

      // Maak een test OAuth sessie aan via de backend (simuleert Google/Strava callback)
      late String sessionId;
      await t.runAsync(() async {
        sessionId = await _createTestOAuthSession();
      });

      // Navigeer naar /oauth?session=<id> — exact zoals de browser doet na OAuth redirect
      GoRouter.of(t.element(find.byType(Scaffold).first))
          .go('/oauth?session=$sessionId');

      await wait(t, ms: 3000);
      await settle(t);

      // Na succesvolle sessie-exchange: niet meer op loginscherm
      noText('E-mailadres');
      noText('Wachtwoord');
      // Plan scherm (geen plan aangemaakt) is zichtbaar
      seeText('Nog geen trainingsplan');
    });

    testWidgets('Verlopen/ongeldige sessie → terug naar loginscherm', (t) async {
      app.main();
      await settle(t);

      seeText('Inloggen');

      // Navigeer met nep session-ID
      GoRouter.of(t.element(find.byType(Scaffold).first))
          .go('/oauth?session=00000000-0000-0000-0000-000000000000');

      await wait(t, ms: 3000);
      await settle(t);

      // Moet teruggaan naar loginscherm
      seeText('Inloggen');
    });

    testWidgets('Ontbrekende sessie-parameter → terug naar loginscherm', (t) async {
      app.main();
      await settle(t);

      seeText('Inloggen');

      // Navigeer naar /oauth zonder session param
      GoRouter.of(t.element(find.byType(Scaffold).first)).go('/oauth');

      await wait(t, ms: 1000);
      await settle(t);

      seeText('Inloggen');
    });
  });
}
