import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// PALETA DE COLOR — "Estudio"
// ─────────────────────────────────────────────────────────────
//
// Los colores viven en `AppColors`, una ThemeExtension con una instancia por
// brillo. La UI nunca usa `const Color` sueltas: pide el token al contexto con
// `context.colors`, que Material resuelve del `ThemeData` activo. Así el mismo
// widget se dibuja solo en claro o en oscuro, y los colores del tema se pueden
// animar con `lerp` al cambiar de modo.
//
// main.dart: `theme: buildTheme(Brightness.light)` y
// `darkTheme: buildTheme(Brightness.dark)`, con el `themeMode` del provider
// (logic/theme_provider.dart).
//
// Paleta anterior — filosofía:
// Filosofía:
// • Neutros cálidos como base → reducen ruido visual.
// • Violeta profundo → foco, acciones e interacción.
// • Verde suave → estados secundarios y superficies.
// • Dorado → recompensa y progreso, no acciones.
// • Rojo → errores exclusivamente.
//
// Objetivo:
// Una interfaz tranquila para sesiones largas de estudio,
// sin colores saturados que compitan con el contenido.
//
// Paleta "Focus & Paper" (la anterior a la actual), por si se quiere volver:
//   paper #FAFAF7 · card #F2F3ED · sage #9BAF9D · deepSage #486B52
//   gold #C5A15A · ink #29312B · muted #687268 · line #DFE3DA
//   sageSoft #E8EEE8 · goldSoft #F3EEDF · error #C94A4A
//   estados: done #10B981 · inProgress #F59E0B · pending #F43F5E
// ─────────────────────────────────────────────────────────────

// ═════════════════════════════════════════════════════════════
// TOKENS DE COLOR
// ═════════════════════════════════════════════════════════════

