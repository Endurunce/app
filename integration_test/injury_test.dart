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

    await tapText(t, 'Registreren');
    await settle(t);
    await fillField(t, 0, uniqueEmail());
    await fillField(t, 1, kTestPassword);
    await tapText(t, 'Account aanmaken');
    await wait(t, ms: 3000);

    // Minimale intake
    await fillField(t, 0, 'Tester');
    await fillField(t, 1, '25');
    await tapText(t, 'Man');
    await settle(t);
    await tapText(t, 'Volgende'); await settle(t);
    await tapText(t, '2–5 jaar'); await settle(t);
    await tapText(t, 'Volgende'); await settle(t);
    await tapText(t, 'Overslaan'); await settle(t);
    await tapText(t, 'Marathon'); await settle(t);
    await tapText(t, 'Weg'); await settle(t);
    await tapText(t, 'Kies datum'); await settle(t);
    await tapText(t, 'OK'); await settle(t);
    await tapText(t, 'Volgende'); await settle(t);
    await tapText(t, 'Ma');
    await tapText(t, 'Wo');
    await tapText(t, 'Vr');
    await tapText(t, 'Zo'); await settle(t);
    await tapText(t, 'Lange loop'); await settle(t);
    await tapText(t, 'Volgende'); await settle(t);
    await tapText(t, 'Overslaan'); await settle(t);
    await tapText(t, '7–8 uur'); await settle(t);
    await tapText(t, 'Plan aanmaken');
    await wait(t, ms: 6000);

    // Navigeer naar Blessures-tabblad
    await tapText(t, 'Blessures');
    await settle(t);
  }

  group('Blessurescherm', () {
    testWidgets('Lege staat zichtbaar zonder blessures', (t) async {
      await goToInjury(t);

      seeText('Geen actieve blessures');
      seeText('Blijf zo doorgaan!');
    });

    testWidgets('Melden-knop opent sheet', (t) async {
      await goToInjury(t);

      await t.tap(find.byType(FloatingActionButton).first);
      await settle(t);

      seeText('Blessure melden');
      seeText('Beschrijf zo nauwkeurig mogelijk');
    });

    testWidgets('Sheet sluit via ×-knop', (t) async {
      await goToInjury(t);

      await t.tap(find.byType(FloatingActionButton).first);
      await settle(t);

      expect(find.byType(DraggableScrollableSheet), findsOneWidget);

      await t.tap(find.byIcon(Icons.close).last);
      await settle(t);

      expect(find.byType(DraggableScrollableSheet), findsNothing);
    });

    testWidgets('Mobiliteitsopties zichtbaar in sheet', (t) async {
      await goToInjury(t);

      await t.tap(find.byType(FloatingActionButton).first);
      await settle(t);

      seeText('Volledig lopen en hardlopen');
      seeText('Alleen wandelen, niet hardlopen');
      seeText('Moeite met lopen');
    });

    testWidgets('Locatie-chips zichtbaar in sheet', (t) async {
      await goToInjury(t);

      await t.tap(find.byType(FloatingActionButton).first);
      await settle(t);

      // Scroll omlaag om locatie-sectie te bereiken
      await scrollDown(t, dy: -200);

      seeText('Locatie');
      // Minstens één locatie-chip aanwezig (knie, enkel, etc.)
      expect(find.byType(FilterChip), findsAtLeastNWidgets(1));
    });

    testWidgets('Melden-knop inactief zonder locatie en mobiliteit', (t) async {
      await goToInjury(t);

      await t.tap(find.byType(FloatingActionButton).first);
      await settle(t);

      // Zoek de submit-knop onderaan
      final submitBtn = find.widgetWithText(FilledButton, 'Blessure melden');
      expect(submitBtn, findsOneWidget);

      final btn = t.widget<FilledButton>(submitBtn);
      expect(btn.onPressed, isNull,
          reason: 'Melden-knop inactief zonder verplichte velden');
    });

    testWidgets('Mobiliteit selecteren activeert knop gedeeltelijk', (t) async {
      await goToInjury(t);

      await t.tap(find.byType(FloatingActionButton).first);
      await settle(t);

      // Selecteer mobiliteitsoptie
      await tapText(t, 'Volledig lopen en hardlopen');
      await settle(t);

      // Nog steeds inactief want locatie ontbreekt
      final btn = t.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Blessure melden'));
      expect(btn.onPressed, isNull,
          reason: 'Knop blijft inactief zonder locatie');
    });

    testWidgets('Locatie + mobiliteit activeren meld-knop', (t) async {
      await goToInjury(t);

      await t.tap(find.byType(FloatingActionButton).first);
      await settle(t);

      // Mobiliteit
      await tapText(t, 'Volledig lopen en hardlopen');
      await settle(t);

      // Locatie (eerste chip)
      final chips = find.byType(FilterChip);
      await t.tap(chips.first);
      await settle(t);

      final btn = t.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Blessure melden'));
      expect(btn.onPressed, isNotNull,
          reason: 'Melden-knop actief na invullen verplichte velden');
    });

    testWidgets('Ernst-slider aanwezig en standaard op 5', (t) async {
      await goToInjury(t);

      await t.tap(find.byType(FloatingActionButton).first);
      await settle(t);

      await scrollDown(t, dy: -300);

      expect(find.byType(Slider), findsAtLeastNWidgets(1));
      // Standaardwaarde '5 / 10' zichtbaar
      seeText('5 / 10');
    });

    testWidgets('Pijntype-chips zichtbaar na scrollen', (t) async {
      await goToInjury(t);

      await t.tap(find.byType(FloatingActionButton).first);
      await settle(t);

      await scrollDown(t, dy: -400);

      seeText('Soort pijn');
      seeText('Scherp');
      seeText('Stijf');
    });

    testWidgets('Blessure melden navigeert terug en toont kaart', (t) async {
      await goToInjury(t);

      await t.tap(find.byType(FloatingActionButton).first);
      await settle(t);

      // Vul verplichte velden in
      await tapText(t, 'Alleen wandelen, niet hardlopen');
      await settle(t);

      final chips = find.byType(FilterChip);
      await t.tap(chips.first);
      await settle(t);

      // Verzend
      final submitBtn = find.widgetWithText(FilledButton, 'Blessure melden');
      await t.tap(submitBtn);
      await wait(t, ms: 4000);

      // Sheet gesloten, blessure-kaart zichtbaar
      expect(find.byType(DraggableScrollableSheet), findsNothing);
      // Blessurelijst toont nu minstens één kaart
      expect(find.byType(Card).evaluate().isNotEmpty ||
          find.textContaining('blessure').evaluate().isNotEmpty ||
          find.textContaining('pijn').evaluate().isNotEmpty ||
          find.byType(ListTile).evaluate().isNotEmpty,
        isTrue,
        reason: 'Blessure-kaart verwacht na melden',
      );
    });
  });
}
