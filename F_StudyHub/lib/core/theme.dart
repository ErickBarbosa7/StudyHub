import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// PALETA DE COLOR — "Trío Equilibrado sobre Violeta" (Modern & Organic)
// #2A113B (Violeta Profundo) es el color principal.
// Teal y Terracota se reparten el peso visual para que
// ningún color domine. Los nombres se mantienen para no romper nada.
// ─────────────────────────────────────────────────────────────

const Color kColorBackground = Color(0xFFF7F5F9); // Blancuzco con tinte de lila muy sutil
const Color kColorCream = Color(0xFFF7F5F9);

// EL TRÍO PROTAGONISTA (Se reparten el peso visual)
const Color kColorDarkGreen = Color(0xFF2A113B); // VIOLETA PROFUNDO (Color principal: acciones, focos)
const Color kColorSoftGreen = Color(0xFF2A9D8F); // TEAL ESMERALDA (Secundario: botones outline, estados completados)
const Color kColorAmber = Color(0xFFE76F51); // TERRACOTA (Acentos de apoyo: badges, detalles de tareas)

// COLORES DE APOYO
const Color kColorOlive = Color(0xFFE8E3EE); // Lila-gris suave (Para bordes y chips neutrales)
const Color kColorOffBlack = Color(0xFF241C2E); // Gris muy oscuro con tinte violeta para textos legibles
const Color kColorTextSecondary = Color(0xFF6F6779); // Gris violeta para textos secundarios

const Color kColorAmberSoft = Color(0xFFFBE5DE); // Fondo suave para el Terracota
const Color kColorTeal = Color(0xFF2A9D8F); // Teal para el chat (iconos y nombres)
const Color kColorTealSoft = Color(0xFFE0F2EF); // Fondo suave para el chat

const Color kColorError = Color(0xFFEF4444);
const Color kColorErrorBorder = Color(0xFFFCA5A5);

// SUPERFICIES Y SOMBRAS
const Color kColorSurfaceWhite = Color(0xFFFFFFFF);
const Color kColorSurfaceSoft = Color(0xB3FFFFFF);
// Sombra teñida de Violeta para que combine con el color principal
final Color kColorTintedShadow = kColorDarkGreen.withValues(alpha: 0.08);

// ─────────────────────────────────────────────────────────────
// ANILLO DE PRESENCIA — elemento de firma
// Mismo trío de color, usado siempre con el mismo significado:
// violeta = sesión activa, teal = completado, lila-niebla = inactivo.
// Se aplica en 4 lugares: dial del pomodoro, anillo del avatar en
// las tarjetas de sala, checkbox de tarea y estado de presencia en el chat.
// No usar este set fuera de esos 4 contextos.
// ─────────────────────────────────────────────────────────────

const Color kColorRingActive = kColorDarkGreen; // Sesión de foco en curso
const Color kColorRingComplete = kColorSoftGreen; // Tarea o pomodoro completado
const Color kColorRingInactive = kColorOlive; // Sala/tarea sin actividad

// ─────────────────────────────────────────────────────────────
// TIPOGRAFÍA
// Sora para todo lo editorial (títulos, cuerpo, botones).
// Una mono con cifras tabulares para lo que cambia número a número:
// el conteo del pomodoro, timestamps del chat, contadores de tareas.
// Así esos valores no "bailan" de ancho y la app se siente un
// poco más instrumento de precisión, no solo lista bonita.
// ─────────────────────────────────────────────────────────────

const String kFontFamily = 'Sora';
const String kFontFamilyMono = 'JetBrains Mono';

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

  // Estilo para cualquier número que cambie en vivo: timer, contadores,
  // timestamps de chat. fontFeatures activa cifras tabulares donde el
  // font en cuestión las soporte.
  static const TextStyle mono = TextStyle(
    fontFamily: kFontFamilyMono,
    fontWeight: weightMedium,
    color: kColorOffBlack,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static TextStyle monoTimer({Color color = kColorDarkGreen}) => TextStyle(
        fontFamily: kFontFamilyMono,
        fontWeight: weightSemiBold,
        fontSize: sizeTimerDisplay,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}

ThemeData buildTheme() {
  final ColorScheme colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: kColorDarkGreen, // Violeta Profundo
    onPrimary: kColorSurfaceWhite,
    secondary: kColorSoftGreen, // Teal Esmeralda
    onSecondary: kColorSurfaceWhite,
    tertiary: kColorAmber, // Terracota
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
      displayLarge: TextStyle(fontSize: AppType.sizeDisplay, fontWeight: AppType.weightBold, color: kColorOffBlack),
      headlineMedium: TextStyle(fontSize: AppType.sizeHeadline, fontWeight: AppType.weightSemiBold, color: kColorOffBlack),
      titleLarge: TextStyle(fontSize: AppType.sizeTitle, fontWeight: AppType.weightSemiBold, color: kColorOffBlack),
      bodyLarge: TextStyle(fontSize: AppType.sizeBodyLarge, fontWeight: AppType.weightRegular, color: kColorOffBlack),
      bodyMedium: TextStyle(fontSize: AppType.sizeBodyMedium, fontWeight: AppType.weightRegular, color: kColorOffBlack),
      bodySmall: TextStyle(fontSize: AppType.sizeBody, fontWeight: AppType.weightRegular, color: kColorTextSecondary),
      labelLarge: TextStyle(fontSize: AppType.sizeLabel, fontWeight: AppType.weightMedium, color: kColorOffBlack),
      labelSmall: TextStyle(fontSize: AppType.sizeCaption, fontWeight: AppType.weightRegular, color: kColorTextSecondary),
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
        backgroundColor: kColorDarkGreen, // Botones principales en Violeta
        foregroundColor: kColorSurfaceWhite,
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
        foregroundColor: kColorSoftGreen, // Botones secundarios en Teal para equilibrar el color
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
        borderSide: const BorderSide(color: kColorDarkGreen, width: 2), // Violeta al escribir
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
      side: const BorderSide(color: kColorOlive, width: 1), // Bordes neutros para que no sature
      labelStyle: const TextStyle(
        color: kColorOffBlack,
        fontWeight: AppType.weightMedium,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}