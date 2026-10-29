import 'package:flutter/material.dart';

/// BAAKI BUILD palette: site-safety orange on warm sand, charcoal text.
abstract final class Brand {
  static const orange = Color(0xFFE8590C);
  static const orangeSoft = Color(0xFFFFEDE2);
  static const charcoal = Color(0xFF1C1F24);
  static const charcoalSoft = Color(0xFF2A2E35);
  static const sand = Color(0xFFF7F4EF);
  static const line = Color(0xFFE6E0D6);
  static const muted = Color(0xFF6B6F76);
  static const green = Color(0xFF2B8A3E);
  static const greenSoft = Color(0xFFE6F4EA);

  static const font = 'PlusJakartaSans';
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Brand.orange,
    primary: Brand.orange,
    onPrimary: Colors.white,
    secondary: Brand.charcoal,
    onSecondary: Colors.white,
    surface: Colors.white,
    onSurface: Brand.charcoal,
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
        .apply(bodyColor: Brand.charcoal, displayColor: Brand.charcoal)
        .copyWith(
          headlineLarge: base.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800, height: 1.15),
          headlineMedium: base.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.2),
          headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          titleSmall: base.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Brand.sand,
      foregroundColor: Brand.charcoal,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle:
          TextStyle(fontFamily: Brand.font, fontSize: 22, fontWeight: FontWeight.w800, color: Brand.charcoal),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Brand.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border(Brand.line),
      enabledBorder: border(Brand.line),
      focusedBorder: border(Brand.orange, 2),
      errorBorder: border(scheme.error),
      focusedErrorBorder: border(scheme.error, 2),
      helperStyle: const TextStyle(color: Brand.muted),
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
        foregroundColor: Brand.charcoal,
        side: const BorderSide(color: Brand.line, width: 1.5),
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
      selectedColor: Brand.charcoal,
      showCheckmark: false,
      side: const BorderSide(color: Brand.line),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      labelStyle: WidgetStateTextStyle.resolveWith((states) => TextStyle(
            fontFamily: Brand.font,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected) ? Colors.white : Brand.charcoal,
          )),
      iconTheme: const IconThemeData(size: 18),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Brand.orangeSoft,
      surfaceTintColor: Colors.transparent,
      height: 68,
      labelTextStyle: WidgetStateTextStyle.resolveWith((states) => TextStyle(
            fontFamily: Brand.font,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
            color: states.contains(WidgetState.selected) ? Brand.orange : Brand.muted,
          )),
      iconTheme: WidgetStateProperty.resolveWith((states) =>
          IconThemeData(color: states.contains(WidgetState.selected) ? Brand.orange : Brand.muted)),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Brand.orangeSoft,
      selectedIconTheme: IconThemeData(color: Brand.orange),
      unselectedIconTheme: IconThemeData(color: Brand.muted),
      selectedLabelTextStyle:
          TextStyle(fontFamily: Brand.font, fontWeight: FontWeight.w800, color: Brand.orange, fontSize: 14),
      unselectedLabelTextStyle:
          TextStyle(fontFamily: Brand.font, fontWeight: FontWeight.w600, color: Brand.muted, fontSize: 14),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Brand.orange,
      foregroundColor: Colors.white,
      extendedTextStyle: const TextStyle(fontFamily: Brand.font, fontWeight: FontWeight.w700, fontSize: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerTheme: const DividerThemeData(color: Brand.line, space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Brand.charcoal,
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
