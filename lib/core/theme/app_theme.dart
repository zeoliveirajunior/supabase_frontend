import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta clinica: teal limpo sobre superficies claras, texto em azul-petroleo.
abstract final class AppColors {
  static const primary = Color(0xFF0E8C86);
  static const primaryDark = Color(0xFF085F5B);
  static const primaryDeep = Color(0xFF053E3C);
  static const accent = Color(0xFF2ED3C6);
  static const mint = Color(0xFFE3F6F4);
  static const ink = Color(0xFF0F2A33);
  static const muted = Color(0xFF5B7078);
  static const line = Color(0xFFD9E5E7);
  static const surface = Color(0xFFF4F8F9);
  static const white = Color(0xFFFFFFFF);
  static const danger = Color(0xFFD64545);
  static const success = Color(0xFF2E9E6B);
  static const warning = Color(0xFFE9A23B);

  /// Marca Clinify: amarelo e dourado (logomarca e destaques).
  static const gold = Color(0xFFD9A21B);
  static const goldDark = Color(0xFFB8860B);
  static const goldLight = Color(0xFFFFD84D);
  static const goldPale = Color(0xFFFFF6D6);
  static const goldDeep = Color(0xFF8C6508);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDeep, primaryDark, primary],
  );
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
  static const double xl = 28;
}

abstract final class AppTheme {
  /// [useGoogleFonts] = false nos testes (sem rede, sem fonte empacotada).
  static ThemeData light({bool useGoogleFonts = true}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      secondary: AppColors.accent,
      onSecondary: AppColors.ink,
      surface: AppColors.white,
      onSurface: AppColors.ink,
      error: AppColors.danger,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.surface,
    );

    final textTheme =
        (useGoogleFonts
                ? GoogleFonts.manropeTextTheme(base.textTheme)
                : base.textTheme)
            .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: color, width: width),
        );

    return base.copyWith(
      textTheme: textTheme,
      dividerColor: AppColors.line,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 18,
        ),
        border: border(AppColors.line),
        enabledBorder: border(AppColors.line),
        focusedBorder: border(AppColors.primary, 1.6),
        errorBorder: border(AppColors.danger),
        focusedErrorBorder: border(AppColors.danger, 1.6),
        labelStyle: const TextStyle(color: AppColors.muted),
        hintStyle: const TextStyle(color: Color(0xFF9AAAB0)),
        prefixIconColor: AppColors.muted,
        suffixIconColor: AppColors.muted,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 52),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          disabledForegroundColor: AppColors.white,
          elevation: 0,
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          foregroundColor: AppColors.primaryDark,
          side: const BorderSide(color: AppColors.line),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          textStyle: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.mint,
        selectedIconTheme: const IconThemeData(color: AppColors.primaryDark),
        unselectedIconTheme: const IconThemeData(color: AppColors.muted),
        selectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          color: AppColors.muted,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.mint,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.mint,
        side: BorderSide.none,
        labelStyle: textTheme.labelLarge?.copyWith(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
    );
  }
}
