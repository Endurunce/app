import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:endurance_app/main.dart' as app;

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Registreert een gebruiker en doorloopt de volledige intake zodat
  /// een trainingsplan beschikbaar is.
  Future<void> setupPlanScreen(WidgetTester t) async {
    app.main();
    await settle(t);

    await tapText(t, 'Registreren');
    await settle(t);

    // Fase 1: account aanmaken
    await fillField(t, 0, uniqueEmail());
    await fillField(t, 1, kTestPassword);
    await tapText(t, 'Volgende');
    await wait(t, ms: 2500);

    // Fase 2: persoonlijk (naam/leeftijd/geslacht)
    await fillField(t, 0, 'Test Runner');
    await fillField(t, 1, '28');
    await tapText(t, 'Man');
    await settle(t);
    await tapText(t, 'Plan opmaken');
    await wait(t, ms: 1000);

    // Intake — stap 1 is overgeslagen (prefilled), start bij stap 2 (ervaring)
    await tapText(t, '2–5 jaar');
    await settle(t);
    await tapText(t, 'Volgende');
    await settle(t);

    // Stap 3 — PR-tijden overslaan
    await tapText(t, 'Overslaan');
    await settle(t);

    // Stap 4 — race doel
    await tapText(t, 'Marathon');
    await settle(t);
    await tapText(t, 'Weg');
    await settle(t);
    // Datum: kies de eerste beschikbare datum via de picker
    await tapText(t, 'Kies datum');
    await settle(t);
    await tapText(t, 'OK');
    await settle(t);
    await tapText(t, 'Volgende');
    await settle(t);

    // Stap 5 — trainingsdagen
    await tapText(t, 'Ma');
    await tapText(t, 'Wo');
    await tapText(t, 'Vr');
    await tapText(t, 'Zo');
    await settle(t);
    // Lange loopdag = Zo
    await tapText(t, 'Lange loop');
    await settle(t);
    await tapText(t, 'Volgende');
    await settle(t);

    // Stap 6 — hartslag overslaan
    await tapText(t, 'Overslaan');
    await settle(t);

    // Stap 7 — slaap
    await tapText(t, '7–8 uur');
    await settle(t);
    await tapText(t, 'Plan aanmaken');
    await wait(t, ms: 6000); // wacht op AI plan generatie
  }

  group('Trainingsplan scherm', () {
    testWidgets('"Nog geen trainingsplan" zichtbaar vóór intake', (t) async {
      app.main();
      await settle(t);

      // Registreer een verse gebruiker en sluit de intake direct
      await tapText(t, 'Registreren');
      await settle(t);

      await fillField(t, 0, uniqueEmail());
      await fillField(t, 1, kTestPassword);
      await tapText(t, 'Volgende');
      await wait(t, ms: 2500);

      await fillField(t, 0, 'Test Runner');
      await fillField(t, 1, '28');
      await tapText(t, 'Man');
      await settle(t);
      await tapText(t, 'Plan opmaken');
      await wait(t, ms: 1000);

      // Gebruiker is in intake — klik sluitknop (×)
      final closeBtn = find.byIcon(Icons.close);
      if (closeBtn.evaluate().isNotEmpty) {
        await t.tap(closeBtn.first);
        await settle(t);
      }

      // Nu op het planscherm zonder plan
      seeText('Nog geen trainingsplan');
      seeText('Plan aanmaken');
    });

    testWidgets('Plan aanmaken-knop navigeert naar intake', (t) async {
      app.main();
      await settle(t);

      await tapText(t, 'Registreren');
      await settle(t);

      await fillField(t, 0, uniqueEmail());
      await fillField(t, 1, kTestPassword);
      await tapText(t, 'Volgende');
      await wait(t, ms: 2500);

      await fillField(t, 0, 'Test Runner');
      await fillField(t, 1, '28');
      await tapText(t, 'Man');
      await settle(t);
      await tapText(t, 'Plan opmaken');
      await wait(t, ms: 1000);

      final closeBtn = find.byIcon(Icons.close);
      if (closeBtn.evaluate().isNotEmpty) {
        await t.tap(closeBtn.first);
        await settle(t);
      }

      await tapText(t, 'Plan aanmaken');
      await settle(t);

      seeText('Jouw plan opmaken');
    });

    testWidgets('Planscherm toont weekoverzicht na intake', (t) async {
      await setupPlanScreen(t);

      seeText('Trainingsplan');
      // Weken zijn zichtbaar
      expect(find.textContaining('Week '), findsAtLeastNWidgets(1));
    });

    testWidgets('Plan-header toont race-doel en progressie', (t) async {
      await setupPlanScreen(t);

      // Header met doelkilometrage en voortgangsring
      expect(find.textContaining('weken'), findsAtLeastNWidgets(1));
      expect(find.textContaining('km'), findsAtLeastNWidgets(1));
    });

    testWidgets('Navigatie-tabs zichtbaar (5 tabs)', (t) async {
      await setupPlanScreen(t);

      // NavigationBar met 5 items
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(5));
    });

    testWidgets('Klik op week opent weekdetailscherm', (t) async {
      await setupPlanScreen(t);

      // Tik op de eerste weekkaart
      await t.tap(find.textContaining('Week 1').first);
      await settle(t);

      seeText('Week 1');
      // Dagkaarten aanwezig
      expect(find.textContaining('km'), findsAtLeastNWidgets(1));
    });

    testWidgets('Weekdetail toont 7 dagen', (t) async {
      await setupPlanScreen(t);

      await t.tap(find.textContaining('Week 1').first);
      await settle(t);

      // Daglabels Ma t/m Zo
      final dayLabels = ['MA', 'DI', 'WO', 'DO', 'VR', 'ZA', 'ZO'];
      for (final label in dayLabels) {
        expect(find.textContaining(label), findsAtLeastNWidgets(1),
            reason: 'Dag $label ontbreekt in weekdetail');
      }
    });

    testWidgets('Pijl-navigatie tussen weken werkt', (t) async {
      await setupPlanScreen(t);

      await t.tap(find.textContaining('Week 1').first);
      await settle(t);

      seeText('Week 1');

      // Volgende-week pijl
      await t.tap(find.byIcon(Icons.chevron_right).first);
      await settle(t);

      seeText('Week 2');

      // Vorige-week pijl
      await t.tap(find.byIcon(Icons.chevron_left).first);
      await settle(t);

      seeText('Week 1');
    });

    testWidgets('Tab-navigatie naar Coach-scherm', (t) async {
      await setupPlanScreen(t);

      await tapText(t, 'Coach');
      await settle(t);

      seeText('Coach');
    });

    testWidgets('Tab-navigatie naar Tips-scherm', (t) async {
      await setupPlanScreen(t);

      await tapText(t, 'Tips');
      await settle(t);

      seeText('Tips & uitleg');
    });

    testWidgets('Uitloggen navigeert terug naar loginscherm', (t) async {
      await setupPlanScreen(t);

      // Ga naar het Profiel-tab
      await tapText(t, 'Profiel');
      await settle(t);

      // Scroll naar de uitlogknop en tik erop
      await scrollDown(t, dy: -600);
      await settle(t);
      await tapText(t, 'Uitloggen');
      await settle(t);

      seeText('Inloggen');
    });
  });
}
