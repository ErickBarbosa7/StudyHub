import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// PALETA DE COLOR — "Estudio"
// ─────────────────────────────────────────────────────────────
//
// Los kColor* de abajo apuntan a la paleta nueva (kRoom*, definida más
// abajo). Junto a cada uno queda comentado su valor anterior de la paleta
// "Focus & Paper" (verde salvia, crema y dorado) por si se quiere volver:
// basta con restaurar ese Color(0x...) en cada línea.
//
// Paleta anterior — filosofía:
// Filosofía:
// • Neutros cálidos como base → reducen ruido visual.
// • Verde profundo → foco, acciones e interacción.
// • Verde suave → estados secundarios y superficies.
// • Dorado → recompensa y progreso, no acciones.
// • Rojo → errores exclusivamente.
//
// Objetivo:
// Una interfaz tranquila para sesiones largas de estudio,
// sin colores saturados que compitan con el contenido.
// ─────────────────────────────────────────────────────────────


// ═════════════════════════════════════════════════════════════
// COLORES PRINCIPALES
// ═════════════════════════════════════════════════════════════

const Color kColorPaper = kRoomBg; // antes: Color(0xFFFAFAF7)
// Fondo principal.
// Blanco ligeramente cálido para evitar la sensación clínica
// de un blanco puro.

const Color kColorCard = kRoomSurface; // antes: Color(0xFFF2F3ED)
// Superficies secundarias.
// Sutilmente diferenciadas del fondo.

const Color kColorSage = kColorSageMid; // antes: Color(0xFF9BAF9D)
// Verde salvia suave.
// Uso decorativo, estados secundarios y superficies.

const Color kColorDeepSage = kRoomStudy; // antes: Color(0xFF486B52)
// Verde principal.
// Acciones, botones, foco, elementos activos e interacción.

const Color kColorGold = kRoomBreak; // antes: Color(0xFFC5A15A)
// Dorado.
// Reservado para progreso, logros y elementos completados.

const Color kColorInk = kRoomInk; // antes: Color(0xFF29312B)
// Texto principal.
// Alto contraste sin llegar al negro puro.


// ═════════════════════════════════════════════════════════════
// COLORES DE APOYO
// ═════════════════════════════════════════════════════════════

const Color kColorTextSecondary = kRoomMuted; // antes: Color(0xFF687268)
// Texto secundario.
// Descripciones, timestamps y metadata.

const Color kColorBorder = kRoomLine; // antes: Color(0xFFDFE3DA)
// Bordes y divisores.
// Muy sutil para evitar ruido visual.

const Color kColorSageSoft = kRoomStudySoft; // antes: Color(0xFFE8EEE8)
// Verde muy suave.
// Chips, iconos, estados informativos y pequeños fondos.

const Color kColorGoldSoft = kRoomBreakSoft; // antes: Color(0xFFF3EEDF)
// Dorado lavado.
// Fondos asociados a logros y progreso.


// ═════════════════════════════════════════════════════════════
// ESTADOS
// ═════════════════════════════════════════════════════════════

const Color kColorError = kRoomError; // antes: Color(0xFFC94A4A)

const Color kColorErrorBorder = Color(0xFFE9A6A6);

const Color kColorStateDone = kRoomStudy; // antes: Color(0xFF10B981)
const Color kColorStateInProgress = kRoomBreak; // antes: Color(0xFFF59E0B)
const Color kColorStatePending = kRoomMuted; // antes: Color(0xFFF43F5E)


// ═════════════════════════════════════════════════════════════
// PALETA DE LA SALA — "Estudio" (rediseño de sala)
// ═════════════════════════════════════════════════════════════
//
// Solo se usa dentro de la sala (lib/ui/room, pomodoro, tareas y chat).
// La paleta anterior "Focus & Paper" sigue intacta arriba (kColorPaper,
// kColorDeepSage, kColorGold, ...) y la usan inicio y crear/unirse.
// Para volver a ella basta con apuntar los widgets de la sala a esas
// constantes en lugar de estas.
//
// Regla: un solo color por modo del reloj; todo lo demás es neutro.

