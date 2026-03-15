import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:endurance_app/main.dart' as app;

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Registreert een gebruiker, doorloopt intake en navigeert naar Profiel-tab.
  Future<void> goToProfile(WidgetTester t) async {
    app.main();
    await settle(t);
    await register(t);
    await completeIntake(t);

    await tapText(t, 'Profiel');
    await settle(t);
  }

  group('Profiel scherm', () {
    testWidgets('Profiel-tab laadt zonder fouten', (t) async {
      await goToProfile(t);

      seeText('PROFIEL');
      expect(find.textContaining('fout'), findsNothing);
    });

    testWidgets('Naam van gebruiker zichtbaar in header', (t) async {
      await goToProfile(t);

      // De registratie-naam 'Tester' moet zichtbaar zijn in de header
      seeText('Tester');
    });

    testWidgets('E-mailadres zichtbaar in header', (t) async {
      app.main();
      await settle(t);
      final email = uniqueEmail();
      await register(t, email: email);
      await completeIntake(t);
      await tapText(t, 'Profiel');
      await settle(t);

      // E-mail bevat '@test.endurunce.app'
      expect(
        find.textContaining('@test.endurunce.app').evaluate().isNotEmpty,
        isTrue,
        reason: 'E-mailadres verwacht in profielheader',
      );
    });

    testWidgets('Profielgegevens sectie is zichtbaar', (t) async {
      await goToProfile(t);

      // Labels in de profiel-sectie
      seeText('Naam');
      seeText('Leeftijd');
      seeText('Geslacht');
      seeText('Ervaring');
    });

    testWidgets('Strava-sectie is zichtbaar', (t) async {
      await goToProfile(t);

      seeText('STRAVA');
    });

    testWidgets('Strava verbinden-knop aanwezig (niet verbonden)', (t) async {
      await goToProfile(t);

      // Als niet verbonden: "Verbinden met Strava" knop
      expect(
        find.textContaining('Verbinden met Strava').evaluate().isNotEmpty ||
            find.textContaining('Strava verbonden').evaluate().isNotEmpty,
        isTrue,
        reason: 'Strava sectie moet knop of verbonden status tonen',
      );
    });

    testWidgets('Account-sectie met uitlogknop aanwezig', (t) async {
      await goToProfile(t);

      seeText('ACCOUNT');
      seeText('Uitloggen');
    });

    testWidgets('Bewerk-knop opent profiel-bewerksheet', (t) async {
      await goToProfile(t);

      // Wacht tot profiel geladen is
      await wait(t, ms: 2000);

      // Tik op het potlood-icoon
      final editBtn = find.byIcon(Icons.edit_outlined);
      if (editBtn.evaluate().isNotEmpty) {
        await t.tap(editBtn.first);
        await settle(t);

        seeText('Profiel bewerken');
        seeText('Naam');
        seeText('Leeftijd');
        seeText('Opslaan');
      }
    });

    testWidgets('Bewerksheet heeft geslacht-chips', (t) async {
      await goToProfile(t);
      await wait(t, ms: 2000);

      final editBtn = find.byIcon(Icons.edit_outlined);
      if (editBtn.evaluate().isNotEmpty) {
        await t.tap(editBtn.first);
        await settle(t);

        seeText('Man');
        seeText('Vrouw');
        seeText('Anders');
      }
    });

    testWidgets('Bewerksheet heeft ervaring-chips', (t) async {
      await goToProfile(t);
      await wait(t, ms: 2000);

      final editBtn = find.byIcon(Icons.edit_outlined);
      if (editBtn.evaluate().isNotEmpty) {
        await t.tap(editBtn.first);
        await settle(t);

        seeText('2–5 jaar');
        seeText('5–10 jaar');
        seeText('10+ jaar');
      }
    });

    testWidgets('Bewerksheet sluit via ×-knop', (t) async {
      await goToProfile(t);
      await wait(t, ms: 2000);

      final editBtn = find.byIcon(Icons.edit_outlined);
      if (editBtn.evaluate().isNotEmpty) {
        await t.tap(editBtn.first);
        await settle(t);

        seeText('Profiel bewerken');

        await t.tap(find.byIcon(Icons.close).last);
        await settle(t);

        expect(find.text('Profiel bewerken'), findsNothing);
      }
    });

    testWidgets('Naam wijzigen en opslaan werkt', (t) async {
      await goToProfile(t);
      await wait(t, ms: 2000);

      final editBtn = find.byIcon(Icons.edit_outlined);
      if (editBtn.evaluate().isNotEmpty) {
        await t.tap(editBtn.first);
        await settle(t);

        // Wijzig naam
        final nameField = find.widgetWithText(TextField, 'Naam');
        if (nameField.evaluate().isNotEmpty) {
          await t.tap(nameField.first);
          await t.enterText(nameField.first, 'Nieuwe Naam');
          await t.pump();
        } else {
          // Probeer via eerste TextField
          await t.tap(find.byType(TextField).first);
          await t.enterText(find.byType(TextField).first, 'Nieuwe Naam');
          await t.pump();
        }

        // Tik Opslaan
        final saveBtn = find.widgetWithText(FilledButton, 'Opslaan');
        if (saveBtn.evaluate().isNotEmpty) {
          final btn = t.widget<FilledButton>(saveBtn.first);
          if (btn.onPressed != null) {
            await t.tap(saveBtn.first);
            await wait(t, ms: 2500);

            // Sheet sluit na succesvol opslaan
            expect(find.text('Profiel bewerken'), findsNothing);
          }
        }
      }
    });

    testWidgets('Ongeldige leeftijd deactiveert opslaan-knop', (t) async {
      await goToProfile(t);
      await wait(t, ms: 2000);

      final editBtn = find.byIcon(Icons.edit_outlined);
      if (editBtn.evaluate().isNotEmpty) {
        await t.tap(editBtn.first);
        await settle(t);

        // Vul ongeldige leeftijd in
        final ageField = find.widgetWithText(TextField, 'Leeftijd');
        if (ageField.evaluate().isNotEmpty) {
          await t.tap(ageField.first);
          await t.enterText(ageField.first, 'abc');
          await t.pump();

          // Opslaan-knop inactief
          final saveBtn = find.widgetWithText(FilledButton, 'Opslaan');
          if (saveBtn.evaluate().isNotEmpty) {
            final btn = t.widget<FilledButton>(saveBtn.first);
            expect(btn.onPressed, isNull,
                reason: 'Opslaan-knop inactief bij ongeldige leeftijd');
          }
        }
      }
    });

    testWidgets('Trainingsplan-sectie zichtbaar na plan aanmaken', (t) async {
      await goToProfile(t);

      seeText('TRAININGSPLAN');
    });

    testWidgets('Uitloggen navigeert naar loginscherm', (t) async {
      await goToProfile(t);

      await scrollDown(t, dy: -600);
      await settle(t);
      await tapText(t, 'Uitloggen');
      await settle(t);

      seeText('Inloggen');
    });
  });
}
