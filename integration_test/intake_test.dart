import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:endurance_app/main.dart' as app;

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Registreert een nieuwe gebruiker en landt op de intake.
  /// Na registratie (fase 2 prefilled) start de intake bij stap 1 van 6
  /// (ervaring) — persoonlijke gegevens zijn al ingevuld via de registratie.
  Future<void> startIntake(WidgetTester t) async {
    app.main();
    await settle(t);
    await register(t);

    seeText('Jouw plan opmaken');
  }

  group('Intake — onboarding na registratie', () {
    testWidgets('Eerste intakestap toont Stap 1 van 6 (ervaring)', (t) async {
      await startIntake(t);

      seeText('Stap 1 van 6');
      seeText('Volgende');
    });

    testWidgets('Ervaring kiezen gaat naar stap 2 van 6', (t) async {
      await startIntake(t);

      await tapText(t, '2–5 jaar');
      await settle(t);
      await tapText(t, 'Volgende');
      await settle(t);

      seeText('Stap 2 van 6');
    });

    testWidgets('Stap 2 (PR-tijden) is overslaanbaar', (t) async {
      await startIntake(t);

      await tapText(t, '2–5 jaar');
      await settle(t);
      await tapText(t, 'Volgende');
      await settle(t);

      seeText('Stap 2 van 6');
      seeText('Overslaan');
    });

    testWidgets('Overslaan op stap 2 gaat naar stap 3', (t) async {
      await startIntake(t);

      await tapText(t, '2–5 jaar');
      await settle(t);
      await tapText(t, 'Volgende');
      await settle(t);

      await tapText(t, 'Overslaan');
      await settle(t);

      seeText('Stap 3 van 6');
    });

    testWidgets('Terugknop gaat naar vorige stap', (t) async {
      await startIntake(t);

      await tapText(t, '2–5 jaar');
      await settle(t);
      await tapText(t, 'Volgende');
      await settle(t);

      seeText('Stap 2 van 6');

      // Terug naar stap 1
      final backBtn = find.byType(BackButton);
      if (backBtn.evaluate().isNotEmpty) {
        await t.tap(backBtn.first);
      } else {
        await tapText(t, 'Terug');
      }
      await settle(t);

      seeText('Stap 1 van 6');
    });

    testWidgets('Stap-indicator toont 6 stappen', (t) async {
      await startIntake(t);

      // 6 AnimatedContainer balken verwacht
      expect(find.byType(AnimatedContainer), findsAtLeastNWidgets(6),
          reason: '6 stap-indicator balken verwacht');
    });

    testWidgets('Sluitknop navigeert terug (intake afbreken)', (t) async {
      await startIntake(t);

      seeText('Stap 1 van 6');

      await t.tap(find.byIcon(Icons.close).first);
      await settle(t);

      expect(
        find.text('Jouw plan opmaken').evaluate().isEmpty,
        isTrue,
        reason: 'Intake zou gesloten moeten zijn na tikken op ×',
      );
    });
  });
}
