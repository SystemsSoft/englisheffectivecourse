import 'package:flutter/material.dart';

/// Cores baseadas na identidade visual da logo Effective English Course.
abstract class AppColors {
  /// Azul marinho escuro — cor principal da logo
  static const Color navyBlue = Color(0xFF1A2150);

  /// Vermelho — destaque da logo (cruz da bandeira e nome da professora)
  static const Color red = Color(0xFFC8102E);

  /// Branco — fundo e elementos claros
  static const Color white = Color(0xFFFFFFFF);

  /// Azul marinho suave — variante para containers/superfícies
  static const Color navyBlueLight = Color(0xFF2B3A7A);

  /// Vermelho suave — variante para hover/estados
  static const Color redLight = Color(0xFFE8394D);
}

abstract class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme(
          brightness: Brightness.light,

          // Primária — azul marinho
          primary: AppColors.navyBlue,
          onPrimary: AppColors.white,
          primaryContainer: const Color(0xFFDDE3FF),
          onPrimaryContainer: AppColors.navyBlue,

          // Secundária — vermelho
          secondary: AppColors.red,
          onSecondary: AppColors.white,
          secondaryContainer: const Color(0xFFFFDADA),
          onSecondaryContainer: AppColors.red,

          // Terciária — azul marinho suave
          tertiary: AppColors.navyBlueLight,
          onTertiary: AppColors.white,
          tertiaryContainer: const Color(0xFFE0E6FF),
          onTertiaryContainer: AppColors.navyBlue,

          // Erro
          error: AppColors.red,
          onError: AppColors.white,
          errorContainer: const Color(0xFFFFDADA),
          onErrorContainer: AppColors.red,

          // Superfícies
          surface: const Color(0xFFF8F9FF),
          onSurface: AppColors.navyBlue,
          surfaceContainerHighest: const Color(0xFFE8EAF6),
          onSurfaceVariant: const Color(0xFF44476A),

          // Contorno
          outline: const Color(0xFF767AA8),
          outlineVariant: const Color(0xFFC4C6E0),

          // Sombra e inversão
          shadow: AppColors.navyBlue,
          inverseSurface: AppColors.navyBlue,
          onInverseSurface: AppColors.white,
          inversePrimary: const Color(0xFFB8C3FF),
          scrim: AppColors.navyBlue,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.navyBlue,
          foregroundColor: AppColors.white,
          centerTitle: true,
          elevation: 2,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.navyBlue,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: AppColors.navyBlue, width: 2),
          ),
        ),
      );
}

