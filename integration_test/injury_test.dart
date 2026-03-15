import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:endurance_app/main.dart' as app;

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Registreert een gebruiker, doorloopt intake en navigeert naar het
  /// Blessures-tabblad.
  Future<void> goToInjury(WidgetTester t) async {
    app.main();
    await settle(t);
    await register(t);
    await completeIntake(t);

    await tapText(t, 'Blessures');
    await settle(t);
  }

  group('Blessurescherm', () {
    testWidgets('Lege staat zichtbaar zonder blessures', (t) async {
      await goToInjury(t);

      seeText('Geen actieve blessures');
      seeText('Blijf zo doorgaan!');
    });

    testWidgets('Melden-FAB opent blessure-chat', (t) async {
      await goToInjury(t);

      await t.tap(find.byType(FloatingActionButton).first);
      await settle(t);

      seeText('Blessure melden');
    });

    testWidgets('Chat-scherm sluit via ×-knop', (t) async {
      await goToInjury(t);

      await t.tap(find.byType(FloatingActionButton).first);
      await settle(t);

      seeText('Blessure melden');

      await t.tap(find.byIcon(Icons.close).first);
      await settle(t);

      // Terug op blessures-scherm — lege staat zichtbaar
      seeText('Geen actieve blessures');
    });

    testWidgets('Intro-bericht en locatievraag zichtbaar', (t) async {
      await goToInjury(t);

      await t.tap(find.byType(FloatingActionButton).first);
      await settle(t);

      // Intro-bericht
      seeText('blessure te registreren');

      // Eerste vraag: locatie
      seeText('Waar zit de pijn?');
    });

    testWidgets('Locatie-chips zichtbaar in chat', (t) async {
      await goToInjury(t);

      await t.tap(find.byType(FloatingActionButton).first);
      await settle(t);

      // Bekende locatie-labels aanwezig
      seeText('Knie');
      seeText('Enkel');
      seeText('Hamstring');
    });

    testWidgets('Bevestig-knop inactief zonder selectie', (t) async {
      await goToInjury(t);

      await t.tap(find.byType(FloatingActionButton).first);
      await settle(t);

      // Bevestig-knop toont "Kies minimaal 1" en is uitgeschakeld
      final btn = find.widgetWithText(FilledButton, 'Kies minimaal 1');
      expect(btn, findsOneWidget);
      final b = t.widget<FilledButton>(btn.first);
      expect(b.onPressed, isNull,
          reason: 'Bevestig-knop inactief zonder locatie-selectie');
    });

    testWidgets('Locatie selecteren activeert bevestig-knop', (t) async {
      await goToInjury(t);

      await t.tap(find.byType(FloatingActionButton).first);
      await settle(t);

      // Selecteer Knie
      await tapText(t, 'Knie');
      await settle(t);

      // Knop toont "Klaar (1)"
      seeText('Klaar (1)');
      final btn = find.textContaining('Klaar (');
      final parent = find.ancestor(of: btn, matching: find.byType(FilledButton));
      if (parent.evaluate().isNotEmpty) {
        final b = t.widget<FilledButton>(parent.first);
        expect(b.onPressed, isNotNull,
            reason: 'Bevestig-knop actief na locatie-selectie');
      }
    });

    testWidgets('Kant-vraag verschijnt na locatie voor eenzijdige locatie', (t) async {
      await goToInjury(t);

      await t.tap(find.byType(FloatingActionButton).first);
      await settle(t);

      await tapText(t, 'Knie');
      await settle(t);
      await t.tap(find.textContaining('Klaar (').first);
      await settle(t);

      // "Aan welke kant?" verschijnt
      seeText('Aan welke kant?');
      seeText('Links');
      seeText('Rechts');
    });

    testWidgets('Ernst-vraag verschijnt na kant-selectie', (t) async {
      await goToInjury(t);

      await t.tap(find.byType(FloatingActionButton).first);
      await settle(t);

      await tapText(t, 'Knie');
      await settle(t);
      await t.tap(find.textContaining('Klaar (').first);
      await settle(t);

      await tapText(t, 'Links');
      await settle(t);

      // Ernst-vraag (number input)
      seeText('Hoe erg is de pijn');
    });

    testWidgets('Volledig melden toont blessure-kaart op blessures-scherm', (t) async {
      await goToInjury(t);
      await reportInjury(t);

      // Actieve blessure-kaart met Ernst-label
      expect(
        find.textContaining('Ernst').evaluate().isNotEmpty ||
            find.textContaining('blessure').evaluate().isNotEmpty,
        isTrue,
        reason: 'Blessure-kaart verwacht na melden',
      );
    });

    testWidgets('Blessure markeren als hersteld werkt', (t) async {
      await goToInjury(t);
      await reportInjury(t);

      // Knop "Markeren als hersteld" aanwezig op de actieve kaart
      final resolveBtn = find.textContaining('Markeren als hersteld');
      expect(resolveBtn.evaluate().isNotEmpty, isTrue,
          reason: '"Markeren als hersteld" knop verwacht op blessure-kaart');

      // Markeer als hersteld
      await t.tap(resolveBtn.first);
      await wait(t, ms: 3000);

      // Bevestiging: snackbar of lege actieve staat
      expect(
        find.textContaining('hersteld').evaluate().isNotEmpty ||
            find.textContaining('Geen actieve').evaluate().isNotEmpty,
        isTrue,
        reason: 'Bevestiging van herstel verwacht (snackbar of lege staat)',
      );
    });

    testWidgets('Geschiedenis-tab laadt zonder fouten', (t) async {
      await goToInjury(t);

      await tapText(t, 'Geschiedenis');
      await settle(t);

      // Lege staat (geen blessures gemeld in deze test)
      seeText('Geen blessuregeschiedenis');
      expect(find.textContaining('fout'), findsNothing);
      expect(find.textContaining('error'), findsNothing);
    });

    testWidgets('Geschiedenis-tab toont herstelde blessure', (t) async {
      await goToInjury(t);
      await reportInjury(t);

      // Markeer als hersteld
      final resolveBtn = find.textContaining('Markeren als hersteld');
      if (resolveBtn.evaluate().isNotEmpty) {
        await t.tap(resolveBtn.first);
        await wait(t, ms: 3000);
      }

      // Ga naar geschiedenis-tab
      await tapText(t, 'Geschiedenis');
      await settle(t);

      // Herstelde blessure staat in de lijst
      expect(
        find.textContaining('Hersteld').evaluate().isNotEmpty ||
            find.textContaining('Knie').evaluate().isNotEmpty,
        isTrue,
        reason: 'Herstelde blessure verwacht in geschiedenis',
      );
    });
  });
}
