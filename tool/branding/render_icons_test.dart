// Renders the app icon PNGs into branding/png/ (1024×1024).
// Run: flutter test tool/branding/render_icons_test.dart
// Not part of CI (lives outside test/).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:coartada/widgets/app_icon.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _save(String name, void Function(Canvas) paint) async {
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec, const Rect.fromLTWH(0, 0, 1024, 1024));
  paint(canvas);
  final image = await rec.endRecording().toImage(1024, 1024);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File('branding/png/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('render icons', (tester) async {
    await tester.runAsync(() async {
      // Full icon (iOS, legacy Android): art on green, no transparency.
      await _save('icon', (c) {
        c.drawRect(
          const Rect.fromLTWH(0, 0, 1024, 1024),
          Paint()..color = iconGreen,
        );
        // Slightly smaller so the handle clears iOS's rounded corners.
        paintAppIconArt(c, scale: 0.9);
      });
      // Adaptive icon layers: art scaled into the 66% safe zone.
      await _save('icon_foreground', (c) => paintAppIconArt(c, scale: 0.62));
      await _save('icon_background', (c) {
        c.drawRect(
          const Rect.fromLTWH(0, 0, 1024, 1024),
          Paint()..color = iconGreen,
        );
      });
      await _save(
        'icon_monochrome',
        (c) => paintAppIconArt(c, mono: true, scale: 0.62),
      );
    });
  });
}
