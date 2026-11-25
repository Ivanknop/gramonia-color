/// Abre enlaces en el navegador del teléfono con un canal nativo propio
/// (MainActivity.kt), para no sumar dependencias por un solo enlace.
library;

import 'package:flutter/services.dart';

/// Blog de los Cuentos de Gramonia.
const urlCuentos = 'https://cuentosdegramonia.substack.com/';

const _canal = MethodChannel('gramonia/enlaces');

/// Abre [url] en el navegador. Devuelve false si no se pudo.
Future<bool> abrirEnlace(String url) async {
  try {
    return await _canal.invokeMethod<bool>('abrir', {'url': url}) ?? false;
  } on PlatformException {
    return false;
  } on MissingPluginException {
    return false;
  }
}
