/// Enlace de invitación a una sala.
///
/// El QR guarda una URL completa (`https://tu-sitio/?sala=ABC123`) en vez del
/// código suelto: así la cámara del celular lo abre como enlace y la app
/// entra directo a "Unirse" con el código ya escrito.
const String _kParam = 'sala';
const int _kCodeLength = 6;

/// URL de invitación para [code], sobre el mismo sitio donde corre la app.
String joinUrl(String code) {
  final base = Uri.base;
  final hasOrigin = base.scheme == 'http' || base.scheme == 'https';
  if (!hasOrigin) return code;
  return Uri(
    scheme: base.scheme,
    host: base.host,
    port: base.hasPort ? base.port : null,
    path: '/',
    queryParameters: {_kParam: code},
  ).toString();
}

/// Código de sala que trae la URL actual, si la hay.
String? codeFromCurrentUrl() => codeFromScan(Uri.base.queryParameters[_kParam]);

/// Extrae el código de lo que lea el escáner: un enlace de invitación o el
/// código suelto. Devuelve `null` si no parece un código válido.
String? codeFromScan(String? raw) {
  if (raw == null) return null;
  var text = raw.trim();
  final uri = Uri.tryParse(text);
  if (uri != null && uri.hasScheme && uri.queryParameters[_kParam] != null) {
    text = uri.queryParameters[_kParam]!;
  }
  final code = text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  return code.length == _kCodeLength ? code : null;
}
