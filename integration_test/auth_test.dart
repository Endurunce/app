import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:endurance_app/main.dart' as app;

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authenticatie', () {
    testWidgets('Loginscherm is zichtbaar bij opstarten zonder sessie',
        (t) async {
      app.main();
      await settle(t);

      seeText('Inloggen');
      seeText('E-mailadres');
      seeText('Wachtwoord');
    });

    testWidgets('Foutmelding bij verkeerde inloggegevens', (t) async {
      app.main();
      await settle(t);

      await fillField(t, 0, 'onbekend@test.nl');
      await fillField(t, 1, 'verkeertwachtwoord');
      await tapText(t, 'Inloggen');
      await wait(t, ms: 2500);

      // Foutmelding moet verschijnen
      expect(
        find.textContaining('wachtwoord').evaluate().isNotEmpty ||
            find.textContaining('mislukt').evaluate().isNotEmpty ||
            find.textContaining('onjuist', findRichText: true)
                .evaluate()
                .isNotEmpty,
        isTrue,
        reason: 'Foutmelding verwacht bij onjuiste inloggegevens',
      );
    });

    testWidgets('Navigeert naar registratiescherm via link', (t) async {
      app.main();
      await settle(t);

      await tapText(t, 'Registreren');
      await settle(t);

      seeText('E-mailadres');
      seeText('Volgende');
    });

    testWidgets('Volledige registratie → intakescherm', (t) async {
      app.main();
      await settle(t);

      // Naar registratie
      await tapText(t, 'Registreren');
      await settle(t);

      // Fase 1: account
      final email = uniqueEmail();
      await fillField(t, 0, email);
      await fillField(t, 1, kTestPassword);
      await tapText(t, 'Volgende');
      await wait(t, ms: 2500);

      // Fase 2: persoonlijk
      await fillField(t, 0, 'Test Runner');
      await tapText(t, 'Geboortedatum kiezen');
      await settle(t);
      await tapText(t, 'OK');
      await settle(t);
      await tapText(t, 'Man');
      await settle(t);
      await tapText(t, 'Plan opmaken');
      await wait(t, ms: 1000);

      // Na registratie moet de intake starten
      seeText('Jouw plan opmaken');
    });

    testWidgets('Login met geldig account navigeert naar planscherm', (t) async {
      app.main();
      await settle(t);

      // Registreer een nieuw account
      final email = uniqueEmail();
      await register(t, email: email);

      // Sluit intake en ga naar profiel om uit te loggen
      final closeBtn = find.byIcon(Icons.close);
      if (closeBtn.evaluate().isNotEmpty) {
        await t.tap(closeBtn.first);
        await settle(t);
      }
      await tapText(t, 'Profiel');
      await settle(t);
      await scrollDown(t, dy: -600);
      await settle(t);
      await tapText(t, 'Uitloggen');
      await settle(t);

      // Login met het zojuist aangemaakte account
      await fillField(t, 0, email);
      await fillField(t, 1, kTestPassword);
      await tapText(t, 'Inloggen');
      await wait(t, ms: 3000);

      // Moet landing op plan of intake zijn (al ingelogd)
      expect(
        find.textContaining('Trainingsplan').evaluate().isNotEmpty ||
            find.textContaining('Nog geen').evaluate().isNotEmpty ||
            find.textContaining('Jouw plan').evaluate().isNotEmpty,
        isTrue,
        reason: 'Na login verwacht planscherm of intakescherm',
      );
    });

    testWidgets('Terugknop op registratiescherm gaat naar login', (t) async {
      app.main();
      await settle(t);

      await tapText(t, 'Registreren');
      await settle(t);

      await tapText(t, 'Inloggen');
      await settle(t);

      seeText('Inloggen');
      noText('Account aanmaken');
    });
  });
}
