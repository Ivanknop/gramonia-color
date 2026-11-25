/// Dificultades del modo libre y de "rehacer obra". La tabla está a mano en
/// `assets/dificultades.json` (la lee también el conversor): cada dificultad
/// tiene una cantidad fija de colores, un objetivo de regiones y las plumas que
/// da terminar un cuadro en el modo libre (crecen con la dificultad).
///
/// Cada cuadro tiene una variante por dificultad, generada por el conversor:
/// `assets/variantes/<cuadro>--<dificultad>.svg/.json`, que usa la ilustración
/// del cuadro. El id de la variante es también la clave de su progreso.
library;

import 'dart:convert';

class Dificultad {
  const Dificultad({
    required this.id,
    required this.nombre,
    required this.colores,
    required this.regiones,
    required this.plumas,
  });

  factory Dificultad.desdeJson(Map<String, dynamic> j) => Dificultad(
    id: j['id'] as String,
    nombre: j['nombre'] as String,
    colores: j['colores'] as int,
    regiones: j['regiones'] as int,
    plumas: j['plumas'] as int,
  );

  final String id;
  final String nombre;

  /// Colores de la paleta (exactos).
  final int colores;

  /// Regiones a pintar (objetivo: el conversor fusiona hasta llegar).
  final int regiones;

  /// Plumas por terminar un cuadro del modo libre en esta dificultad.
  final int plumas;
}

/// Lee la tabla de `assets/dificultades.json`, en el orden de la pantalla.
List<Dificultad> leerDificultades(String texto) {
  final j = jsonDecode(texto) as Map<String, dynamic>;
  return [
    for (final d in j['dificultades'] as List) Dificultad.desdeJson(d as Map<String, dynamic>),
  ];
}

const separadorVariante = '--';

/// Id de la variante de [cuadroId] en la dificultad [dificultadId].
String idVariante(String cuadroId, String dificultadId) =>
    '$cuadroId$separadorVariante$dificultadId';

/// Cuadro del que sale un id (el mismo id si no es una variante).
String cuadroBase(String id) => id.split(separadorVariante).first;

/// Dificultad de un id de variante (null si es un cuadro de la historia).
String? dificultadDe(String id) {
  final i = id.indexOf(separadorVariante);
  return i < 0 ? null : id.substring(i + separadorVariante.length);
}
