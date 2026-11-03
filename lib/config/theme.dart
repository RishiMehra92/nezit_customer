import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_local/config/constant.dart';

class AppTheme {
  /// App main color
  static const Color primaryColor = AppConstant.myprimaryColor;
  static Color primaryVariant = primaryColor.withValues(alpha: 0.8);

  /// Eye-Comfort Font Colors (deep charcoal for light, soft warm white for dark)
  static const Color lightFontColor = Color(0xFF1E293B); // Slate-800: calm, deep charcoal (no blinding glare)
  static const Color darkFontColor = Color(0xFFE2E8F0); // Slate-200: soft, warm white (no halation/blur)

  /// Eye-Comfort Secondary / Subtitle Colors (solid, never dim or washed out)
  static const Color lightSubtitleColor = Color(0xFF64748B); // Slate-500: easy on the eyes, clearly legible
  static const Color darkSubtitleColor = Color(0xFFA8B4C4); // Slate-350 (~72% luminance): crisp, never ghostly/dim

  /// Light Theme Colors
  static const Color mainLightBackgroundColor = Color(0xFFF8FAFC); // Slate-50 soft canvas
  static Color mainLightBackgroundColor2 = const Color(0xFFF1F5F9); // Slate-100
  static const Color mainLightContainerBgColor = Colors.white; // Clean crisp cards on soft canvas
  static const Color lightSecondary = Color(0xFFE2E8F0); // Slate-200
  static const Color lightTertiary = Color(0xFF1E293B); // Slate-800 primary text
  static Color lightProductCardColor = Colors.white;
  static const Color lightSubCategoryCardColor = Color(0xFFF0F9FF); // Soft ice blue
  static Color lightOutline = const Color(0xFFE2E8F0); // Slate-200 soft border
  static Color lightOutlineVariant = const Color(0xFFCBD5E1); // Slate-300 divider/outline
  static const Color pointsEarnedColor = Color(0xFFE8F5E9);

  /// Dark Theme Colors — 4-level surface elevation system
  static const Color mainDarkBackgroundColor = Color(0xFF0D0D0D); // page bg
  static const Color mainDarkContainerBgColor = Color(0xFF1A1A1A); // cards (L1)
  static const Color darkSubCategoryCardColor = Color(0xFF242424); // elevated cards (L2)
  static const Color darkExtraCardColor = Color(0xFF2E2E2E); // chips / inputs (L3)
  static const Color darkTertiary = Color(0xFFE6EBF2); // primary text (calm, warm white)
  static Color darkProductCardColor = const Color(0xFF1A1A1A);
  static Color darkOutline = const Color(0x1FFFFFFF); // 12% white border
  static Color darkOutlineVariant = const Color(0x14FFFFFF); // 8% white divider

  /// Typography
  static const String fontFamily = 'Figtree';

  /// Messages Color
  static const Color errorColor = Colors.red;
  static const Color successColor = Colors.green;
  static const Color warningColor = Colors.orangeAccent;

  /// Rating Star color
  static const Color ratingStarColor = Color(0xFFEEAB18);
  static const IconData ratingStarIcon = TablerIcons.star;
  static const IconData ratingStarIconFilled = TablerIcons.star_filled;
  static const IconData ratingStarIconHalfFilled = TablerIcons.star_half_filled;

  /// Delivery Time Widget Color
  static const Color deliveryTimeWidgetColor = Color(0xFFC2FBFF);

  /// Discount Card Color
  static const Color discountCardColor = Color(0xFF53ad67);

  /// Coupon Card Colors
  static Color couponShadeColor = Colors.blue.shade50;
  static Color couponCollectBgColor = primaryColor.withValues(alpha: 0.1);

