/// Abre enlaces con un canal nativo propio (MainActivity.kt), para no sumar una dependencia por un
/// solo enlace.
library;

import 'package:flutter/services.dart';

const urlCuentos = 'https://cuentosdegramonia.substack.com/';

const _canal = MethodChannel('gramonia/enlaces');

Future<bool> abrirEnlace(String url) async {
  try {
    return await _canal.invokeMethod<bool>('abrir', {'url': url}) ?? false;
  } on PlatformException {
    return false;
  } on MissingPluginException {
    return false;
  }
}