/// Paleta de la app para un brillo concreto.
///
/// Se accede desde la UI con `context.colors.<token>`.
///
/// Regla: un solo color por modo del reloj (estudio, descanso corto, descanso
/// largo); todo lo demás es neutro.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.line,
    required this.track,
    required this.ringTrack,
    required this.disabled,
    required this.study,
    required this.studySoft,
    required this.rest,
    required this.restSoft,
    required this.restInk,
    required this.longRest,
    required this.longRestSoft,
    required this.error,
    required this.errorSoft,
    required this.errorLine,
    required this.sageMid,
    required this.onAccent,
    required this.snackBg,
    required this.snackText,
    required this.shadow,
    required this.brand,
    required this.taskFg,
    required this.taskSoft,
    required this.taskLine,
    required this.chatFg,
    required this.chatSoft,
    required this.chatLine,
    required this.helpFg,
    required this.helpSoft,
    required this.helpLine,
    required this.themeFg,
    required this.themeSoft,
    required this.themeLine,
  });

  // ── Neutros ────────────────────────────────────────────────

  /// Fondo de pantalla.
  final Color bg;

  /// Tarjetas y paneles.
  final Color surface;

  /// Texto principal. Nunca negro puro.
  final Color ink;

  /// Texto secundario, descripciones y metadatos.
  final Color muted;

  /// Bordes y divisores.
  final Color line;

  /// Fondos neutros: selectores, chips, campos.
  final Color track;

  /// Pista del anillo del reloj.
  final Color ringTrack;

  /// Elementos deshabilitados.
  final Color disabled;

  // ── Modos del reloj ────────────────────────────────────────

  /// Estudio: acciones, foco, elementos activos.
  final Color study;

  /// Fondo suave de estudio: chips, iconos, estados informativos.
  final Color studySoft;

  /// Descanso corto.
  final Color rest;

  /// Fondo suave de descanso corto.
  final Color restSoft;

  /// Texto sobre [restSoft].
  final Color restInk;

  /// Descanso largo.
  final Color longRest;

  /// Fondo suave de descanso largo.
  final Color longRestSoft;

  // ── Errores ────────────────────────────────────────────────

  final Color error;
  final Color errorSoft;
  final Color errorLine;

  // ── Acento decorativo ──────────────────────────────────────

  /// Tono medio del violeta.
  final Color sageMid;

  // ── Sobre acento ───────────────────────────────────────────

  /// Texto e iconos colocados sobre [study] o [bg] (botón principal, avisos).
  ///
  /// En oscuro se invierte a un violeta muy oscuro: el acento es claro y necesita
  /// texto oscuro encima para mantener el contraste.
  final Color onAccent;

  // ── Avisos ─────────────────────────────────────────────────

  /// Fondo de los avisos (notificaciones, banners).
  ///
  /// Sigue siendo de alto contraste en ambos modos: en oscuro la píldora se
  /// vuelve clara sobre el fondo oscuro, en vez de un gris apagado.
  final Color snackBg;

  /// Texto sobre [snackBg].
  final Color snackText;

  // ── Sombras ────────────────────────────────────────────────

  /// Sombra tintada de tarjetas. En oscuro, negro (una sombra de color verde no
  /// se ve sobre un fondo oscuro).
  final Color shadow;

  // ── Marca ──────────────────────────────────────────────────

  /// Fondo del panel de marca del inicio (blanco encima). Violeta profundo en
  /// ambos modos: en oscuro se hunde para no ser el bloque más brillante de la
  /// pantalla, pero sigue dando contraste al texto blanco.
  final Color brand;

  // ── Identidad por sección: tareas (violeta) y chat (rosa) ──
  final Color taskFg;
  final Color taskSoft;
  final Color taskLine;
  final Color chatFg;
  final Color chatSoft;
  final Color chatLine;

  // ── Botones de acción con identidad propia ────────────────
  /// Ayuda (azul) y modo claro/oscuro (índigo): cada control con su color.
  final Color helpFg;
  final Color helpSoft;
  final Color helpLine;
  final Color themeFg;
  final Color themeSoft;
  final Color themeLine;

  /// Paleta clara: la que se usó siempre hasta ahora.
  static const light = AppColors(
    bg: Color(0xFFFAF8F4),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF24282A),
    muted: Color(0xFF6F7678),
    line: Color(0xFFE7E4DC),
    track: Color(0xFFF1EEE7),
    ringTrack: Color(0xFFE8E5DC),
    disabled: Color(0xFFCFCDC5),
    study: Color(0xFF0A87A3),
    studySoft: Color(0xFFD9F2F7),
    rest: Color(0xFF16A34A),
    restSoft: Color(0xFFDCF7E4),
    restInk: Color(0xFF0F7A36),
    longRest: Color(0xFF0EA5E9),
    longRestSoft: Color(0xFFDCF2FD),
    error: Color(0xFFDC2F3F),
    errorSoft: Color(0xFFFDE4E6),
    errorLine: Color(0xFFF4B6BC),
    sageMid: Color(0xFF3FB6CC),
    onAccent: Color(0xFFFFFFFF),
    snackBg: Color(0xFF24282A),
    snackText: Color(0xFFF4F3EE),
    shadow: Color(0x260A87A3),
    helpFg: Color(0xFFD97706),
    helpSoft: Color(0xFFFFEFD0),
    helpLine: Color(0xFFF8D68E),
    themeFg: Color(0xFF6D3BE8),
    themeSoft: Color(0xFFEDE7FF),
    themeLine: Color(0xFFD8CCFB),
    taskFg: Color(0xFF0A87A3),
    taskSoft: Color(0xFFD9F2F7),
    taskLine: Color(0xFFB3E1EB),
    chatFg: Color(0xFF0A87A3),
    chatSoft: Color(0xFFD9F2F7),
    chatLine: Color(0xFFB3E1EB),
    brand: Color(0xFFF5F1EA),
  );

  /// Paleta oscura (rojo coral aclarado para contraste).
  static const dark = AppColors(
    bg: Color(0xFF161A1C),
    surface: Color(0xFF1F2528),
    ink: Color(0xFFECEFEF),
    muted: Color(0xFFA3ACAE),
    line: Color(0xFF2E3538),
    track: Color(0xFF262C2F),
    ringTrack: Color(0xFF2C3336),
    disabled: Color(0xFF5E6669),
    study: Color(0xFF38D0E8),
    studySoft: Color(0xFF0F3A44),
    rest: Color(0xFF4ADE80),
    restSoft: Color(0xFF12301F),
    restInk: Color(0xFFA6EBC3),
    longRest: Color(0xFF7DD3FC),
    longRestSoft: Color(0xFF12344A),
    error: Color(0xFFFF6B78),
    errorSoft: Color(0xFF3A1F22),
    errorLine: Color(0xFF5A2C31),
    sageMid: Color(0xFF22A9C2),
    onAccent: Color(0xFF04262D),
    snackBg: Color(0xFFECEFEF),
    snackText: Color(0xFF161A1C),
    shadow: Color(0x8A000000),
    helpFg: Color(0xFFFFB84D),
    helpSoft: Color(0xFF3D2E0C),
    helpLine: Color(0xFF5A4415),
    themeFg: Color(0xFFB79BFF),
    themeSoft: Color(0xFF2A2050),
    themeLine: Color(0xFF42367A),
    taskFg: Color(0xFF38D0E8),
    taskSoft: Color(0xFF0F3A44),
    taskLine: Color(0xFF1D5565),
    chatFg: Color(0xFF38D0E8),
    chatSoft: Color(0xFF0F3A44),
    chatLine: Color(0xFF1D5565),
    brand: Color(0xFF1B2124),
  );

  /// Colores de la sala por modo de reloj. Para pintar el dial según la fase.
  Color modeColor(String mode) {
    if (mode == 'SHORT_BREAK') return rest;
    if (mode == 'LONG_BREAK') return longRest;
    return study;
  }

  /// Fondo suave de la sala por modo de reloj.
  Color modeSoft(String mode) {
    if (mode == 'SHORT_BREAK') return restSoft;
    if (mode == 'LONG_BREAK') return longRestSoft;
    return studySoft;
  }

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? ink,
    Color? muted,
    Color? line,
    Color? track,
    Color? ringTrack,
    Color? disabled,
    Color? study,
    Color? studySoft,
    Color? rest,
    Color? restSoft,
    Color? restInk,
    Color? longRest,
    Color? longRestSoft,
    Color? error,
    Color? errorSoft,
    Color? errorLine,
    Color? sageMid,
    Color? onAccent,
    Color? snackBg,
    Color? snackText,
    Color? shadow,
    Color? brand,
    Color? taskFg,
    Color? taskSoft,
    Color? taskLine,
    Color? chatFg,
    Color? chatSoft,
    Color? chatLine,
    Color? helpFg,
    Color? helpSoft,
    Color? helpLine,
    Color? themeFg,
    Color? themeSoft,
    Color? themeLine,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      line: line ?? this.line,
      track: track ?? this.track,
      ringTrack: ringTrack ?? this.ringTrack,
      disabled: disabled ?? this.disabled,
      study: study ?? this.study,
      studySoft: studySoft ?? this.studySoft,
      rest: rest ?? this.rest,
      restSoft: restSoft ?? this.restSoft,
      restInk: restInk ?? this.restInk,
      longRest: longRest ?? this.longRest,
      longRestSoft: longRestSoft ?? this.longRestSoft,
      error: error ?? this.error,
      errorSoft: errorSoft ?? this.errorSoft,
      errorLine: errorLine ?? this.errorLine,
      sageMid: sageMid ?? this.sageMid,
      onAccent: onAccent ?? this.onAccent,
      snackBg: snackBg ?? this.snackBg,
      snackText: snackText ?? this.snackText,
      shadow: shadow ?? this.shadow,
      brand: brand ?? this.brand,
      taskFg: taskFg ?? this.taskFg,
      taskSoft: taskSoft ?? this.taskSoft,
      taskLine: taskLine ?? this.taskLine,
      chatFg: chatFg ?? this.chatFg,
      chatSoft: chatSoft ?? this.chatSoft,
      chatLine: chatLine ?? this.chatLine,
      helpFg: helpFg ?? this.helpFg,
      helpSoft: helpSoft ?? this.helpSoft,
      helpLine: helpLine ?? this.helpLine,
      themeFg: themeFg ?? this.themeFg,
      themeSoft: themeSoft ?? this.themeSoft,
      themeLine: themeLine ?? this.themeLine,
    );
  }

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      bg: mix(bg, other.bg),
      surface: mix(surface, other.surface),
      ink: mix(ink, other.ink),
      muted: mix(muted, other.muted),
      line: mix(line, other.line),
      track: mix(track, other.track),
      ringTrack: mix(ringTrack, other.ringTrack),
      disabled: mix(disabled, other.disabled),
      study: mix(study, other.study),
      studySoft: mix(studySoft, other.studySoft),
      rest: mix(rest, other.rest),
      restSoft: mix(restSoft, other.restSoft),
      restInk: mix(restInk, other.restInk),
      longRest: mix(longRest, other.longRest),
      longRestSoft: mix(longRestSoft, other.longRestSoft),
      error: mix(error, other.error),
      errorSoft: mix(errorSoft, other.errorSoft),
      errorLine: mix(errorLine, other.errorLine),
      sageMid: mix(sageMid, other.sageMid),
      onAccent: mix(onAccent, other.onAccent),
      snackBg: mix(snackBg, other.snackBg),
      snackText: mix(snackText, other.snackText),
      shadow: mix(shadow, other.shadow),
      brand: mix(brand, other.brand),
      taskFg: mix(taskFg, other.taskFg),
      taskSoft: mix(taskSoft, other.taskSoft),
      taskLine: mix(taskLine, other.taskLine),
      chatFg: mix(chatFg, other.chatFg),
      chatSoft: mix(chatSoft, other.chatSoft),
      chatLine: mix(chatLine, other.chatLine),
      helpFg: mix(helpFg, other.helpFg),
      helpSoft: mix(helpSoft, other.helpSoft),
      helpLine: mix(helpLine, other.helpLine),
      themeFg: mix(themeFg, other.themeFg),
      themeSoft: mix(themeSoft, other.themeSoft),
      themeLine: mix(themeLine, other.themeLine),
    );
  }
}

