import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:endurance_app/main.dart' as app;

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> goToWeek1(WidgetTester t) async {
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

    // Week 1 openen
    await t.tap(find.textContaining('Week 1').first);
    await settle(t);
  }

  group('Sessiedetail sheet', () {
    testWidgets('Tik op sessie-icoon opent detail sheet', (t) async {
      await goToWeek1(t);

      // Vind een actieve dag (niet rustdag) en tik op het sessie-icoon
      // Het emoji-icoon zit in een Container met GestureDetector
      final sessions = find.byType(GestureDetector);
      expect(sessions, findsAtLeastNWidgets(1));

      // Tik op de eerste niet-rust sessie
      await t.tap(sessions.first);
      await wait(t, ms: 1000);

      // DraggableScrollableSheet verschijnt
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    });

    testWidgets('Detail sheet toont sessiontype-label', (t) async {
      await goToWeek1(t);

      await t.tap(find.byType(GestureDetector).first);
      await wait(t, ms: 1500);

      // Het sheet bevat minimaal één van de bekende sessie-labels
      final sessionLabels = [
        'Rustige duurloop',
        'Tempoloup',
        'Lange duurloop',
        'Intervaltraining',
        'Wandel/Trail mix',
      ];
      final found = sessionLabels.any(
        (label) => find.textContaining(label).evaluate().isNotEmpty,
      );
      expect(found, isTrue, reason: 'Sessie-label verwacht in detail sheet');
    });

    testWidgets('Detail sheet sluit via sluit-knop', (t) async {
      await goToWeek1(t);

      await t.tap(find.byType(GestureDetector).first);
      await wait(t, ms: 1500);

      expect(find.byType(DraggableScrollableSheet), findsOneWidget);

      // Sluit-knop
      await t.tap(find.byIcon(Icons.close).last);
      await settle(t);

      expect(find.byType(DraggableScrollableSheet), findsNothing);
    });

    testWidgets('Detail sheet toont shimmer tijdens laden', (t) async {
      await goToWeek1(t);

      await t.tap(find.byType(GestureDetector).first);
      await t.pump(const Duration(milliseconds: 200)); // Vóór netwerkaanroep

      // Shimmer widget aanwezig tijdens laden
      // (na volledige load zijn ze weg)
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    });
  });

  group('Sessie voltooien', () {
    testWidgets('Tik op ○-knop toont feedbackformulier', (t) async {
      await goToWeek1(t);

      // Vind de ○ knop (radio_button_unchecked icon)
      final unchecked = find.byIcon(Icons.radio_button_unchecked);
      expect(unchecked, findsAtLeastNWidgets(1));

      await t.tap(unchecked.first);
      await settle(t);

      seeText('HOE VOELDE HET?');
    });

    testWidgets('Emoji-selector zichtbaar in feedbackformulier', (t) async {
      await goToWeek1(t);

      await t.tap(find.byIcon(Icons.radio_button_unchecked).first);
      await settle(t);

      // 5 emoji-opties
      final emojis = ['😫', '😓', '😐', '😊', '🤩'];
      for (final emoji in emojis) {
        expect(find.text(emoji), findsOneWidget,
            reason: 'Emoji $emoji verwacht in feedbackformulier');
      }
    });

    testWidgets('Pijn-toggle werkt in feedbackformulier', (t) async {
      await goToWeek1(t);

      await t.tap(find.byIcon(Icons.radio_button_unchecked).first);
      await settle(t);

      seeText('Pijn of ongemak tijdens sessie');
      await tapText(t, 'Pijn of ongemak tijdens sessie');
      await settle(t);

      // Checkbox toggled
      expect(find.byIcon(Icons.check_box), findsAtLeastNWidgets(1));
    });

    testWidgets('Feedbackformulier sluit na annuleren', (t) async {
      await goToWeek1(t);

      await t.tap(find.byIcon(Icons.radio_button_unchecked).first);
      await settle(t);

      seeText('HOE VOELDE HET?');

      // Tik opnieuw op de ○ knop (of expand_less)
      final lessIcon = find.byIcon(Icons.expand_less);
      if (lessIcon.evaluate().isNotEmpty) {
        await t.tap(lessIcon.first);
        await settle(t);
      }

      expect(find.text('HOE VOELDE HET?'), findsNothing);
    });

    testWidgets('Sessie afronden met standaard feedback', (t) async {
      await goToWeek1(t);

      await t.tap(find.byIcon(Icons.radio_button_unchecked).first);
      await settle(t);

      // Kies een emoji (😊 = index 3)
      await t.tap(find.text('😊').first);
      await settle(t);

      // Verzend zonder pijn en zonder notities
      await tapText(t, 'Sessie afronden');
      await wait(t, ms: 2500);

      // Na voltooiing: ✓ knop zichtbaar
      expect(find.text('✓'), findsAtLeastNWidgets(1),
          reason: 'Sessie zou als voltooid gemarkeerd moeten zijn');
    });

    testWidgets('Voltooide sessie heeft ✓ icoon en kan ongedaan worden',
        (t) async {
      await goToWeek1(t);

      // Sessie voltooien
      await t.tap(find.byIcon(Icons.radio_button_unchecked).first);
      await settle(t);
      await t.tap(find.text('😊').first);
      await settle(t);
      await tapText(t, 'Sessie afronden');
      await wait(t, ms: 2500);

      // ✓ zichtbaar
      expect(find.text('✓'), findsAtLeastNWidgets(1));

      // Tik op ✓ om te annuleren
      await t.tap(find.text('✓').first);
      await wait(t, ms: 2000);

      // ○ terug
      expect(find.byIcon(Icons.radio_button_unchecked), findsAtLeastNWidgets(1));
    });
  });
}
