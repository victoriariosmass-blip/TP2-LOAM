// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:mi_primer_app/main.dart';

void main() {
  testWidgets('Dino 2048 screen displays its header and controls', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const Dino2048App());

    expect(find.text('USUARIO: JUGADOR1'), findsOneWidget);
    expect(find.text('SCORE: 0'), findsOneWidget);
    expect(find.text('INICIO'), findsOneWidget);
    expect(find.text('PAUSA'), findsOneWidget);
    expect(find.text('REINICIAR'), findsOneWidget);
    expect(find.text('NUEVA'), findsOneWidget);
  });
}
