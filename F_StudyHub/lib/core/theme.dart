import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// PALETA DE COLOR — "Papel, Salvia y un Hilo de Oro"
// Un libro a la luz del día: papel crudo de fondo, verde salvia
// para lo vivo, tinta suave para tipografía y un dorado moderado
// para detalles. Nada saturado; nada compite con el contenido.
// ─────────────────────────────────────────────────────────────

// EL SEXTETO PROTAGONISTA
const Color kColorPaper = Color(0xFFFDFCF8); // Fondo principal (papel bajo luz cálida)
const Color kColorCard = Color(0xFFF1EEE3); // Superficies secundarias (tarjetas)
const Color kColorSage = Color(0xFF8FA893); // Color principal (fondos destacados)
const Color kColorDeepSage = Color(0xFF5E7A64); // Secundario (acción, íconos, contraste)
const Color kColorGold = Color(0xFFC7A05A); // Acento: "un hilo de oro" (ornamento sutil)
const Color kColorInk = Color(0xFF2B2E2A); // Texto principal (nunca negro puro)

// COLORES DE APOYO (derivados de la misma familia)
const Color kColorTextSecondary = Color(0xFF5F6B5B); // Gris salvia para textos secundarios
const Color kColorBorder = Color(0xFFE4E0D4); // Línea pergamino (bordes, chips neutros)
const Color kColorSageSoft = Color(0xFFE7EDE6); // Salvia lavada (chips, icon boxes, estados)
const Color kColorGoldSoft = Color(0xFFF2EAD8); // Arena dorada (módulo con acento oro)

const Color kColorError = Color(0xFFE63946);
const Color kColorErrorBorder = Color(0xFFFCA5A5);

// SUPERFICIES Y SOMBRAS
const Color kColorSurfaceWhite = kColorPaper;
const Color kColorSurfaceSoft = kColorPaper;
// Sombra teñida de salvia profunda, casi imperceptible
final Color kColorTintedShadow = kColorDeepSage.withValues(alpha: 0.08);

// ─────────────────────────────────────────────────────────────
// ANILLO DE PRESENCIA — elemento de firma
// salvia profunda = sesión activa, oro = completado, pergamino = inactivo.
// Se aplica en 4 lugares: dial del pomodoro, anillo del avatar en
// las tarjetas de sala, checkbox de tarea y estado de presencia en el chat.
// No usar este set fuera de esos 4 contextos.
// ─────────────────────────────────────────────────────────────

const Color kColorRingActive = kColorDeepSage; // Sesión de foco en curso
const Color kColorRingComplete = kColorGold; // Tarea o pomodoro completado (hilo de oro)
const Color kColorRingInactive = kColorBorder; // Sala/tarea sin actividad

// ─────────────────────────────────────────────────────────────
// TIPOGRAFÍA ("Unhurried")
// Recursive para todo lo editorial (títulos, cuerpo, botones).
// Cascadia Code (mono) con cifras tabulares para lo que cambia número a número:
// el conteo del pomodoro, timestamps del chat, contadores de tareas.
// ─────────────────────────────────────────────────────────────

const String kFontFamily = 'Recursive';
const String kFontFamilyMono = 'Cascadia Code';

abstract final class AppType {
  static const double sizeMicro = 10;
  static const double sizeCaption = 12;
  static const double sizeLabel = 13;
  static const double sizeBody = 14;
  static const double sizeBodyMedium = 15;
  static const double sizeBodyLarge = 16;
  static const double sizeTitle = 20;
  static const double sizeHeadline = 22;
  static const double sizeDisplay = 28;
  static const double sizeTimerDisplay = 44; // Dígitos grandes del dial del pomodoro

  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemiBold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;

