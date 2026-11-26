import 'package:colores_de_gramonia/engine/niveles.dart';
import 'package:colores_de_gramonia/engine/progresion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('colores de cada nivel (×1,5): 10, 15, 22, 33, 49, 73, 109, 163', () {
    expect([for (var n = 1; n <= 8; n++) coloresDelNivel(n)], [10, 15, 22, 33, 49, 73, 109, 163]);
    for (var n = 2; n <= 12; n++) {
      final previo = coloresDelNivel(n - 1);
      expect(coloresDelNivel(n), previo + previo ~/ 2);
    }
  });

  test('las obras empiezan en el nivel 1 (el 0 es el tutorial)', () {
    expect(() => coloresDelNivel(nivelTutorial), throwsArgumentError);
  });

  Bioma lugar(String id, int nivel, List<String?> obras) => Bioma(
    id: id,
    nombre: id,
    descripcion: '',
    color: 0,
    nivel: nivel,
    piezas: [for (final (i, c) in obras.indexed) Pieza(id: '$id-$i', cuadroId: c)],
  );

  final biomas = [
    lugar('arbol', 1, ['a1', 'a2']),
    lugar('bosque', 2, ['b1']),
    lugar('prado', 2, ['p1', null]),
    lugar('islas', 3, [null, null]),
  ];

  test('lugares de cada nivel', () {
    expect(lugaresDelNivel(biomas, 2).map((b) => b.id), ['bosque', 'prado']);
  });

  test('nivel 0 hasta pasar el tutorial', () {
    expect(nivelActual(biomas, {}, tutorialPasado: false).nivel, 0);
    expect(nivelActual(biomas, {}, tutorialPasado: true), (nivel: 1, hechas: 0, necesarias: 2));
  });

  test('el nivel cuenta las obras de todos sus lugares', () {
    expect(nivelActual(biomas, {'a1', 'a2'}, tutorialPasado: true), (
      nivel: 2,
      hechas: 0,
      necesarias: 2,
    ));
    expect(nivelActual(biomas, {'a1', 'a2', 'p1'}, tutorialPasado: true), (
      nivel: 2,
      hechas: 1,
      necesarias: 2,
    ));
  });

  test('sin obras pendientes queda en el último nivel con obras, completo', () {
    expect(nivelActual(biomas, {'a1', 'a2', 'b1', 'p1'}, tutorialPasado: true), (
      nivel: 2,
      hechas: 2,
      necesarias: 2,
    ));
  });

  test('niveles subidos al completar obras', () {
    expect(nivelesSubidos(biomas, {}, {'a1'}), 0);
    expect(nivelesSubidos(biomas, {'a1'}, {'a1', 'a2'}), 1);
    expect(nivelesSubidos(biomas, {'a1', 'a2', 'b1'}, {'a1', 'a2', 'b1', 'p1'}), 0);
  });

  test('niveles completos: en orden, sin contar los que no tienen obras', () {
    expect(nivelesCompletos(biomas, {}), isEmpty);
    expect(nivelesCompletos(biomas, {'a1', 'a2'}), [1]);
    expect(nivelesCompletos(biomas, {'b1', 'p1'}), isEmpty); // falta el nivel 1
    expect(nivelesCompletos(biomas, {'a1', 'a2', 'b1', 'p1'}), [1, 2]);
    expect(nivelesQueSeCompletan(biomas, {'a1', 'a2', 'b1'}, {'a1', 'a2', 'b1', 'p1'}), [2]);
    expect(nivelesQueSeCompletan(biomas, {'a1'}, {'a1', 'b1'}), isEmpty);
  });

  test('portada: se ven a color los lugares de los niveles completos (con obras)', () {
    final conVacio = [
      ...biomas,
      lugar('vacio', 2, [null]),
    ];
    expect(lugaresRecuperados(conVacio, {'a1'}), isEmpty);
    expect(lugaresRecuperados(conVacio, {'a1', 'a2'}).map((b) => b.id), ['arbol']);
    // Un lugar sin obras no se colorea aunque su nivel esté completo.
    expect(lugaresRecuperados(conVacio, {'a1', 'a2', 'b1', 'p1'}).map((b) => b.id), [
      'arbol',
      'bosque',
      'prado',
    ]);
  });
}
