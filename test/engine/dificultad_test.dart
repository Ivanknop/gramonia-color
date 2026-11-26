import 'dart:io';

import 'package:colores_de_gramonia/engine/dificultad.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tabla = leerDificultades(File('assets/dificultades.json').readAsStringSync());

  test('cada dificultad pide más colores y regiones, y da más plumas que la anterior', () {
    expect(tabla, isNotEmpty);
    for (var i = 1; i < tabla.length; i++) {
      final (antes, d) = (tabla[i - 1], tabla[i]);
      expect(d.colores, greaterThan(antes.colores), reason: d.id);
      expect(d.regiones, greaterThan(antes.regiones), reason: d.id);
      expect(d.plumas, greaterThan(antes.plumas), reason: d.id);
      expect(d.regiones, greaterThanOrEqualTo(d.colores), reason: d.id);
    }
  });

  test('ninguna dificultad usa el id de una retirada', () {
    expect(tabla.map((d) => d.id).toSet().intersection(dificultadesRetiradas), isEmpty);
  });

  test('ids de variantes', () {
    final id = idVariante('nido-de-rocanon', 'facil');
    expect(id, 'nido-de-rocanon--facil');
    expect(cuadroBase(id), 'nido-de-rocanon');
    expect(dificultadDe(id), 'facil');
    expect(cuadroBase('nido-de-rocanon'), 'nido-de-rocanon');
    expect(dificultadDe('nido-de-rocanon'), isNull);
  });
}
