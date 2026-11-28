import 'package:share_plus/share_plus.dart';

import '../game/model.dart';
import 'app_info.dart';
import 'app_state.dart';
import 'strings.dart';

/// Sends text through the platform share sheet. Screens take one of these
/// so tests can pass a fake.
typedef ShareText = Future<void> Function(String text);

Future<void> shareWithPlatform(String text) =>
    SharePlus.instance.share(ShareParams(text: text));

/// A spoiler-free summary of a solved case: which case, level, time and
/// hints. Never names, squares or the culprit.
String resultShareText(
  Strings s,
  Puzzle p, {
  required bool daily,
  required Duration elapsed,
  required int hints,
}) {
  final which = daily
      ? '${s.dailyCase}, ${s.shortDate(AppState.dayOf(p.seed))}'
      : s.caseTitle(p.seed);
  final details = [
    '${s.levelName(p.level)} ${p.board.size}×${p.board.size}',
    if (p.board.variant == Variant.noTouch) s.noTouchShort,
    formatDuration(elapsed),
    s.hintCount(hints),
  ].join(' · ');
  return 'Pesquisa — $which\n$details\n${s.shareInvite}\n$shareLink';
}
