import 'package:material_ui/material_ui.dart';

/// Design tokens. Picked with the UI UX Pro Max skill:
/// - light: "E-Ink / Paper" style (paper #FDFBF7, ink #1A1A1A, pencil #4A4A4A);
/// - dark: "Card & Board Game" palette (felt green + gold on #0F172A).
/// Dark primary is lightened to #4ADE80 so green text keeps 4.5:1 contrast.
/// Widgets read colors from [Theme] / [GameColors], never raw hex.
class AppTheme {
  /// Bundled font families (see pubspec.yaml, assets/fonts/).
  static const headingFont = 'PlayfairDisplay';
  static const bodyFont = 'SourceSerif4';

  static const _green = Color(0xFF15803D);
  static const _gold = Color(0xFFD97706);

  static ThemeData light() => _build(
    brightness: Brightness.light,
    scheme: const ColorScheme.light(
      primary: _green,
      onPrimary: Colors.white,
      secondary: _gold,
      onSecondary: Color(0xFF0F172A),
      error: Color(0xFFDC2626),
      onError: Colors.white,
      surface: Color(0xFFFDFBF7),
      onSurface: Color(0xFF1A1A1A),
      onSurfaceVariant: Color(0xFF4A4A4A),
      surfaceContainerLow: Color(0xFFFFFFFF),
      surfaceContainer: Color(0xFFF5F2EA),
      surfaceContainerHigh: Color(0xFFEDE9DF),
      outline: Color(0xFF8A8478),
      outlineVariant: Color(0xFFE0E0E0),
    ),
    game: GameColors.light,
  );

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    scheme: const ColorScheme.dark(
      primary: Color(0xFF4ADE80),
      onPrimary: Color(0xFF0F172A),
      secondary: _gold,
      onSecondary: Color(0xFF0F172A),
      error: Color(0xFFF87171),
      onError: Color(0xFF0F172A),
      surface: Color(0xFF0F172A),
      onSurface: Colors.white,
      onSurfaceVariant: Color(0xFF94A3B8),
      surfaceContainerLow: Color(0xFF192134),
      surfaceContainer: Color(0xFF1E293B),
      surfaceContainerHigh: Color(0xFF243044),
      outline: Color(0xFF64748B),
      outlineVariant: Color(0x14FFFFFF),
    ),
    game: GameColors.dark,
  );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required GameColors game,
  }) {
    final base = ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: bodyFont,
    );
    final text = base.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    TextStyle? heading(TextStyle? s, FontWeight w) =>
        s?.copyWith(fontFamily: headingFont, fontWeight: w);
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      extensions: [game],
      // "Minimalist Monochrome Editorial" pairing (UI UX Pro Max):
      // Playfair Display for headings, Source Serif 4 for everything else.
      textTheme: text.copyWith(
        displayLarge: heading(text.displayLarge, FontWeight.w800),
        displayMedium: heading(text.displayMedium, FontWeight.w800),
        displaySmall: heading(
          text.displaySmall,
          FontWeight.w800,
        )?.copyWith(letterSpacing: -0.5),
        headlineLarge: heading(text.headlineLarge, FontWeight.w700),
        headlineMedium: heading(text.headlineMedium, FontWeight.w700),
        headlineSmall: heading(text.headlineSmall, FontWeight.w700),
        titleLarge: heading(text.titleLarge, FontWeight.w700),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        labelMedium: text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        labelSmall: text.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        bodyLarge: text.bodyLarge?.copyWith(height: 1.5),
        bodyMedium: text.bodyMedium?.copyWith(height: 1.5),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Colors specific to the board, per brightness.
@immutable
class GameColors extends ThemeExtension<GameColors> {
  const GameColors({
    required this.roomTints,
    required this.wall,
    required this.gridLine,
    required this.pattern,
    required this.seat,
    required this.blockedIcon,
    required this.takenShade,
    required this.suspects,
  });

  /// One tint per room index (rooms are also told apart by thick walls and
  /// the legend, never by color alone).
  final List<Color> roomTints;
  final Color wall;
  final Color gridLine;

  /// Faint floor pattern ink (planks, tiles, carpet, grass, stone).
  final Color pattern;

  /// Chairs: warm like rugs, because people can stand on them.
  final Color seat;
  final Color blockedIcon;

  /// Overlay on cells whose row or column already has someone.
  final Color takenShade;

  /// Avatar fills by roster index; white initials reach 4.5:1 on all of them.
  final List<Color> suspects;

  static const _suspects = [
    Color(0xFFB91C1C),
    Color(0xFF1D4ED8),
    Color(0xFF7E22CE),
    Color(0xFF0F766E),
    Color(0xFFBE185D),
    Color(0xFF4D7C0F),
    Color(0xFF9A3412),
    Color(0xFF334155),
  ];

  static const light = GameColors(
    roomTints: [
      Color(0xFFF3E8D2),
      Color(0xFFDDEBDD),
      Color(0xFFDCE6F2),
      Color(0xFFF2DEDC),
      Color(0xFFE8E0F0),
      Color(0xFFE6E6DA),
    ],
    wall: Color(0xFF1A1A1A),
    gridLine: Color(0x331A1A1A),
    pattern: Color(0x1F1A1A1A),
    seat: Color(0xFF92400E),
    blockedIcon: Color(0xFF4A4A4A),
    takenShade: Color(0x141A1A1A),
    suspects: _suspects,
  );

  static const dark = GameColors(
    roomTints: [
      Color(0xFF2A2A22),
      Color(0xFF14301F),
      Color(0xFF1A2740),
      Color(0xFF3A1F24),
      Color(0xFF2B2140),
      Color(0xFF262B30),
    ],
    wall: Color(0xFFE2E8F0),
    gridLine: Color(0x33FFFFFF),
    pattern: Color(0x1FFFFFFF),
    seat: Color(0xFFFBBF24),
    blockedIcon: Color(0xFFCBD5E1),
    takenShade: Color(0x1FFFFFFF),
    suspects: _suspects,
  );

  @override
  GameColors copyWith() => this;

  @override
  GameColors lerp(GameColors? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}

extension GameColorsX on BuildContext {
  GameColors get game => Theme.of(this).extension<GameColors>()!;
}

/// Shared motion tokens (UI UX Pro Max: one rhythm for the whole app,
/// decelerate on arrival, exits shorter than entries). Every animation goes
/// through [Motion.of], which returns zero when the system asks for reduced
/// motion, so the final state is always shown at once.
abstract final class Motion {
  /// A suspect dropping into a square.
  static const place = Duration(milliseconds: 220);

  /// Board shake after a wrong check: short, so it never feels like a block.
  static const shake = Duration(milliseconds: 360);

  /// Final reveal: the other rooms dim and the victim's room is outlined.
  static const reveal = Duration(milliseconds: 700);

  /// How long the reveal stays on screen before the case-closed dialog.
  static const revealHold = Duration(milliseconds: 600);

  static const enter = Curves.easeOutCubic;

  /// Slight overshoot for things that "land".
  static const land = Curves.easeOutBack;

  /// [d], or zero when animations are disabled (reduced motion).
  static Duration of(BuildContext context, Duration d) =>
      MediaQuery.of(context).disableAnimations ? Duration.zero : d;
}
