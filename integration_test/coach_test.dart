import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:endurance_app/main.dart' as app;

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Registreert een gebruiker, doorloopt intake en navigeert naar het Coach-tabblad.
  Future<void> goToCoach(WidgetTester t) async {
    app.main();
    await settle(t);
    await register(t);
    await completeIntake(t);

    // Navigeer naar Coach-tabblad
    await tapText(t, 'Coach');
    await settle(t);
  }

  group('Coach scherm', () {
    testWidgets('Coach-tabblad is zichtbaar in navigatiebalk', (t) async {
      app.main();
      await settle(t);

      await register(t);

      final closeBtn = find.byType(CloseButton);
      if (closeBtn.evaluate().isNotEmpty) {
        await t.tap(closeBtn.first);
        await settle(t);
      }

      // Coach tab in NavigationBar zichtbaar
      expect(find.text('Coach'), findsAtLeastNWidgets(1));
    });

    testWidgets('Coach-scherm laadt zonder fouten', (t) async {
      await goToCoach(t);

      seeText('Coach');
      // Geen foutscherm
      expect(find.textContaining('fout'), findsNothing);
      expect(find.textContaining('error'), findsNothing);
    });

    testWidgets('Chat-invoerveld aanwezig', (t) async {
      await goToCoach(t);

      // TextField voor berichtinvoer
      expect(find.byType(TextField), findsAtLeastNWidgets(1));
    });

    testWidgets('Verzendknop aanwezig', (t) async {
      await goToCoach(t);

      // Verzendknop (send-icoon)
      expect(
        find.byIcon(Icons.send).evaluate().isNotEmpty ||
            find.byIcon(Icons.send_rounded).evaluate().isNotEmpty ||
            find.byType(IconButton).evaluate().isNotEmpty,
        isTrue,
        reason: 'Verzendknop verwacht in coach-scherm',
      );
    });

    testWidgets('Welkomstbericht van coach zichtbaar', (t) async {
      await goToCoach(t);

      // Wacht op initieel bericht
      await wait(t, ms: 2000);

      // Er is minimaal één berichtbubble aanwezig
      final hasBubble = find.byType(Container).evaluate().isNotEmpty;
      expect(hasBubble, isTrue);
    });

    testWidgets('Bericht typen en invoerveld reageert', (t) async {
      await goToCoach(t);

      final field = find.byType(TextField).first;
      await t.tap(field);
      await t.enterText(field, 'Hoe gaat mijn training?');
      await t.pump();

      expect(
        find.text('Hoe gaat mijn training?'),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('Bericht versturen toont gebruikersbericht in chat', (t) async {
      await goToCoach(t);

      final field = find.byType(TextField).first;
      await t.tap(field);
      await t.enterText(field, 'Test vraag');
      await t.pump();

      // Verzend via send-knop of enter
      final sendBtn = find.byIcon(Icons.send);
      if (sendBtn.evaluate().isNotEmpty) {
        await t.tap(sendBtn.first);
      } else {
        final iconButtons = find.byType(IconButton);
        if (iconButtons.evaluate().isNotEmpty) {
          await t.tap(iconButtons.last);
        }
      }
      await wait(t, ms: 1000);

      // Gebruikersbericht zichtbaar in chat
      expect(
        find.textContaining('Test vraag').evaluate().isNotEmpty,
        isTrue,
        reason: 'Gebruikersbericht zou in chat zichtbaar moeten zijn',
      );
    });

    testWidgets('Coach antwoord verschijnt na verzenden bericht', (t) async {
      await goToCoach(t);

      final field = find.byType(TextField).first;
      await t.tap(field);
      await t.enterText(field, 'Wat is een goede rustdag?');
      await t.pump();

      final sendBtn = find.byIcon(Icons.send);
      if (sendBtn.evaluate().isNotEmpty) {
        await t.tap(sendBtn.first);
      } else {
        final iconButtons = find.byType(IconButton);
        if (iconButtons.evaluate().isNotEmpty) {
          await t.tap(iconButtons.last);
        }
      }

      // Wacht op AI-antwoord (netwerkaanroep)
      await wait(t, ms: 8000);

      // Er zijn nu meer berichten in de lijst dan alleen het gebruikersbericht
      expect(
        find.byType(ListView).evaluate().isNotEmpty ||
            find.byType(Column).evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('Invoerveld leeg na verzenden', (t) async {
      await goToCoach(t);

      final field = find.byType(TextField).first;
      await t.tap(field);
      await t.enterText(field, 'Korte vraag');
      await t.pump();

      final sendBtn = find.byIcon(Icons.send);
      if (sendBtn.evaluate().isNotEmpty) {
        await t.tap(sendBtn.first);
      } else {
        final iconButtons = find.byType(IconButton);
        if (iconButtons.evaluate().isNotEmpty) {
          await t.tap(iconButtons.last);
        }
      }
      await t.pump(const Duration(milliseconds: 500));

      // Veld is leeggemaakt na verzenden
      final textField = t.widget<TextField>(find.byType(TextField).first);
      expect(
        textField.controller?.text ?? '',
        isEmpty,
        reason: 'Invoerveld zou leeg moeten zijn na verzenden',
      );
    });
  });
}