const Color kRoomBg = Color(0xFFF3F2EE); // fondo de pantalla
const Color kRoomSurface = Color(0xFFFFFFFF); // tarjetas
const Color kRoomInk = Color(0xFF1C2321); // texto principal
const Color kRoomMuted = Color(0xFF5D6763); // texto secundario
const Color kRoomLine = Color(0xFFE3E1DA); // bordes
const Color kRoomTrack = Color(0xFFEEEDE8); // fondos neutros (selector, chips)
const Color kRoomRingTrack = Color(0xFFE9E7E1); // pista del anillo
const Color kRoomDisabled = Color(0xFFC9C6BC);

const Color kRoomStudy = Color(0xFF1F6B5C); // estudio
const Color kRoomStudySoft = Color(0xFFE3EFEB);

const Color kRoomBreak = Color(0xFFA65A00); // descanso corto
const Color kRoomBreakSoft = Color(0xFFFAEBD5);
const Color kRoomBreakInk = Color(0xFF8A4B00); // texto sobre kRoomBreakSoft

const Color kRoomLong = Color(0xFF484C9B); // descanso largo
const Color kRoomLongSoft = Color(0xFFE8E9F6);

const Color kRoomError = Color(0xFFB3372F);

// Tono medio del verde azulado (decorativo, antes salvia #9BAF9D).
const Color kColorSageMid = Color(0xFF8DB8AC);


// ═════════════════════════════════════════════════════════════
// SUPERFICIES Y SOMBRAS
// ═════════════════════════════════════════════════════════════

const Color kColorSurfaceWhite = kColorPaper;

const Color kColorSurfaceSoft = kColorCard;

// Sombra extremadamente sutil.
// La intención es separar elementos sin crear una interfaz
// llena de sombras.
final Color kColorTintedShadow =
    kColorDeepSage.withValues(alpha: 0.06);



const Color kColorRingActive = kColorDeepSage;

const Color kColorRingComplete = kColorGold;

const Color kColorRingInactive = kColorBorder;

const String kFontFamily = 'Recursive';

const String kFontFamilyMono = 'Cascadia Code';


abstract final class AppType {

  // ───────────────────────────────────────────────────────────
  // TAMAÑOS
  // ───────────────────────────────────────────────────────────

  static const double sizeMicro = 10;

  static const double sizeCaption = 12;

  static const double sizeLabel = 13;

  static const double sizeBody = 14;

  static const double sizeBodyMedium = 15;

  static const double sizeBodyLarge = 16;

  static const double sizeTitle = 20;

  static const double sizeHeadline = 22;

  static const double sizeDisplay = 28;

  static const double sizeHero = 40;

  static const double sizeGiant = 48;

  static const double sizeTimerDisplay = 44;

  static const double sizeTimerCompact = 38;

  static const double sizeTimerLarge = 56;


  // ───────────────────────────────────────────────────────────
  // PESOS
  // ───────────────────────────────────────────────────────────

  static const FontWeight weightRegular =
      FontWeight.w400;

  static const FontWeight weightMedium =
      FontWeight.w500;

  static const FontWeight weightSemiBold =
      FontWeight.w600;

  static const FontWeight weightBold =
      FontWeight.w700;


  // ───────────────────────────────────────────────────────────
  // MONO
  // ───────────────────────────────────────────────────────────

  static const TextStyle mono = TextStyle(
    fontFamily: kFontFamilyMono,
    fontWeight: weightMedium,
    color: kColorInk,
    fontFeatures: [
      FontFeature.tabularFigures(),
    ],
  );


  // ───────────────────────────────────────────────────────────
  // TIMER
  // ───────────────────────────────────────────────────────────

  static TextStyle monoTimer({
    Color color = kColorInk,
    double? fontSize,
  }) =>
      TextStyle(
        fontFamily: kFontFamilyMono,
        fontWeight: weightSemiBold,
        fontSize: fontSize ?? sizeTimerDisplay,
        color: color,
        fontFeatures: const [
          FontFeature.tabularFigures(),
        ],
      );


  // ───────────────────────────────────────────────────────────
  // ITÁLICA
  // ───────────────────────────────────────────────────────────

  static const FontVariation italicSlant =
      FontVariation('slnt', -14);


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
        fontVariations: const [
          italicSlant,
        ],
      );
}


