/// Dificultades del modo libre y de "rehacer obra" (a mano en assets/dificultades.json). Cada
/// cuadro tiene una variante por dificultad, `<cuadro>--<dificultad>`, cuyo id es también la clave
/// de su progreso.
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
  final int plumas;
}

List<Dificultad> leerDificultades(String texto) {
  final j = jsonDecode(texto) as Map<String, dynamic>;
  return [
    for (final d in j['dificultades'] as List) Dificultad.desdeJson(d as Map<String, dynamic>),
  ];
}

/// Dificultades que ya no están en la tabla (se pasó de diez a siete). Al
/// cargar un guardado viejo se descarta lo pintado en ellas (ver `Progreso`).
const dificultadesRetiradas = {'mediano', 'muy-dificil', 'insano'};

const separadorVariante = '--';

String idVariante(String cuadroId, String dificultadId) =>
    '$cuadroId$separadorVariante$dificultadId';

/// Cuadro del que sale un id (el mismo id si no es una variante).
String cuadroBase(String id) => id.split(separadorVariante).first;

/// Dificultad de un id de variante (null si es un cuadro de la historia).
String? dificultadDe(String id) {
  final i = id.indexOf(separadorVariante);
  return i < 0 ? null : id.substring(i + separadorVariante.length);
}
