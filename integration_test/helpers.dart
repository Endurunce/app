import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unique e-mail voor elke testrun zodat registratie altijd lukt
String uniqueEmail() =>
    'e2e+${DateTime.now().millisecondsSinceEpoch}@test.endurunce.app';

const kTestPassword = 'Test1234!';

// ── Pump helpers ─────────────────────────────────────────────────────────────

/// Wacht maximaal [seconds] op rust (geen pending frames / animaties).
/// Veilig voor netwerkaanroepen: pumpAndSettle zou anders vastlopen.
Future<void> settle(WidgetTester t, {int seconds = 8}) async {
  await t.pumpAndSettle(Duration(seconds: seconds));
}

/// Pump een vaste tijd — handig na netwerkaanroepen die nog draaien.
Future<void> wait(WidgetTester t, {int ms = 2000}) async {
  await t.pump(Duration(milliseconds: ms));
  await t.pump(Duration(milliseconds: ms));
}

// ── Tap helpers ───────────────────────────────────────────────────────────────

/// Tik op de eerste widget die de gegeven tekst bevat.
Future<void> tapText(WidgetTester t, String text) async {
  final finder = find.text(text);
  await t.ensureVisible(finder.first);
  await t.tap(finder.first);
  await t.pump(const Duration(milliseconds: 300));
}

/// Tik op de eerste widget van het opgegeven type.
Future<void> tapType<W extends Widget>(WidgetTester t) async {
  await t.tap(find.byType(W).first);
  await t.pump(const Duration(milliseconds: 300));
}

// ── Input helpers ─────────────────────────────────────────────────────────────

/// Vult het eerste TextField in met [text] en verplaatst focus daarna.
Future<void> fillFirstField(WidgetTester t, String text) async {
  await t.tap(find.byType(TextField).first);
  await t.enterText(find.byType(TextField).first, text);
  await t.pump();
}

/// Vult TextField met index [n] in.
Future<void> fillField(WidgetTester t, int n, String text) async {
  final fields = find.byType(TextField);
  await t.tap(fields.at(n));
  await t.enterText(fields.at(n), text);
  await t.pump();
}

// ── Assert helpers ─────────────────────────────────────────────────────────────

/// Verwacht dat de tekst zichtbaar is op het scherm.
void seeText(String text) =>
    expect(find.textContaining(text), findsAtLeastNWidgets(1),
        reason: '"$text" zou zichtbaar moeten zijn');

/// Verwacht dat de tekst NIET zichtbaar is.
void noText(String text) =>
    expect(find.text(text), findsNothing,
        reason: '"$text" zou niet zichtbaar moeten zijn');

/// Verwacht dat een widget van type [W] aanwezig is.
void seeType<W extends Widget>() =>
    expect(find.byType(W), findsAtLeastNWidgets(1));

// ── Scroll helpers ─────────────────────────────────────────────────────────────

/// Scroll omlaag in de eerste scrollable.
Future<void> scrollDown(WidgetTester t, {double dy = -400}) async {
  await t.drag(find.byType(Scrollable).first, Offset(0, dy));
  await t.pump(const Duration(milliseconds: 300));
}

// ── Registratie helpers ───────────────────────────────────────────────────────

/// Voert de volledige twee-fase registratie uit en landt op de intake.
///
/// Fase 1: e-mail + wachtwoord → Volgende
/// Fase 2: naam + geboortedatum (date picker, accepteer standaard 2000) + geslacht → Plan opmaken
Future<void> register(
  WidgetTester t, {
  String? email,
  String name = 'Tester',
}) async {
  await tapText(t, 'Registreren');
  await settle(t);

  // Fase 1
  await fillField(t, 0, email ?? uniqueEmail());
  await fillField(t, 1, kTestPassword);
  await tapText(t, 'Volgende');
  await wait(t, ms: 2500);

  // Fase 2
  await fillField(t, 0, name);
  // Geboortedatum via date picker — accepteer standaard (jaar 2000, leeftijd 24+)
  await tapText(t, 'Geboortedatum kiezen');
  await settle(t);
  await tapText(t, 'OK');
  await settle(t);
  await tapText(t, 'Man');
  await settle(t);
  await tapText(t, 'Plan opmaken');
  await wait(t, ms: 1000);
}

// ── Blessure helpers ──────────────────────────────────────────────────────────

/// Meldt een blessure via het chat-formulier en keert terug naar Blessures.
///
/// Verwacht dat de huidige route het Blessures-scherm is (FAB zichtbaar).
Future<void> reportInjury(WidgetTester t) async {
  // Open blessure-chat via FAB
  await t.tap(find.byType(FloatingActionButton).first);
  await settle(t);

  // Stap 1: Locatie (multi-chips) — selecteer Knie
  await tapText(t, 'Knie');
  await settle(t);
  // Bevestig de selectie ("Klaar (1)")
  await t.tap(find.textContaining('Klaar (').first);
  await settle(t);

  // Stap 2: Kant — selecteer Links (Knie is eenzijdig)
  await tapText(t, 'Links');
  await settle(t);

  // Stap 3: Ernst (number) — typ 5 en verstuur via send-icoon
  await t.enterText(find.byType(TextField).first, '5');
  await t.pump();
  await t.tap(find.byIcon(Icons.send).first);
  await settle(t);

  // Stap 4: Pijntype — selecteer Stekend
  await tapText(t, 'Stekend');
  await settle(t);

  // Stap 5: Wanneer — selecteer Alleen tijdens bewegen
  await tapText(t, 'Alleen tijdens bewegen');
  await settle(t);

  // Stap 6: Hoe lang — selecteer 1–3 dagen
  await tapText(t, '1–3 dagen');
  await settle(t);

  // Stap 7: Kan normaal lopen — Ja
  await tapText(t, 'Ja');
  await settle(t);

  // Stap 8: Kan hardlopen — Nee
  await tapText(t, 'Nee');
  await settle(t);

  // Stap 9: Beschrijving — overslaan
  await tapText(t, 'Overslaan');
  await wait(t, ms: 4000); // wacht op API-aanroep

  // Navigeer terug: tik op "Klaar" (geen plan wijzigingen) of "Plan houden"
  final klaarBtn = find.widgetWithText(FilledButton, 'Klaar');
  if (klaarBtn.evaluate().isNotEmpty) {
    await t.tap(klaarBtn.first);
  } else {
    final planHouden = find.text('Plan houden');
    if (planHouden.evaluate().isNotEmpty) {
      await t.tap(planHouden.first);
    } else {
      // Fallback: sluit via ×-knop
      await t.tap(find.byIcon(Icons.close).first);
    }
  }
  await settle(t);
}

/// Volledige intake doorlopen na registratie (begint bij stap 2 — stap 1 is
/// prefilled vanuit de registratie).
Future<void> completeIntake(WidgetTester t) async {
  await tapText(t, '2–5 jaar'); await settle(t);
  await tapText(t, 'Volgende'); await settle(t);
  await tapText(t, 'Overslaan'); await settle(t);   // PR-tijden
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
  await tapText(t, 'Overslaan'); await settle(t);   // hartslag
  await tapText(t, '7–8 uur'); await settle(t);
  await tapText(t, 'Plan aanmaken');
  await wait(t, ms: 6000); // wacht op AI plan generatie
}
