import 'package:coartada/game/model.dart';
import 'package:coartada/theme/app_theme.dart';
import 'package:coartada/widgets/suspect_avatar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('all eight portraits paint, victim and ring included', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Wrap(
          children: [
            for (var i = 0; i < roster.length; i++)
              SuspectAvatar(
                rosterIndex: i,
                size: minAvatarSize,
                isVictim: i == 0,
                ring: i == 1 ? Colors.red : null,
              ),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(SuspectAvatar), findsNWidgets(roster.length));
  });

  test('the chest initial is at least 12px at the smallest size', () {
    expect(minAvatarSize * 0.36, greaterThanOrEqualTo(12));
  });

  test('white initials keep 4.5:1 on every shirt', () {
    for (final c in GameColors.light.suspects) {
      final shirt = shirtColor(c);
      final l = shirt.computeLuminance();
      expect((1.05) / (l + 0.05), greaterThanOrEqualTo(4.5), reason: '$c');
    }
  });
}