// ═════════════════════════════════════════════════════════════
// THEME
// ═════════════════════════════════════════════════════════════

ThemeData buildTheme() {

  final ColorScheme colorScheme = ColorScheme(
    brightness: Brightness.light,

    // ─────────────────────────────────────────────────────────
    // PRIMARY
    // ─────────────────────────────────────────────────────────

    primary: kColorDeepSage,

    onPrimary: kColorPaper,


    // ─────────────────────────────────────────────────────────
    // SECONDARY
    // ─────────────────────────────────────────────────────────

    secondary: kColorSage,

    onSecondary: kColorInk,


    // ─────────────────────────────────────────────────────────
    // TERTIARY
    // ─────────────────────────────────────────────────────────

    // Dorado = recompensa.
    tertiary: kColorGold,

    onTertiary: kColorPaper,

    tertiaryContainer: kColorGoldSoft,

    onTertiaryContainer: kColorInk,


    // ─────────────────────────────────────────────────────────
    // ERROR
    // ─────────────────────────────────────────────────────────

    error: kColorError,

    onError: kColorPaper,


    // ─────────────────────────────────────────────────────────
    // SURFACE
    // ─────────────────────────────────────────────────────────

    surface: kColorCard,

    onSurface: kColorInk,
  );


  return ThemeData(

    // ─────────────────────────────────────────────────────────
    // BASE
    // ─────────────────────────────────────────────────────────

    useMaterial3: true,

    colorScheme: colorScheme,

    scaffoldBackgroundColor: kColorPaper,

    fontFamily: kFontFamily,


    // ═══════════════════════════════════════════════════════
    // TYPOGRAPHY
    // ═══════════════════════════════════════════════════════

    textTheme: const TextTheme(

      displayLarge: TextStyle(
        fontSize: AppType.sizeDisplay,
        fontWeight: FontWeight.w800,
        color: kColorInk,
        height: 1.15,
        letterSpacing: -0.4,
      ),

      headlineMedium: TextStyle(
        fontSize: AppType.sizeHeadline,
        fontWeight: FontWeight.w700,
        color: kColorInk,
        height: 1.2,
        letterSpacing: -0.3,
      ),

      titleLarge: TextStyle(
        fontSize: AppType.sizeTitle,
        fontWeight: FontWeight.w700,
        color: kColorInk,
        height: 1.25,
        letterSpacing: -0.2,
      ),

      bodyLarge: TextStyle(
        fontSize: AppType.sizeBodyLarge,
        fontWeight: AppType.weightRegular,
        color: kColorInk,
        height: 1.3,
      ),

      bodyMedium: TextStyle(
        fontSize: AppType.sizeBodyMedium,
        fontWeight: AppType.weightRegular,
        color: kColorInk,
        height: 1.35,
      ),

      bodySmall: TextStyle(
        fontSize: AppType.sizeBody,
        fontWeight: AppType.weightRegular,
        color: kColorTextSecondary,
        fontVariations: [
          AppType.italicSlant,
        ],
      ),

      labelLarge: TextStyle(
        fontSize: AppType.sizeLabel,
        fontWeight: AppType.weightSemiBold,
        color: kColorInk,
      ),

      labelSmall: TextStyle(
        fontSize: AppType.sizeCaption,
        fontWeight: AppType.weightRegular,
        color: kColorTextSecondary,
        fontVariations: [
          AppType.italicSlant,
        ],
      ),
    ),


    // ═══════════════════════════════════════════════════════
    // APP BAR
    // ═══════════════════════════════════════════════════════

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: kColorInk,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
    ),


    // ═══════════════════════════════════════════════════════
    // ELEVATED BUTTON
    // ═══════════════════════════════════════════════════════

    elevatedButtonTheme: ElevatedButtonThemeData(

      style: ElevatedButton.styleFrom(

        // Verde = acción principal.
        backgroundColor: kColorDeepSage,

        // Papel sobre verde.
        foregroundColor: kColorPaper,

        minimumSize: const Size.fromHeight(56),

        // Sin sombra para mantener la interfaz tranquila.
        elevation: 0,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),

        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),

        textStyle: const TextStyle(
          fontFamily: kFontFamily,
          fontWeight: AppType.weightSemiBold,
          fontSize: AppType.sizeBodyLarge,
        ),
      ),
    ),


    // ═══════════════════════════════════════════════════════
    // OUTLINED BUTTON
    // ═══════════════════════════════════════════════════════

    outlinedButtonTheme: OutlinedButtonThemeData(

      style: OutlinedButton.styleFrom(

        foregroundColor: kColorDeepSage,

        side: const BorderSide(
          color: kColorDeepSage,
          width: 1.5,
        ),

        minimumSize: const Size.fromHeight(56),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),

        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),

        textStyle: const TextStyle(
          fontFamily: kFontFamily,
          fontWeight: AppType.weightSemiBold,
          fontSize: AppType.sizeBodyLarge,
        ),
      ),
    ),


    // ═══════════════════════════════════════════════════════
    // INPUTS
    // ═══════════════════════════════════════════════════════

    inputDecorationTheme: InputDecorationTheme(

      filled: true,

      fillColor: kColorPaper,

      hintStyle: const TextStyle(
        color: kColorTextSecondary,
        fontSize: AppType.sizeBodyMedium,
      ),

      labelStyle: const TextStyle(
        color: kColorTextSecondary,
        fontSize: AppType.sizeBodyMedium,
      ),

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),


      // ─────────────────────────────────────────────────────
      // Default
      // ─────────────────────────────────────────────────────

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),


      // ─────────────────────────────────────────────────────
      // Enabled
      // ─────────────────────────────────────────────────────

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),


      // ─────────────────────────────────────────────────────
      // Focus
      // ─────────────────────────────────────────────────────

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),

        borderSide: const BorderSide(
          color: kColorDeepSage,
          width: 1.5,
        ),
      ),


      // ─────────────────────────────────────────────────────
      // Error
      // ─────────────────────────────────────────────────────

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),

        borderSide: const BorderSide(
          color: kColorErrorBorder,
          width: 1.5,
        ),
      ),


      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),

        borderSide: const BorderSide(
          color: kColorError,
          width: 1.5,
        ),
      ),
    ),


    // ═══════════════════════════════════════════════════════
    // CARDS
    // ═══════════════════════════════════════════════════════

    cardTheme: CardThemeData(

      color: kColorCard,

      elevation: 0,

      margin: const EdgeInsets.symmetric(
        vertical: 8,
      ),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
    ),


    // ═══════════════════════════════════════════════════════
    // CHIPS
    // ═══════════════════════════════════════════════════════

    chipTheme: ChipThemeData(

      // Verde suave para no competir con el contenido.
      backgroundColor: kColorSageSoft,

      side: BorderSide.none,

      labelStyle: const TextStyle(
        color: kColorInk,
        fontWeight: AppType.weightMedium,
      ),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),


    // ═══════════════════════════════════════════════════════
    // SNACKBAR
    // ═══════════════════════════════════════════════════════

    snackBarTheme: const SnackBarThemeData(

      backgroundColor: kColorInk,

      behavior: SnackBarBehavior.floating,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(16),
        ),
      ),
    ),


    // ═══════════════════════════════════════════════════════
    // DIALOG
    // ═══════════════════════════════════════════════════════

    dialogTheme: DialogThemeData(

      backgroundColor: kColorPaper,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    ),


    // ═══════════════════════════════════════════════════════
    // BOTTOM SHEET
    // ═══════════════════════════════════════════════════════

    bottomSheetTheme: const BottomSheetThemeData(

      backgroundColor: kColorPaper,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(32),
        ),
      ),
    ),


    // ═══════════════════════════════════════════════════════
    // TABS
    // ═══════════════════════════════════════════════════════

    tabBarTheme: TabBarThemeData(
      labelColor: kColorDeepSage,
      unselectedLabelColor: kColorTextSecondary,
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: BoxDecoration(
        color: kColorCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      labelStyle: const TextStyle(fontWeight: AppType.weightSemiBold),
      unselectedLabelStyle: const TextStyle(fontWeight: AppType.weightMedium),
      dividerColor: Colors.transparent,
    ),
  );
}