import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:endurance_app/main.dart' as app;

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Registreert een gebruiker, doorloopt intake en navigeert naar Tips-tab.
  Future<void> goToTips(WidgetTester t) async {
    app.main();
    await settle(t);
    await register(t);
    await completeIntake(t);

    await tapText(t, 'Tips');
    await settle(t);
  }

  group('Tips scherm', () {
    testWidgets('Tips-tab navigeert naar Tips & uitleg', (t) async {
      await goToTips(t);

      seeText('Tips & uitleg');
    });

    testWidgets('Alle 6 tip-titels zijn zichtbaar', (t) async {
      await goToTips(t);

      seeText('De AI Coach');
      seeText('Adaptief schema');
      seeText('10% opbouwritme');
      seeText('Herstelwaarschuwingen');
      seeText('Slaap als trainingstool');
    });

    testWidgets('Tip over trail ultra is zichtbaar na scrollen', (t) async {
      await goToTips(t);

      await scrollDown(t, dy: -300);

      seeText('Trail & wandelstrategie voor ultra\'s');
    });

    testWidgets('Tip-inhoud bevat verwachte tekst', (t) async {
      await goToTips(t);

      // AI Coach tip-inhoud
      seeText('profiel en trainingsdata');
    });

    testWidgets('Tips-emojis zijn zichtbaar', (t) async {
      await goToTips(t);

      seeText('🤖');
      seeText('📅');
      seeText('📈');
    });

    testWidgets('Tips-scherm bevat geen foutmeldingen', (t) async {
      await goToTips(t);

      expect(find.textContaining('fout'), findsNothing);
      expect(find.textContaining('error'), findsNothing);
    });
  });
}
