import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../core/app_state.dart';
import '../core/strings.dart';
import '../game/game_controller.dart';
import '../game/generator.dart';
import '../game/model.dart';
import '../theme/app_theme.dart';
import '../widgets/board_view.dart';
import '../widgets/suspect_avatar.dart';
import 'how_to_play_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.appState,
    required this.puzzle,
    this.daily = false,
  });

  final AppState appState;
  final Puzzle puzzle;
  final bool daily;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController game = GameController(
    widget.puzzle,
    daily: widget.daily,
  );

  Strings get s => widget.appState.s;

  @override
  void dispose() {
    game.dispose();
    super.dispose();
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _onTap(int cell) {
    switch (game.tap(cell)) {
      case TapResult.blocked:
        _snack(s.blocked);
      case TapResult.locked || TapResult.ok:
        break;
    }
  }

  Future<void> _check() async {
    switch (game.check()) {
      case CheckResult.incomplete:
        _snack(game.conflicts.isNotEmpty ? s.conflict : s.incomplete);
      case CheckResult.wrong:
        HapticFeedback.heavyImpact();
        _snack(game.conflicts.isNotEmpty ? s.conflict : s.wrong);
      case CheckResult.correct:
        HapticFeedback.mediumImpact();
        await _accuse();
    }
  }

  Future<void> _accuse() async {
    final p = widget.puzzle;
    while (game.phase == Phase.accusing) {
      if (!mounted) return;
      final pick = await showModalBottomSheet<int>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text(
                s.accuseTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(s.accuseBody),
              const SizedBox(height: 12),
              for (var i = 0; i < p.people; i++)
                if (i != p.victim)
                  ListTile(
                    minTileHeight: 56,
                    leading: SuspectAvatar(rosterIndex: p.cast[i], size: 40),
                    title: Text(p.name(i)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pop(context, i),
                  ),
            ],
          ),
        ),
      );
      if (pick == null || !mounted) return; // closed: can reopen with Check
      if (game.accuse(pick)) {
        HapticFeedback.mediumImpact();
        widget.appState.recordSolved(
          p,
          game.watch.elapsed,
          daily: widget.daily,
        );
        await _showSolved();
      } else {
        HapticFeedback.heavyImpact();
        _snack(s.wrongAccusation);
      }
    }
  }

  Future<void> _showSolved() async {
    final p = widget.puzzle;
    final room = p.board.rooms[p.board.roomOf[p.solution[p.victim]]];
    final again = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.verified,
          color: Theme.of(context).colorScheme.primary,
          size: 40,
        ),
        title: Text(s.solvedTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.solvedBody(p.name(p.culprit), p.name(p.victim), s.inRoom(room)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _StatRow(label: s.time, value: formatDuration(game.watch.elapsed)),
            _StatRow(label: s.hintsUsed, value: '${game.hints}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.backHome),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.anotherCase),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (again == true) {
      final next = generatePuzzle(
        level: p.level,
        seed: Random().nextInt(99999) + 1,
        variant: p.board.variant,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => GameScreen(appState: widget.appState, puzzle: next),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.puzzle;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.daily ? s.dailyCase : s.caseTitle(p.seed)),
              Text(
                '${s.levelName(p.level)} · ${p.board.size}×${p.board.size}'
                '${p.board.variant == Variant.noTouch ? ' · ${s.noTouchTitle}' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            Center(child: _Clock(watch: game.watch)),
            IconButton(
              tooltip: s.howToPlay,
              icon: const Icon(Icons.help_outline),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HowToPlayScreen(strings: s)),
              ),
            ),
            PopupMenuButton<void>(
              itemBuilder: (_) => [
                PopupMenuItem(onTap: game.restart, child: Text(s.restart)),
              ],
            ),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  _Briefing(puzzle: p, strings: s),
                  const SizedBox(height: 16),
                  Center(
                    child: BoardView(
                      controller: game,
                      strings: s,
                      onTap: _onTap,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _Inspector(game: game, strings: s),
                  const SizedBox(height: 8),
                  _RoomLegend(board: p.board, strings: s),
                  const SizedBox(height: 20),
                  _SectionTitle(s.suspects),
                  _SuspectTray(game: game, strings: s),
                  const SizedBox(height: 20),
                  _SectionTitle(s.clues),
                  for (var i = 0; i < p.clues.length; i++)
                    _ClueTile(
                      text: s.clue(p.clues[i], p),
                      rosterIndex: p.cast[p.clues[i].subject],
                      done: game.doneClues.contains(i),
                      onTap: () => game.toggleClue(i),
                    ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: _ActionBar(
          strings: s,
          game: game,
          onCheck: _check,
          onHint: () {
            final who = game.hint();
            if (who != null) HapticFeedback.selectionClick();
          },
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Semantics(
      header: true,
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    ),
  );
}

class _Briefing extends StatelessWidget {
  const _Briefing({required this.puzzle, required this.strings});
  final Puzzle puzzle;
  final Strings strings;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SuspectAvatar(
            rosterIndex: puzzle.cast[puzzle.victim],
            size: 44,
            isVictim: true,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(strings.briefing(puzzle.name(puzzle.victim)))),
        ],
      ),
    ),
  );
}

