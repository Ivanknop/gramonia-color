import 'package:colores_de_gramonia/engine/motor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('color', () {
    test('luminancia de blanco y negro', () {
      expect(luminancia('#FFFFFF'), closeTo(1, 1e-9));
      expect(luminancia('#000000'), closeTo(0, 1e-9));
    });

    test('el gris sin color siempre es claro y es gris', () {
      for (final hex in ['#000000', '#FFFFFF', '#674EA7', '#FFD966']) {
        final g = grisSinColor(hex);
        final r = (g >> 16) & 255, v = (g >> 8) & 255, a = g & 255;
        expect((r, v), (a, a));
        expect(r, greaterThan(0.6 * 255));
      }
      expect(grisSinColor('#222222') & 255, lessThan(grisSinColor('#EEEEEE') & 255));
    });

    test('textoSobre elige el contraste', () {
      expect(textoSobre('#FFFFFF'), 0xFF000000);
      expect(textoSobre('#222222'), 0xFFFFFFFF);
      expect(argbDeHex('#12AB34'), 0xFF12AB34);
    });
  });

  group('progresión', () {
    const bosque = Bioma(
      id: 'bosque',
      nombre: 'Bosque',
      descripcion: '',
      color: 0xFF00FF00,
      filas: 1,
      columnas: 2,
      piezas: [
        Pieza(id: 'a', cuadroId: 'c1', fila: 0, columna: 0),
        Pieza(id: 'b', cuadroId: 'c2', fila: 0, columna: 1),
      ],
    );

    test('se desbloquea al destapar todas las piezas', () {
      expect(estadoBioma(bosque, {'c1'}).desbloqueado, isFalse);
      final e = estadoBioma(bosque, {'c1', 'c2'});
      expect(e.desbloqueado, isTrue);
      expect(e.reveladas, {'a', 'b'});
    });

    test('con celdas sin pieza asignada no se desbloquea', () {
      const incompleto = Bioma(
        id: 'x',
        nombre: 'X',
        descripcion: '',
        color: 0,
        filas: 1,
        columnas: 3,
        piezas: [Pieza(id: 'a', cuadroId: 'c1', fila: 0, columna: 0)],
      );
      final e = estadoBioma(incompleto, {'c1'});
      expect((e.total, e.desbloqueado), (3, false));
    });

    test('piezaDeCuadro', () {
      expect(piezaDeCuadro([bosque], 'c2')?.pieza.id, 'b');
      expect(piezaDeCuadro([bosque], 'nada'), isNull);
    });

    test('validarBiomas detecta problemas', () {
      expect(validarBiomas([bosque], ['c1', 'c2']), isEmpty);
      const roto = Bioma(
        id: 'r',
        nombre: 'R',
        descripcion: '',
        color: 0,
        filas: 1,
        columnas: 2,
        piezas: [
          Pieza(id: 'a', cuadroId: 'c1', fila: 0, columna: 0),
          Pieza(id: 'b', cuadroId: 'c1', fila: 0, columna: 0),
          Pieza(id: 'c', cuadroId: 'zz', fila: 3, columna: 0),
        ],
      );
      final todo = validarBiomas([roto], ['c1']).join('\n');
      for (final esperado in [
        'dos piezas',
        'celda ya usada',
        'inexistente',
        'fuera de la grilla',
      ]) {
        expect(todo, contains(esperado));
      }
    });
  });

  group('vista', () {
    test('tamanoNumero se acota entre 1.2 y 18', () {
      expect(tamanoNumero(0.5), 1.2);
      expect(tamanoNumero(10), closeTo(11, 1e-9));
      expect(tamanoNumero(100), 18);
    });

    test('escalaMaxima permite leer y tocar lo más chico, entre 4x y 16x', () {
      expect(escalaMaxima([20, 30], 1), 4); // ya se ve bien: mínimo 4x
      expect(escalaMaxima([0.8], 2), closeTo(10 / 1.6, 1e-9)); // radio 1.6 pt → 6.25x
      expect(escalaMaxima([0.5], 0.1), 16); // tope
    });
  });
}
