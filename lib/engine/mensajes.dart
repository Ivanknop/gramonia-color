/// Mensaje del panel final al terminar una obra de la historia: uno al azar
/// entre varios, según cuántas obras le faltan a su lugar (los textos están
/// en `Textos.mensajesObra`).
library;

import 'dart:math' as math;

import 'progresion.dart';

/// Textos para elegir, con `{lugar}` (el lugar con artículo, en minúscula),
/// `{Lugar}` (igual, en mayúscula) y `{n}` (obras que faltan).
typedef MensajesDeObra = ({List<String> faltan, List<String> faltaUna, List<String> completo});

/// Obras disponibles del [lugar] que todavía no se terminaron.
int obrasQueFaltan(Bioma lugar, Set<String> completados) =>
    lugar.cuadroIds.where((id) => !completados.contains(id)).length;

/// Mensaje al terminar una obra de [lugar], con [completados] ya incluyendo
/// la obra recién terminada.
String mensajeDeObra(
  Bioma lugar,
  Set<String> completados,
  MensajesDeObra textos,
  math.Random azar,
) {
  final faltan = obrasQueFaltan(lugar, completados);
  final opciones = switch (faltan) {
    0 => textos.completo,
    1 => textos.faltaUna,
    _ => textos.faltan,
  };
  final elegido = opciones[azar.nextInt(opciones.length)];
  final conLugar = lugar.conArticulo;
  return elegido
      .replaceAll('{Lugar}', conLugar[0].toUpperCase() + conLugar.substring(1))
      .replaceAll('{lugar}', conLugar)
      .replaceAll('{n}', '$faltan')
      // "a el" → "al", "de el" → "del".
      .replaceAll(RegExp(r'\ba el '), 'al ')
      .replaceAll(RegExp(r'\bde el '), 'del ');
}
