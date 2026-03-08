import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:endurance_app/main.dart' as app;

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Registreert een nieuwe gebruiker en landt op de intake.
  Future<void> startIntake(WidgetTester t) async {
    app.main();
    await settle(t);

    await tapText(t, 'Registreren');
    await settle(t);

    await fillField(t, 0, uniqueEmail());
    await fillField(t, 1, kTestPassword);
    await tapText(t, 'Account aanmaken');
    await wait(t, ms: 3000);

    seeText('Jouw plan opmaken');
  }

  group('Intake — 7-staps onboarding', () {
    testWidgets('Stap 1: persoonlijke gegevens — stap-indicator zichtbaar',
        (t) async {
      await startIntake(t);

      seeText('Stap 1 van 7');
      seeText('Volgende');
    });

    testWidgets('Stap 1: Volgende-knop inactief zonder verplichte velden',
        (t) async {
      await startIntake(t);

      // Zonder naam/leeftijd/geslacht mag Volgende niet werken
      final nextBtn = find.widgetWithText(FilledButton, 'Volgende');
      expect(nextBtn, findsOneWidget);

      final btn = t.widget<FilledButton>(nextBtn);
      expect(btn.onPressed, isNull,
          reason: 'Volgende zou disabled moeten zijn zonder verplichte velden');
    });

    testWidgets('Stap 1 → Stap 2 na invullen persoonlijke gegevens',
        (t) async {
      await startIntake(t);

      // Naam
      await fillField(t, 0, 'Test Runner');
      // Leeftijd
      await fillField(t, 1, '30');
      // Geslacht kiezen (eerste chip/optie)
      await tapText(t, 'Man');
      await settle(t);

      await tapText(t, 'Volgende');
      await settle(t);

      seeText('Stap 2 van 7');
    });

    testWidgets('Stap 3 (PR-tijden) is overslaanbaar', (t) async {
      await startIntake(t);

      // Stap 1 invullen
      await fillField(t, 0, 'Test Runner');
      await fillField(t, 1, '30');
      await tapText(t, 'Man');
      await settle(t);
      await tapText(t, 'Volgende');
      await settle(t);

      // Stap 2: ervaring
      await tapText(t, '2–5 jaar');
      await settle(t);
      await tapText(t, 'Volgende');
      await settle(t);

      // Stap 3: PR-tijden — overslaan link aanwezig
      seeText('Stap 3 van 7');
      seeText('Overslaan');
    });

    testWidgets('Overslaan op stap 3 gaat naar stap 4', (t) async {
      await startIntake(t);

      // Snel door stap 1 en 2
      await fillField(t, 0, 'Test Runner');
      await fillField(t, 1, '30');
      await tapText(t, 'Man');
      await settle(t);
      await tapText(t, 'Volgende');
      await settle(t);

      await tapText(t, '2–5 jaar');
      await settle(t);
      await tapText(t, 'Volgende');
      await settle(t);

      // Overslaan op stap 3
      await tapText(t, 'Overslaan');
      await settle(t);

      seeText('Stap 4 van 7');
    });

    testWidgets('Terugknop gaat naar vorige stap', (t) async {
      await startIntake(t);

      await fillField(t, 0, 'Test Runner');
      await fillField(t, 1, '30');
      await tapText(t, 'Man');
      await settle(t);
      await tapText(t, 'Volgende');
      await settle(t);

      seeText('Stap 2 van 7');

      // Terug naar stap 1
      final backBtn = find.byType(BackButton).first;
      if (backBtn.evaluate().isEmpty) {
        await tapText(t, 'Terug');
      } else {
        await t.tap(backBtn);
      }
      await settle(t);

      seeText('Stap 1 van 7');
    });

    testWidgets('Stap-indicator toont voortgang', (t) async {
      await startIntake(t);

      // Stap 1 invullen en doorgaan
      await fillField(t, 0, 'Test Runner');
      await fillField(t, 1, '30');
      await tapText(t, 'Man');
      await settle(t);
      await tapText(t, 'Volgende');
      await settle(t);

      // Stap 2 zichtbaar, stap-indicator bijgewerkt
      seeText('Stap 2 van 7');

      // AnimatedContainer bars zijn aanwezig (step indicator)
      expect(find.byType(AnimatedContainer), findsAtLeastNWidgets(7),
          reason: '7 stap-indicator balken verwacht');
    });

    testWidgets('Sluitknop op stap 1 navigeert terug naar planscherm', (t) async {
      await startIntake(t);

      // Stap 1 is zichtbaar
      seeText('Stap 1 van 7');

      // Sluitknop (×) tikken
      await t.tap(find.byIcon(Icons.close).first);
      await settle(t);

      // Terug op het planscherm (of loginscherm — niet meer op intake)
      expect(
        find.text('Jouw plan opmaken').evaluate().isEmpty,
        isTrue,
        reason: 'Intake zou gesloten moeten zijn na tikken op ×',
      );
    });
  });
}