  static const TextStyle mono = TextStyle(
    fontFamily: kFontFamilyMono,
    fontWeight: weightMedium,
    color: kColorInk,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static TextStyle monoTimer({Color color = kColorInk}) => TextStyle(
        fontFamily: kFontFamilyMono,
        fontWeight: weightSemiBold,
        fontSize: sizeTimerDisplay,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static const FontVariation italicSlant = FontVariation('slnt', -14);

  static TextStyle secondaryItalic({
    double size = sizeBodyMedium,
    Color color = kColorTextSecondary,
  }) =>
      TextStyle(
        fontFamily: kFontFamily,
        fontWeight: weightRegular,
        fontSize: size,
        color: color,
        height: 1.3,
        fontVariations: const [italicSlant],
      );
}

ThemeData buildTheme() {
  final ColorScheme colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: kColorDeepSage, // Salvia profunda: acciones e interacción
    onPrimary: kColorPaper, // Papel sobre salvia (regla del brief)
    secondary: kColorSage, // Salvia: superficies destacadas
    onSecondary: kColorInk,
    tertiary: kColorGold, // El hilo de oro
    onTertiary: kColorPaper,
    tertiaryContainer: kColorGoldSoft,
    onTertiaryContainer: kColorInk,
    error: kColorError,
    onError: kColorPaper,
    surface: kColorCard,
    onSurface: kColorInk,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: kColorPaper,
    fontFamily: kFontFamily,

    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: AppType.sizeDisplay, fontWeight: FontWeight.w800, color: kColorInk, height: 1.15, letterSpacing: -0.4),
      headlineMedium: TextStyle(fontSize: AppType.sizeHeadline, fontWeight: FontWeight.w700, color: kColorInk, height: 1.2, letterSpacing: -0.3),
      titleLarge: TextStyle(fontSize: AppType.sizeTitle, fontWeight: FontWeight.w700, color: kColorInk, height: 1.25, letterSpacing: -0.2),
      bodyLarge: TextStyle(fontSize: AppType.sizeBodyLarge, fontWeight: AppType.weightRegular, color: kColorInk, height: 1.3),
      bodyMedium: TextStyle(fontSize: AppType.sizeBodyMedium, fontWeight: AppType.weightRegular, color: kColorInk, height: 1.35),
      bodySmall: TextStyle(fontSize: AppType.sizeBody, fontWeight: AppType.weightRegular, color: kColorTextSecondary, fontVariations: [AppType.italicSlant]),
      labelLarge: TextStyle(fontSize: AppType.sizeLabel, fontWeight: AppType.weightSemiBold, color: kColorInk),
      labelSmall: TextStyle(fontSize: AppType.sizeCaption, fontWeight: AppType.weightRegular, color: kColorTextSecondary, fontVariations: [AppType.italicSlant]),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: kColorInk,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kColorDeepSage, // Salvia profunda
        foregroundColor: kColorPaper, // Papel sobre salvia, sin colores ajenos
        minimumSize: const Size.fromHeight(56),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(
          fontFamily: kFontFamily,
          fontWeight: AppType.weightSemiBold,
          fontSize: AppType.sizeBodyLarge,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kColorDeepSage,
        side: const BorderSide(color: kColorDeepSage, width: 1.5),
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(
          fontFamily: kFontFamily,
          fontWeight: AppType.weightSemiBold,
          fontSize: AppType.sizeBodyLarge,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kColorPaper,
      hintStyle: const TextStyle(color: kColorTextSecondary, fontSize: AppType.sizeBodyMedium),
      labelStyle: const TextStyle(color: kColorTextSecondary, fontSize: AppType.sizeBodyMedium),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kColorDeepSage, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kColorErrorBorder, width: 1.5),
      ),
    ),

    cardTheme: CardThemeData(
      color: kColorCard,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: kColorSageSoft,
      side: BorderSide.none,
      labelStyle: const TextStyle(
        color: kColorInk,
        fontWeight: AppType.weightMedium,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    snackBarTheme: const SnackBarThemeData(
      backgroundColor: kColorInk,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: kColorPaper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: kColorPaper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
    ),

    tabBarTheme: const TabBarThemeData(
      indicatorColor: kColorDeepSage,
      labelColor: kColorInk,
      unselectedLabelColor: kColorTextSecondary,
      indicatorSize: TabBarIndicatorSize.label,
    ),
  );
}
