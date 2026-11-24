import 'package:colores_de_gramonia/engine/niveles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('primeros niveles (obras / colores): 2/10, 3/15, 4/22, 6/33, 9/49', () {
    expect([for (var n = 1; n <= 5; n++) obrasDelNivel(n)], [2, 3, 4, 6, 9]);
    expect([for (var n = 1; n <= 5; n++) coloresDelNivel(n)], [10, 15, 22, 33, 49]);
  });

  test('cada valor es el anterior más la mitad (redondeada para abajo)', () {
    for (var n = 2; n <= 12; n++) {
      final previo = coloresDelNivel(n - 1);
      expect(coloresDelNivel(n), previo + previo ~/ 2);
    }
  });

  test('los niveles empiezan en 1', () {
    expect(() => obrasDelNivel(0), throwsArgumentError);
  });

  test('nivel de cada obra según su lugar en el recorrido', () {
    // Nivel 1: obras 0-1; nivel 2: 2-4; nivel 3: 5-8; nivel 4: 9-14; nivel 5: 15-23.
    expect(
      [for (var i = 0; i < 16; i++) nivelDeObra(i)],
      [
        1, 1, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 5, //
      ],
    );
    expect(nivelDeObra(23), 5);
    expect(nivelDeObra(24), 6);
  });

  test('nivel actual según las obras completadas', () {
    expect(nivelActual(0), (nivel: 1, hechas: 0, necesarias: 2));
    expect(nivelActual(1), (nivel: 1, hechas: 1, necesarias: 2));
    expect(nivelActual(2), (nivel: 2, hechas: 0, necesarias: 3));
    expect(nivelActual(6), (nivel: 3, hechas: 1, necesarias: 4));
    expect(nivelActual(9), (nivel: 4, hechas: 0, necesarias: 6));
  });
}