/// Los tokens de color del tema activo.
///
/// Un `Theme.of(context)` por método `build` y se pasa el resultado a las
/// propiedades: `[c.ink, c.muted]` en vez de repetir la búsqueda.
extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>() ?? AppColors.light;
}


const String kFontFamily = 'Nunito';

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

  /// Fuente monoespaciada sin color: el que lo use decide el tono (para el reloj
  /// suele ser el del modo actual, no el de la paleta).
  static const TextStyle mono = TextStyle(
    fontFamily: kFontFamilyMono,
    fontWeight: weightMedium,
    fontFeatures: [
      FontFeature.tabularFigures(),
    ],
  );


  // ───────────────────────────────────────────────────────────
  // TIMER
  // ───────────────────────────────────────────────────────────

  static TextStyle monoTimer({
    required BuildContext context,
    Color? color,
    double? fontSize,
  }) =>
      TextStyle(
        fontFamily: kFontFamilyMono,
        fontWeight: weightSemiBold,
        fontSize: fontSize ?? sizeTimerDisplay,
        color: color ?? context.colors.ink,
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
    required BuildContext context,
    double size = sizeBodyMedium,
    Color? color,
  }) =>
      TextStyle(
        fontFamily: kFontFamily,
        fontWeight: weightRegular,
        fontSize: size,
        color: color ?? context.colors.muted,
        height: 1.3,
        fontVariations: const [
          italicSlant,
        ],
      );
}