/// What the last tapped square is, or what to do next.
class _Inspector extends StatelessWidget {
  const _Inspector({required this.game, required this.strings});
  final GameController game;
  final Strings strings;

  @override
  Widget build(BuildContext context) {
    final cell = game.focusedCell;
    final b = game.board;
    final style = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    String text;
    if (cell == null) {
      text = strings.selectHint;
    } else {
      final f = b.furniture[cell];
      text = [
        '${Strings.colLetter(b.col(cell))}${b.row(cell) + 1}',
        strings.roomName(b.rooms[b.roomOf[cell]]),
        if (f != Furniture.none) strings.furnitureName(f),
      ].join(' · ');
    }
    return Semantics(
      liveRegion: true,
      child: Text(text, textAlign: TextAlign.center, style: style),
    );
  }
}

class _RoomLegend extends StatelessWidget {
  const _RoomLegend({required this.board, required this.strings});
  final Board board;
  final Strings strings;

  @override
  Widget build(BuildContext context) {
    final game = context.game;
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        for (var r = 0; r < board.rooms.length; r++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: game.roomTints[r % game.roomTints.length],
                  border: Border.all(color: scheme.outline),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                strings.roomName(board.rooms[r]),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
      ],
    );
  }
}

class _SuspectTray extends StatelessWidget {
  const _SuspectTray({required this.game, required this.strings});
  final GameController game;
  final Strings strings;

  @override
  Widget build(BuildContext context) {
    final p = game.puzzle;
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < p.people; i++)
          Semantics(
            selected: game.selected == i,
            button: true,
            label: [
              p.name(i),
              if (i == p.victim) strings.victimLabel,
              if (game.placement[i] != null) strings.placed,
            ].join(', '),
            excludeSemantics: true,
            child: Material(
              color: game.selected == i
                  ? scheme.secondary.withValues(alpha: 0.18)
                  : scheme.surfaceContainerLow,
              shape: StadiumBorder(
                side: BorderSide(
                  color: game.selected == i
                      ? scheme.secondary
                      : scheme.outlineVariant,
                  width: game.selected == i ? 2 : 1,
                ),
              ),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => game.select(i),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SuspectAvatar(
                          rosterIndex: p.cast[i],
                          size: 34,
                          isVictim: i == p.victim,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          p.name(i),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        if (game.placement[i] != null) ...[
                          const SizedBox(width: 6),
                          Icon(
                            game.locked.contains(i) ? Icons.lock : Icons.check,
                            size: 16,
                            color: scheme.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ClueTile extends StatelessWidget {
  const _ClueTile({
    required this.text,
    required this.rosterIndex,
    required this.done,
    required this.onTap,
  });
  final String text;
  final int rosterIndex;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      checked: done,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                Opacity(
                  opacity: done ? 0.4 : 1,
                  child: SuspectAvatar(rosterIndex: rosterIndex, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      decoration: done ? TextDecoration.lineThrough : null,
                      color: done ? scheme.onSurfaceVariant : scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.strings,
    required this.game,
    required this.onCheck,
    required this.onHint,
  });
  final Strings strings;
  final GameController game;
  final VoidCallback onCheck;
  final VoidCallback onHint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placing = game.phase == Phase.placing;
    return Material(
      color: scheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Row(
            children: [
              _BarButton(
                icon: Icons.undo,
                label: strings.undo,
                onTap: game.canUndo ? game.undo : null,
              ),
              _BarButton(
                icon: Icons.close,
                label: strings.crossOut,
                active: game.crossMode,
                onTap: placing ? game.toggleCrossMode : null,
              ),
              _BarButton(
                icon: Icons.lightbulb_outline,
                label: strings.hint,
                onTap: placing ? onHint : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: game.phase == Phase.solved ? null : onCheck,
                  icon: const Icon(Icons.gavel),
                  label: Text(strings.check),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = onTap == null
        ? scheme.onSurface.withValues(alpha: 0.38)
        : active
        ? scheme.onSecondary
        : scheme.onSurface;
    return Expanded(
      child: Semantics(
        toggled: active ? true : null,
        child: Material(
          color: active ? scheme.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: color),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
  );
}

class _Clock extends StatefulWidget {
  const _Clock({required this.watch});
  final Stopwatch watch;

  @override
  State<_Clock> createState() => _ClockState();
}

class _ClockState extends State<_Clock> {
  late final Timer _timer = Timer.periodic(
    const Duration(seconds: 1),
    (_) => setState(() {}),
  );

  @override
  void initState() {
    super.initState();
    _timer;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Text(
      formatDuration(widget.watch.elapsed),
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
    ),
  );
}
