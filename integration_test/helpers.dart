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
