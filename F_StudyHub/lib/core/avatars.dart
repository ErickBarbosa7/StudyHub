import 'package:dicebear_core/dicebear_core.dart';
import 'package:dicebear_styles/sprouts.dart';

/// Avatares por defecto: estilo "Sprouts" de DiceBear (CC0), generados en el
/// dispositivo. Sin red, sin datos que salgan del teléfono y sin parpadeo de
/// carga.
///
/// El SVG sale sin fondo (`backgroundColor: []`; por defecto trae uno saturado
/// distinto por seed): el círculo que lo contiene (`RoomAvatar`) pone el fondo
/// con los tokens del tema, así se ve bien también en oscuro.
Style? _style;

final Map<String, String> _svgBySeed = {};

final RegExp _metadata = RegExp(r'<metadata.*?</metadata>', dotAll: true);

/// SVG del avatar para [seed]. El mismo seed da siempre el mismo dibujo.
///
/// El estilo se interpreta una sola vez (es la parte cara) y cada SVG se
/// guarda: un avatar se redibuja muchas veces (cada cambio de la lista de
/// personas) pero se genera una sola.
String avatarSvg(String seed) {
  return _svgBySeed.putIfAbsent(seed, () {
    final style = _style ??= Style.parse(sprouts);
    final svg = Avatar(style, {'seed': seed, 'backgroundColor': []}).svg;
    // flutter_svg avisa por consola de cada <metadata> que no dibuja.
    return svg.replaceAll(_metadata, '');
  });
}

/// Interpreta el estilo antes de que haga falta: la primera vez cuesta unos
/// cientos de milisegundos y, hecha al abrir la sala, congelaría el primer
/// cuadro.
void warmUpAvatars() {
  avatarSvg('warm-up');
}
