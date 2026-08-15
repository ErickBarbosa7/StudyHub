import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// PALETA DE COLOR — "Marigold & Índigo" (Basada en Ilustraciones)
// #FFC436 (Naranja Claro/Marigold) es el color principal.
// Sintoniza con las animaciones Lottie (dorado #FFC627/#FBC830) y con
// los grises pizarra de la ilustración (#253138, #455A63, #37464F).
// El Índigo contrasta perfectamente y el Gris Pizarra ancla el diseño.
// Los nombres de variables se mantienen intactos.
// ─────────────────────────────────────────────────────────────

const Color kColorBackground = Color(0xFFF4F5F8); // Gris perla muy claro (fondo de la imagen)
const Color kColorCream = Color(0xFFF4F5F8);

// EL TRÍO PROTAGONISTA
const Color kColorDarkGreen = Color(0xFFFFC436); // NARANJA CLARO (Color principal: focos, acciones, luz de la ilustración)
const Color kColorSoftGreen = Color(0xFF5A55D2); // ÍNDIGO SUAVE (Secundario: botones outline, texto de la ilustración)
const Color kColorAmber = Color(0xFF434B54); // GRIS PIZARRA (Acentos: engranajes, libros, detalles de tareas)

// COLORES DE APOYO
const Color kColorOlive = Color(0xFFE2E6EA); // Gris neutro suave (Para bordes y chips)
const Color kColorOffBlack = Color(0xFF2C3137); // Pizarra casi negro para textos (combinado con los engranajes)
const Color kColorTextSecondary = Color(0xFF717983); // Gris medio para textos secundarios

const Color kColorAmberSoft = Color(0xFFFFF4D6); // Fondo suave para el Naranja Claro
const Color kColorAnimationSoft = Color(0xFFFFF4D6); // Fondo suave del dial activo (empata con el dorado del loading)
const Color kColorTeal = Color(0xFF5A55D2); // Índigo para el chat (iconos y nombres)
const Color kColorTealSoft = Color(0xFFEEEDFB); // Fondo suave para el chat

const Color kColorError = Color(0xFFE63946);
const Color kColorErrorBorder = Color(0xFFFCA5A5);

// SUPERFICIES Y SOMBRAS
const Color kColorSurfaceWhite = Color(0xFFFFFFFF);
const Color kColorSurfaceSoft = Color(0xB3FFFFFF);
// Sombra teñida del Índigo secundario para no ensuciar el naranja
final Color kColorTintedShadow = kColorSoftGreen.withValues(alpha: 0.06);

// ─────────────────────────────────────────────────────────────
// ANILLO DE PRESENCIA — elemento de firma
// naranja claro = sesión activa, índigo = completado, gris = inactivo.
// Se aplica en 4 lugares: dial del pomodoro, anillo del avatar en
// las tarjetas de sala, checkbox de tarea y estado de presencia en el chat.
// No usar este set fuera de esos 4 contextos.
// ─────────────────────────────────────────────────────────────

const Color kColorRingActive = kColorDarkGreen; // Sesión de foco en curso
const Color kColorRingComplete = kColorSoftGreen; // Tarea o pomodoro completado
const Color kColorRingInactive = kColorOlive; // Sala/tarea sin actividad

// ─────────────────────────────────────────────────────────────
// TIPOGRAFÍA
// Recursive para todo lo editorial (títulos, cuerpo, botones).
// Cascadia Code (mono) con cifras tabulares para lo que cambia número a número:
// el conteo del pomodoro, timestamps del chat, contadores de tareas.
// Los nombres de variables se mantienen intactos.
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
    color: kColorOffBlack,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static TextStyle monoTimer({Color color = kColorOffBlack}) => TextStyle(
        fontFamily: kFontFamilyMono,
        fontWeight: weightSemiBold,
        fontSize: sizeTimerDisplay,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // Cursiva nativa de Recursive (eje slnt) para texto de apoyo,
  // acento tipográfico de las interfaces estilo Claude Code.
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
    primary: kColorDarkGreen, // Naranja Claro
    onPrimary: kColorOffBlack, // TEXTO OSCURO para contrastar con el fondo claro
    secondary: kColorSoftGreen, // Índigo
    onSecondary: kColorSurfaceWhite,
    tertiary: kColorAmber, // Gris Pizarra
    onTertiary: kColorSurfaceWhite,
    tertiaryContainer: kColorAmberSoft,
    onTertiaryContainer: kColorOffBlack,
    error: kColorError,
    onError: kColorSurfaceWhite,
    surface: kColorBackground,
    onSurface: kColorOffBlack,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: kColorBackground,
    fontFamily: kFontFamily,

    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: AppType.sizeDisplay, fontWeight: FontWeight.w800, color: kColorOffBlack, height: 1.15, letterSpacing: -0.4),
      headlineMedium: TextStyle(fontSize: AppType.sizeHeadline, fontWeight: FontWeight.w700, color: kColorOffBlack, height: 1.2, letterSpacing: -0.3),
      titleLarge: TextStyle(fontSize: AppType.sizeTitle, fontWeight: FontWeight.w700, color: kColorOffBlack, height: 1.25, letterSpacing: -0.2),
      bodyLarge: TextStyle(fontSize: AppType.sizeBodyLarge, fontWeight: AppType.weightRegular, color: kColorOffBlack, height: 1.3),
      bodyMedium: TextStyle(fontSize: AppType.sizeBodyMedium, fontWeight: AppType.weightRegular, color: kColorOffBlack, height: 1.35),
      bodySmall: TextStyle(fontSize: AppType.sizeBody, fontWeight: AppType.weightRegular, color: kColorTextSecondary, fontVariations: [AppType.italicSlant]),
      labelLarge: TextStyle(fontSize: AppType.sizeLabel, fontWeight: AppType.weightSemiBold, color: kColorOffBlack),
      labelSmall: TextStyle(fontSize: AppType.sizeCaption, fontWeight: AppType.weightRegular, color: kColorTextSecondary, fontVariations: [AppType.italicSlant]),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: kColorOffBlack,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kColorDarkGreen, // Botones principales en Naranja Claro
        foregroundColor: kColorOffBlack, // Texto oscuro para legibilidad
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
        foregroundColor: kColorSoftGreen, // Botones secundarios en Índigo
        side: const BorderSide(color: kColorSoftGreen, width: 1.5),
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
      fillColor: kColorSurfaceWhite,
      hintStyle: const TextStyle(color: kColorTextSecondary, fontSize: AppType.sizeBodyMedium),
      labelStyle: const TextStyle(color: kColorTextSecondary, fontSize: AppType.sizeBodyMedium),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kColorOlive, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kColorOlive, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kColorDarkGreen, width: 2), // Naranja al escribir
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kColorErrorBorder, width: 1.5),
      ),
    ),

    cardTheme: CardThemeData(
      color: kColorSurfaceWhite,
      elevation: 8,
      shadowColor: kColorTintedShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Colors.white, width: 1.5),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: kColorSurfaceWhite,
      side: const BorderSide(color: kColorOlive, width: 1),
      labelStyle: const TextStyle(
        color: kColorOffBlack,
        fontWeight: AppType.weightMedium,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}