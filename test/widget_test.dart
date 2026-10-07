// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
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

  testWidgets('buying a diamond pack updates the displayed balance', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const Dino2048App());

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('TIENDA DE DIAMANTES'), findsOneWidget);
    expect(find.text('PUÑADO'), findsOneWidget);
    expect(find.text('LLUVIA'), findsOneWidget);

    await tester.tap(find.text(r'$500 ARS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('60'), findsOneWidget);
  });

  testWidgets('light and dark modes apply to the game shell and diamond shop', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const Dino2048App());

    final rootScaffold = find.byType(Scaffold).first;
    expect(
      tester.widget<Scaffold>(rootScaffold).backgroundColor,
      const Color(0xFFCBF3F0),
    );
    final restartButton = find.byWidgetPredicate(
      (widget) => widget is BrutalistButton && widget.text == 'REINICIAR',
    );
    expect(
      tester.widget<BrutalistButton>(restartButton).color,
      const Color(0xFFFF6B6B),
    );
    final themeToggle = find.byTooltip('Cambiar a modo oscuro').first;
    final toggleMaterial = find
        .descendant(of: themeToggle, matching: find.byType(Material))
        .first;
    expect(tester.widget<Material>(toggleMaterial).shape, isA<CircleBorder>());

    await tester.tap(themeToggle);
    await tester.pump();

    expect(
      tester.widget<Scaffold>(rootScaffold).backgroundColor,
      const Color(0xFF17172E),
    );
    expect(
      tester.widget<BrutalistButton>(restartButton).color,
      const Color(0xFFFF8994),
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final shopScaffold = find.byType(Scaffold).last;
    expect(
      tester.widget<Scaffold>(shopScaffold).backgroundColor,
      const Color(0xFF17172E),
    );

    await tester.tap(find.byTooltip('Cambiar a modo claro').last);
    await tester.pump();

    expect(
      tester.widget<Scaffold>(shopScaffold).backgroundColor,
      const Color(0xFFCBF3F0),
    );

    await tester.tap(find.byTooltip('Volver al juego'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      tester.widget<Scaffold>(rootScaffold).backgroundColor,
      const Color(0xFFCBF3F0),
    );
  });

  testWidgets(
    'restart advertisement blocks play until its 8-second timer ends',
    (WidgetTester tester) async {
      await tester.pumpWidget(const Dino2048App());

      await tester.tap(find.text('REINICIAR'));
      await tester.pump();

      expect(find.text('PUBLICIDAD'), findsNothing);
      expect(find.text('Dino Bites es una marca ficticia.'), findsNothing);
      expect(find.text('DINO BITES'), findsOneWidget);
      expect(find.text('¡DINO BITES A TAN SOLO \$1200 ARS!'), findsOneWidget);
      expect(
        find.text(
          'Conseguí tus galletitas de dinosaurios favoritas en la tienda más cercana',
        ),
        findsOneWidget,
      );
      expect(find.text('ESPERÁ 8 SEG.'), findsOneWidget);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'ESPERÁ 8 SEG.'),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(
              find.ancestor(
                of: find.byIcon(Icons.close),
                matching: find.byType(IconButton),
              ),
            )
            .onPressed,
        isNull,
      );

      await tester.pump(const Duration(seconds: 7));
      expect(find.text('ESPERÁ 1 SEG.'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('¡A JUGAR!'), findsOneWidget);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, '¡A JUGAR!'),
            )
            .onPressed,
        isNotNull,
      );

      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, '¡A JUGAR!'),
          )
          .onPressed!
          .call();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('DINO BITES'), findsNothing);
    },
  );
}
