import 'package:coartada/game/model.dart';
import 'package:coartada/theme/app_theme.dart';
import 'package:coartada/widgets/furniture_glyph.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  testWidgets('every piece of furniture paints without errors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Row(
          children: [
            for (final f in Furniture.values) FurnitureGlyph(f, size: 48),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(FurnitureGlyph), findsNWidgets(Furniture.values.length));
  });

  // Meaningful graphics need 3:1 against what is behind them: every room
  // tint, also under the floor pattern and the "taken" shade.
  for (final (name, colors) in [
    ('light', GameColors.light),
    ('dark', GameColors.dark),
  ]) {
    test('$name furniture ink keeps 3:1 on every floor', () {
      for (final tint in colors.roomTints) {
        final floors = [
          tint,
          Color.alphaBlend(colors.pattern, tint),
          Color.alphaBlend(colors.takenShade, tint),
          Color.alphaBlend(
            colors.takenShade,
            Color.alphaBlend(colors.pattern, tint),
          ),
        ];
        for (final floor in floors) {
          for (final ink in [colors.blockedIcon, colors.seat]) {
            expect(
              _contrast(ink, floor),
              greaterThanOrEqualTo(3),
              reason: 'ink $ink on $floor',
            );
          }
        }
      }
    });
  }

  test('one tint per room, even in an 8×8 house', () {
    for (final colors in [GameColors.light, GameColors.dark]) {
      expect(colors.roomTints.toSet(), hasLength(greaterThanOrEqualTo(7)));
    }
  });
}
