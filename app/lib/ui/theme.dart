import 'package:flutter/material.dart';

/// Final palette is Brick & Sage. Others kept for comparison: --dart-define=PALETTE=safety|green|toran.
const palette = String.fromEnvironment('PALETTE', defaultValue: 'brick');

Color _pick(int safety, int green, int toran, int brick) => Color(switch (palette) {
      'green' => green,
      'toran' => toran,
      'brick' => brick,
      _ => safety,
    });

/// BAAKI BUILD colour roles. No pure black anywhere: text is a dark grey.
abstract final class Brand {
  /// Buttons and filled brand surfaces.
  static final primary = _pick(0xFFC2410C, 0xFF15803D, 0xFFF2A900, 0xFFB23A1E);

  /// Text and icons on [primary].
  static final onPrimary = _pick(0xFFFFFFFF, 0xFFFFFFFF, 0xFF1F2933, 0xFFFFFFFF);

  /// Icon tint on light backgrounds.
  static final accent = _pick(0xFFC2410C, 0xFF15803D, 0xFF1E6B3A, 0xFFB23A1E);

  /// Light tint behind accent icons and info boxes.
  static final soft = _pick(0xFFFFEDE3, 0xFFE3F4E8, 0xFFFFF4CF, 0xFFFBE9E3);

  /// Coloured band behind the hero, login panel and profile card.
  static final header = _pick(0xFF334155, 0xFF14532D, 0xFF1E6B3A, 0xFF3D5A47);
  static final headerSoft = _pick(0xFF475569, 0xFF1D6B3D, 0xFF2A7D48, 0xFF4C6B56);

  /// Icons that must stand out on [header].
  static final highlight = _pick(0xFFFB923C, 0xFFF2B705, 0xFFF2A900, 0xFFE0B23C);

  static final sand = _pick(0xFFF4F5F7, 0xFFF5F7F2, 0xFFFAF8F1, 0xFFFAF6F0);
  static final line = _pick(0xFFE2E5EA, 0xFFDFE6DC, 0xFFE9E3D3, 0xFFE8DFD5);
  static final ink = _pick(0xFF1F2933, 0xFF1F2A24, 0xFF1F2933, 0xFF2B2622);
  static final muted = _pick(0xFF64707D, 0xFF5F6B64, 0xFF6B6A5F, 0xFF6E655D);

  static const green = Color(0xFF2B8A3E);
  static const greenSoft = Color(0xFFE6F4EA);

  static const font = 'PlusJakartaSans';
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Brand.primary,
    primary: Brand.primary,
    onPrimary: Brand.onPrimary,
    secondary: Brand.ink,
    onSecondary: Colors.white,
    surface: Colors.white,
    onSurface: Brand.ink,
  ).copyWith(
    outline: const Color(0xFFB9B3A9),
    outlineVariant: Brand.line,
    onSurfaceVariant: Brand.muted,
    surfaceContainerHighest: const Color(0xFFF0ECE5),
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: Brand.font,
    scaffoldBackgroundColor: Brand.sand,
    visualDensity: VisualDensity.standard,
  );

  final radius12 = BorderRadius.circular(12);
  OutlineInputBorder border(Color c, [double w = 1]) =>
      OutlineInputBorder(borderRadius: radius12, borderSide: BorderSide(color: c, width: w));

  return base.copyWith(
    textTheme: base.textTheme
        .apply(bodyColor: Brand.ink, displayColor: Brand.ink)
        .copyWith(
          headlineLarge: base.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800, height: 1.15),
          headlineMedium: base.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.2),
          headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          titleSmall: base.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
    appBarTheme: AppBarTheme(
      backgroundColor: Brand.sand,
      foregroundColor: Brand.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle:
          TextStyle(fontFamily: Brand.font, fontSize: 22, fontWeight: FontWeight.w800, color: Brand.ink),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Brand.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border(Brand.line),
      enabledBorder: border(Brand.line),
      focusedBorder: border(Brand.accent, 2),
      errorBorder: border(scheme.error),
      focusedErrorBorder: border(scheme.error, 2),
      helperStyle: TextStyle(color: Brand.muted),
      helperMaxLines: 3,
      errorMaxLines: 3,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: radius12),
        textStyle: const TextStyle(fontFamily: Brand.font, fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        foregroundColor: Brand.ink,
        side: BorderSide(color: Brand.line, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: radius12),
        textStyle: const TextStyle(fontFamily: Brand.font, fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(fontFamily: Brand.font, fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: Brand.header,
      showCheckmark: false,
      side: BorderSide(color: Brand.line),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      labelStyle: WidgetStateTextStyle.resolveWith((states) => TextStyle(
            fontFamily: Brand.font,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected) ? Colors.white : Brand.ink,
          )),
      iconTheme: const IconThemeData(size: 18),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Brand.soft,
      surfaceTintColor: Colors.transparent,
      height: 68,
      labelTextStyle: WidgetStateTextStyle.resolveWith((states) => TextStyle(
            fontFamily: Brand.font,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
            color: states.contains(WidgetState.selected) ? Brand.accent : Brand.muted,
          )),
      iconTheme: WidgetStateProperty.resolveWith((states) =>
          IconThemeData(color: states.contains(WidgetState.selected) ? Brand.accent : Brand.muted)),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Brand.soft,
      selectedIconTheme: IconThemeData(color: Brand.accent),
      unselectedIconTheme: IconThemeData(color: Brand.muted),
      selectedLabelTextStyle:
          TextStyle(fontFamily: Brand.font, fontWeight: FontWeight.w800, color: Brand.accent, fontSize: 14),
      unselectedLabelTextStyle:
          TextStyle(fontFamily: Brand.font, fontWeight: FontWeight.w600, color: Brand.muted, fontSize: 14),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Brand.primary,
      foregroundColor: Brand.onPrimary,
      extendedTextStyle: const TextStyle(fontFamily: Brand.font, fontWeight: FontWeight.w700, fontSize: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerTheme: DividerThemeData(color: Brand.line, space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Brand.ink,
      shape: RoundedRectangleBorder(borderRadius: radius12),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: radius12),
    ),
  );
}