  /// Helper: Eye-comfortable primary text color
  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkTertiary : lightTertiary;
  }

  /// Helper: Eye-comfortable secondary text color (never dim/ghosted in dark mode)
  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkSubtitleColor : lightSubtitleColor;
  }

  /// Helper: Eye-comfortable card / surface container
  static Color surfaceCard(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? mainDarkContainerBgColor : Colors.white;
  }

  /// Resolves a [ThemeMode] to a concrete [ThemeData].
  /// [brightness] is only used when [mode] is [ThemeMode.system].
  static ThemeData resolveFromMode(ThemeMode mode, Brightness brightness) {
    switch (mode) {
      case ThemeMode.dark:
        return darkTheme;
      case ThemeMode.system:
        return brightness == Brightness.dark ? darkTheme : lightTheme;
      case ThemeMode.light:
        return lightTheme;
    }
  }

  /// Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: mainLightBackgroundColor,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      surface: mainLightBackgroundColor,
      surfaceContainer: mainLightContainerBgColor,
      surfaceContainerHighest: mainLightBackgroundColor2,
      primary: mainLightContainerBgColor,
      onPrimary: lightProductCardColor,
      onSecondary: lightSubCategoryCardColor,
      secondary: lightSecondary,
      tertiary: lightTertiary,
      outline: lightOutline,
      outlineVariant: lightOutlineVariant,
      onSecondaryContainer: lightSubtitleColor,
      onSurfaceVariant: lightSubtitleColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: lightTertiary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
      ),
      margin: EdgeInsets.zero,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE2E8F0),
      thickness: 0.8,
      space: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: Colors.white,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: Colors.white,
      headerBackgroundColor: primaryColor,
      headerForegroundColor: Colors.white,
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryColor;
        return null;
      }),
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        if (states.contains(WidgetState.disabled)) return Colors.grey.shade400;
        return lightTertiary;
      }),
      todayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return primaryColor;
      }),
      todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryColor;
        return null;
      }),
    ),
    fontFamily: AppTheme.fontFamily,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontFamily: fontFamily, color: lightTertiary, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(fontFamily: fontFamily, color: lightTertiary, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(fontFamily: fontFamily, color: lightTertiary, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontFamily: fontFamily, color: lightTertiary, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontFamily: fontFamily, color: lightTertiary, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(fontFamily: fontFamily, color: lightTertiary, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(fontFamily: fontFamily, color: lightTertiary, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(fontFamily: fontFamily, color: lightTertiary, fontWeight: FontWeight.w400),
      bodySmall: TextStyle(fontFamily: fontFamily, color: lightSubtitleColor, fontWeight: FontWeight.w400),
      labelLarge: TextStyle(fontFamily: fontFamily, color: lightTertiary, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(fontFamily: fontFamily, color: lightSubtitleColor, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(fontFamily: fontFamily, color: lightSubtitleColor, fontWeight: FontWeight.w400),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(lightTertiary),
      ),
    ),
  );

  /// Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: mainDarkBackgroundColor,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.dark(
      surface: mainDarkBackgroundColor,
      surfaceContainer: mainDarkContainerBgColor,
      surfaceContainerHighest: darkSubCategoryCardColor,
      primary: mainDarkContainerBgColor,
      onPrimary: mainDarkContainerBgColor,
      onSecondary: darkSubCategoryCardColor,
      secondary: darkExtraCardColor,
      tertiary: darkTertiary,
      onSecondaryContainer: darkSubtitleColor,
      onSurfaceVariant: darkSubtitleColor,
      outline: darkOutline,
      outlineVariant: darkOutlineVariant,
      error: Colors.red,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: mainDarkBackgroundColor,
      foregroundColor: darkTertiary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF111111),
      selectedItemColor: primaryColor,
      unselectedItemColor: Color(0xFF8E9BAE),
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: mainDarkContainerBgColor,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: mainDarkContainerBgColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0x1FFFFFFF), width: 0.5),
      ),
    ),
    cardTheme: CardThemeData(
      color: mainDarkContainerBgColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0x1FFFFFFF), width: 0.5),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0x14FFFFFF),
      thickness: 0.5,
      space: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: mainDarkContainerBgColor,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x1FFFFFFF), width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x1FFFFFFF), width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 1),
      ),
      hintStyle: const TextStyle(color: Color(0xFF8E9BAE)),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      headerBackgroundColor: primaryColor,
      headerForegroundColor: Colors.white,
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryColor;
        return null;
      }),
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        if (states.contains(WidgetState.disabled)) return Colors.grey.shade600;
        return darkTertiary;
      }),
      todayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return primaryColor;
      }),
      todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryColor;
        return null;
      }),
    ),
    fontFamily: AppTheme.fontFamily,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontFamily: fontFamily, color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(fontFamily: fontFamily, color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(fontFamily: fontFamily, color: Color(0xFFF1F5F9), fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontFamily: fontFamily, color: Color(0xFFF1F5F9), fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontFamily: fontFamily, color: darkTertiary, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(fontFamily: fontFamily, color: darkTertiary, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(fontFamily: fontFamily, color: darkTertiary, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(fontFamily: fontFamily, color: darkTertiary, fontWeight: FontWeight.w400),
      bodySmall: TextStyle(fontFamily: fontFamily, color: darkSubtitleColor, fontWeight: FontWeight.w400),
      labelLarge: TextStyle(fontFamily: fontFamily, color: darkTertiary, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(fontFamily: fontFamily, color: darkSubtitleColor, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(fontFamily: fontFamily, color: darkSubtitleColor, fontWeight: FontWeight.w400),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(darkTertiary),
      ),
    ),
  );
}
