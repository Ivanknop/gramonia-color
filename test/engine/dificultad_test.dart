import 'dart:io';

import 'package:colores_de_gramonia/engine/dificultad.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tabla = leerDificultades(File('assets/dificultades.json').readAsStringSync());

  test('la tabla tiene las diez dificultades en orden', () {
    expect(tabla.map((d) => d.nombre), [
      'Súper fácil',
      'Fácil',
      'Normal',
      'Mediano',
      'Difícil',
      'Muy difícil',
      'Extremo',
      'Imposible',
      'Insano',
      'Divino',
    ]);
  });

  test('cada dificultad tiene más colores y más regiones que la anterior', () {
    for (var i = 1; i < tabla.length; i++) {
      expect(tabla[i].colores, greaterThan(tabla[i - 1].colores), reason: tabla[i].id);
      expect(tabla[i].regiones, greaterThan(tabla[i - 1].regiones), reason: tabla[i].id);
      expect(tabla[i].regiones, greaterThanOrEqualTo(tabla[i].colores), reason: tabla[i].id);
    }
  });

  test('ids de variantes', () {
    final id = idVariante('nido-de-rocanon', 'muy-dificil');
    expect(id, 'nido-de-rocanon--muy-dificil');
    expect(cuadroBase(id), 'nido-de-rocanon');
    expect(dificultadDe(id), 'muy-dificil');
    expect(cuadroBase('nido-de-rocanon'), 'nido-de-rocanon');
    expect(dificultadDe('nido-de-rocanon'), isNull);
  });
}
