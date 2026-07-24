import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ui/token_ui.dart';

void main() {
  testWidgets('TuButton renders with built-in theme (no TuTheme)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TuButton.neutral.medium(label: 'Tap', onPressed: () {}),
        ),
      ),
    );
    expect(find.text('Tap'), findsOneWidget);
  });

  testWidgets('TuTheme brand colors apply to button', (tester) async {
    const brandNeutral = Color(0xFFC45C26);
    final colors = TuColors.builtIn(ThemeMode.dark);
    final branded = TuColors(
      mode: ThemeMode.dark,
      bg: colors.bg,
      component: colors.component,
      mask: colors.mask,
      text: colors.text,
      button: const TuButtonColors(
        primary: Colors.white,
        secondary: Colors.grey,
        neutral: brandNeutral,
      ),
      error: colors.error,
      success: colors.success,
    );

    await tester.pumpWidget(
      TuTheme(
        colors: branded,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ColoredBox(
                  color: context.colors.button.neutral,
                  child: const SizedBox(width: 10, height: 10),
                );
              },
            ),
          ),
        ),
      ),
    );

    final box = tester.widget<ColoredBox>(find.byType(ColoredBox));
    expect(box.color, brandNeutral);
  });
}