// ═════════════════════════════════════════════════════════════
// THEME
// ═════════════════════════════════════════════════════════════

ThemeData buildTheme([Brightness brightness = Brightness.light]) {

  final c = brightness == Brightness.dark ? AppColors.dark : AppColors.light;

  final ColorScheme colorScheme = ColorScheme(
    brightness: brightness,

    // ─────────────────────────────────────────────────────────
    // PRIMARY
    // ─────────────────────────────────────────────────────────

    primary: c.study,

    onPrimary: c.onAccent,


    // ─────────────────────────────────────────────────────────
    // SECONDARY
    // ─────────────────────────────────────────────────────────

    secondary: c.sageMid,

    onSecondary: c.ink,


    // ─────────────────────────────────────────────────────────
    // TERTIARY
    // ─────────────────────────────────────────────────────────

    // Ámbar = recompensa.
    tertiary: c.rest,

    onTertiary: c.onAccent,

    tertiaryContainer: c.restSoft,

    onTertiaryContainer: c.restInk,


    // ─────────────────────────────────────────────────────────
    // ERROR
    // ─────────────────────────────────────────────────────────

    error: c.error,

    onError: c.onAccent,


    // ─────────────────────────────────────────────────────────
    // SURFACE
    // ─────────────────────────────────────────────────────────

    surface: c.surface,

    onSurface: c.ink,

    onSurfaceVariant: c.muted,

    surfaceContainerHighest: c.track,

    outline: c.line,

    outlineVariant: c.line,
  );


  return ThemeData(

    // ─────────────────────────────────────────────────────────
    // BASE
    // ─────────────────────────────────────────────────────────

    useMaterial3: true,

    colorScheme: colorScheme,

    brightness: brightness,

    // Paleta de la app: la UI la lee con `context.colors`.
    extensions: [c],

    scaffoldBackgroundColor: c.bg,

    // Transiciones suaves entre pantallas en todas las plataformas.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
      },
    ),

    // Feedback al tocar: onda suave del color primario.
    splashFactory: InkSparkle.splashFactory,
    splashColor: c.studySoft,
    highlightColor: Colors.transparent,

    fontFamily: kFontFamily,


    // ═══════════════════════════════════════════════════════
    // TYPOGRAPHY
    // ═══════════════════════════════════════════════════════

    textTheme: TextTheme(

      displayLarge: TextStyle(
        fontSize: AppType.sizeDisplay,
        fontWeight: FontWeight.w800,
        color: c.ink,
        height: 1.15,
        letterSpacing: -0.4,
      ),

      headlineMedium: TextStyle(
        fontSize: AppType.sizeHeadline,
        fontWeight: FontWeight.w700,
        color: c.ink,
        height: 1.2,
        letterSpacing: -0.3,
      ),

      titleLarge: TextStyle(
        fontSize: AppType.sizeTitle,
        fontWeight: FontWeight.w700,
        color: c.ink,
        height: 1.25,
        letterSpacing: -0.2,
      ),

      bodyLarge: TextStyle(
        fontSize: AppType.sizeBodyLarge,
        fontWeight: AppType.weightRegular,
        color: c.ink,
        height: 1.3,
      ),

      bodyMedium: TextStyle(
        fontSize: AppType.sizeBodyMedium,
        fontWeight: AppType.weightRegular,
        color: c.ink,
        height: 1.35,
      ),

      bodySmall: TextStyle(
        fontSize: AppType.sizeBody,
        fontWeight: AppType.weightRegular,
        color: c.muted,
        fontVariations: [
          AppType.italicSlant,
        ],
      ),

      labelLarge: TextStyle(
        fontSize: AppType.sizeLabel,
        fontWeight: AppType.weightSemiBold,
        color: c.ink,
      ),

      labelSmall: TextStyle(
        fontSize: AppType.sizeCaption,
        fontWeight: AppType.weightRegular,
        color: c.muted,
        fontVariations: [
          AppType.italicSlant,
        ],
      ),
    ),


    // ═══════════════════════════════════════════════════════
    // APP BAR
    // ═══════════════════════════════════════════════════════

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: c.ink,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
    ),


    // ═══════════════════════════════════════════════════════
    // ELEVATED BUTTON
    // ═══════════════════════════════════════════════════════

    elevatedButtonTheme: ElevatedButtonThemeData(

      style: ElevatedButton.styleFrom(

        // Violeta = acción principal.
        backgroundColor: c.study,

        // Texto de alto contraste sobre ese verde.
        foregroundColor: c.onAccent,

        disabledBackgroundColor: c.track,
        disabledForegroundColor: c.disabled,

        minimumSize: const Size.fromHeight(56),

        elevation: 0,
        shadowColor: c.shadow,

        shape: const StadiumBorder(),

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

        foregroundColor: c.study,

        side: BorderSide(
          color: c.study,
          width: 1.5,
        ),

        minimumSize: const Size.fromHeight(56),

        shape: const StadiumBorder(),

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
    // TEXT BUTTON
    // ═══════════════════════════════════════════════════════

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.study,
        textStyle: const TextStyle(
          fontFamily: kFontFamily,
          fontWeight: AppType.weightSemiBold,
          fontSize: AppType.sizeBodyLarge,
        ),
      ),
    ),


    // ═══════════════════════════════════════════════════════
    // ICON
    // ═══════════════════════════════════════════════════════

    iconTheme: IconThemeData(color: c.ink),


    // ═══════════════════════════════════════════════════════
    // INPUTS
    // ═══════════════════════════════════════════════════════

    inputDecorationTheme: InputDecorationTheme(

      filled: true,

      fillColor: c.track,

      hintStyle: TextStyle(
        color: c.muted,
        fontSize: AppType.sizeBodyMedium,
      ),

      labelStyle: TextStyle(
        color: c.muted,
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
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),


      // ─────────────────────────────────────────────────────
      // Enabled
      // ─────────────────────────────────────────────────────

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),


      // ─────────────────────────────────────────────────────
      // Focus
      // ─────────────────────────────────────────────────────

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),

        borderSide: BorderSide(
          color: c.study,
          width: 1.5,
        ),
      ),


      // ─────────────────────────────────────────────────────
      // Error
      // ─────────────────────────────────────────────────────

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),

        borderSide: BorderSide(
          color: c.errorLine,
          width: 1.5,
        ),
      ),


      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),

        borderSide: BorderSide(
          color: c.error,
          width: 1.5,
        ),
      ),
    ),


    // ═══════════════════════════════════════════════════════
    // CARDS
    // ═══════════════════════════════════════════════════════

    cardTheme: CardThemeData(

      color: c.surface,

      elevation: 0,

      margin: const EdgeInsets.symmetric(
        vertical: 8,
      ),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
    ),


    // ═══════════════════════════════════════════════════════
    // CHIPS
    // ═══════════════════════════════════════════════════════

    chipTheme: ChipThemeData(

      // Fondo suave para no competir con el contenido.
      backgroundColor: c.studySoft,

      side: BorderSide.none,

      labelStyle: TextStyle(
        color: c.ink,
        fontWeight: AppType.weightMedium,
      ),

      shape: const StadiumBorder(),
    ),


    // ═══════════════════════════════════════════════════════
    // SNACKBAR
    // ═══════════════════════════════════════════════════════

    snackBarTheme: SnackBarThemeData(

      backgroundColor: c.snackBg,

      contentTextStyle: TextStyle(color: c.snackText),

      behavior: SnackBarBehavior.floating,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(20),
        ),
      ),
    ),


    // ═══════════════════════════════════════════════════════
    // DIALOG
    // ═══════════════════════════════════════════════════════

    dialogTheme: DialogThemeData(

      backgroundColor: c.bg,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
    ),


    // ═══════════════════════════════════════════════════════
    // BOTTOM SHEET
    // ═══════════════════════════════════════════════════════

    bottomSheetTheme: BottomSheetThemeData(

      backgroundColor: c.bg,

      surfaceTintColor: Colors.transparent,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(32),
        ),
      ),
    ),


    // ═══════════════════════════════════════════════════════
    // TABS
    // ═══════════════════════════════════════════════════════

    tabBarTheme: TabBarThemeData(
      labelColor: c.study,
      unselectedLabelColor: c.muted,
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
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
