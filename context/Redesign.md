# StudyHub — Brief de Rediseño Visual: "Enfoque Índigo"

## Objetivo
Reemplazar la paleta actual ("Enfoque Natural", verde bosque) por una paleta índigo/azul violeta que se sienta más asociada a concentración y productividad digital, manteniendo el coral como acento de energía/equipo. El objetivo es una app que se vea **moderna y enfocada**, no una "app de plantas".

## Qué NO cambia
- Estructura de pantallas, componentes, jerarquía de información.
- Nombres de variables de color en código (`kColorDarkGreen`, `kColorSoftGreen`, etc. se mantienen aunque ya no sean verdes — evita romper referencias).
- Radios de borde (16–32px), sistema de espaciado, tipografía (Sora + JetBrains Mono).
- Convención de un solo botón primario de 56px por pantalla.
- Targets táctiles mínimos 44×44.

## Paleta nueva

| Rol | Antes | Ahora | Uso |
|---|---|---|---|
| Color principal (`kColorDarkGreen`) | `#2D6A4F` verde bosque | **`#4C4CAB` índigo** | Botones primarios, íconos, checkboxes, chip activo, timer |
| Color secundario (`kColorSoftGreen`) | `#52B788` verde esmeralda | **`#7B7BD6` índigo claro** | Éxito/completado, subtítulos, chat |
| Acento (`kColorAmber`) | `#E76F51` coral | **se mantiene `#E76F51`** | Módulo de Tareas — el contraste índigo/coral es más vivo que verde/coral, no tocar |
| Fondo (`kColorBackground`/`kColorCream`) | `#F7FAF8` menta | **`#F7F7FB` lavanda casi blanco** | Fondo de pantallas |
| Texto principal (`kColorOffBlack`) | `#183024` verde pino oscuro | **`#201E36` índigo casi negro** | Textos principales, nunca negro puro |
| Texto secundario | `#6A8074` gris verdoso | **`#716F94` gris violáceo** | Subtítulos, labels |
| Bordes neutrales (`kColorOlive`) | `#DCE5E0` gris-verde | **`#E1E0EF` gris-lavanda** | Bordes, chips neutrales |
| Fondo suave amber | `#FDECE7` | sin cambio | Header de Tareas |
| Teal (chat) | `#52B788` (duplicaba el verde secundario) | **`#7B7BD6`** (duplica el índigo claro) | Burbujas ajenas, nombre remitente, borde focal input chat |
| Fondo suave teal | `#E8F4EE` | **`#EDEDFA`** | Header de Chat, burbujas ajenas |
| Sombra tintada | verde 8% | **índigo 8%** (`kColorDarkGreen.withValues(alpha: 0.08)`) | Tarjetas/paneles elevados |
| Error | `#E63946` / borde `#FCA5A5` | sin cambio | Validaciones |

**Regla de armonía:** todo lo que antes era "verdoso" (fondos, bordes, texto secundario) ahora es "violáceo/lavanda", para que el cambio de color principal no quede aislado — toda la paleta de apoyo debe respirar en la misma familia cromática.

## Ajustes de mejora sugeridos (más allá del cambio de color)

1. **Contraste del texto en botón primario:** con índigo `#4C4CAB` el texto blanco (`kColorSurfaceWhite`) sigue teniendo buen contraste — no requiere cambio, pero verificar accesibilidad (ratio ≥ 4.5:1) al implementar.
2. **Diferenciación Chat vs. Color principal:** antes el chat (teal) y el secundario (verde esmeralda) eran literalmente el mismo valor. Se mantiene esa duplicación intencional en índigo claro — está bien, pero si se quiere una identidad de módulo más distintiva a futuro, considerar un teal real (`#2A9D8F`) solo para el chat, dejando el índigo claro exclusivo para estados de "completado".
3. **Timer y Pomodoro:** el dial mono en índigo sobre fondo lavanda 30% mantiene buena legibilidad; no requiere ajuste de tamaño de fuente.
4. **Pill "Activo"/"En progreso":** sigue usando fondo oliva 30% + texto verde en la especificación actual — actualizar a fondo lavanda 30% (`kColorOlive` ya redefinido) + texto índigo.
5. **JetBrains Mono:** sigue declarado en el theme pero sin registrar en `pubspec.yaml`, por lo que no carga. Si se quiere que los dígitos del Pomodoro y timestamps realmente usen tabular figures monoespaciadas, hay que añadir el archivo de fuente y su entrada en `pubspec.yaml`. Fuera del alcance de este cambio de color, pero se señala porque afecta el resultado visual esperado.

## Checklist de implementación para la IA que ejecute el cambio
- [x] Reemplazar los valores hex en `theme.dart` (ver archivo adjunto `theme.dart` ya actualizado).
- [x] Buscar en todo el proyecto usos de colores hardcodeados (`Color(0xFF...)`) fuera de `theme.dart` que dupliquen los valores viejos de verde y reemplazarlos por las constantes (`kColorDarkGreen`, etc.), nunca por hex nuevos sueltos.
- [x] Revisar `home_screen.dart`: título hero, CTA, modal "¿Cómo funciona?" (íconos en caja "oliva suave" → ahora lavanda suave).
- [x] Revisar `create_room_screen.dart`: pills de segmented control, campo de nombre, botón principal.
- [x] Revisar workspace de sala: pill de código, chips de conectados, TabBar, dial Pomodoro, pills de duración.
- [x] Revisar tarjeta de Tareas: el amber/coral NO cambia, solo el checkbox completado (relleno verde → relleno índigo) y la pill "Completada" (fondo verde 20% → fondo índigo claro 20%).
- [x] Revisar Chat: burbujas propias (índigo), burbujas ajenas (lavanda suave/índigo claro), input focus border.
- [x] Confirmar que ninguna sombra, borde o fondo residual siga en tono verde tras el cambio (buscar `0xFF2D6A4F`, `0xFF52B788`, `0xFFDCE5E0`, `0xFF183024`, `0xFF6A8074`, `0xFFF7FAF8`, `0xFFE8F4EE` como residuos).