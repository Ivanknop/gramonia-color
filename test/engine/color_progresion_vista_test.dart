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
    const arbol = Bioma(
      id: 'arbol',
      nombre: 'Árbol',
      descripcion: '',
      color: 0,
      piezas: [
        Pieza(id: 'a', cuadroId: 'c1'),
        Pieza(id: 'b', cuadroId: 'c2'),
      ],
    );
    const bosque = Bioma(
      id: 'bosque',
      nombre: 'Bosque',
      descripcion: '',
      color: 0,
      nivel: 2,
      piezas: [
        Pieza(id: 'c', cuadroId: 'c3'),
        Pieza(id: 'd'),
      ], // d: próximamente
    );
    const ciudad = Bioma(
      id: 'ciudad',
      nombre: 'Ciudad',
      descripcion: '',
      color: 0,
      nivel: 3,
      piezas: [Pieza(id: 'e', cuadroId: 'c4')],
    );
    const todos = [arbol, bosque, ciudad];

    test('al principio solo se puede jugar el primer bioma', () {
      expect(estadoBiomas(todos, {}).map((e) => e.accesible), [true, false, false]);
    });

    test('completar un bioma habilita el siguiente', () {
      final e = estadoBiomas(todos, {'c1', 'c2'});
      expect(e[0].completo, isTrue);
      expect(e[0].reveladas, {'a', 'b'});
      expect(e.map((x) => x.accesible), [true, true, false]);
    });

    test('las piezas "próximamente" no traban el avance, pero el bioma no queda completo', () {
      final e = estadoBiomas(todos, {'c1', 'c2', 'c3'});
      expect(e[1].completoDisponible, isTrue);
      expect(e[1].completo, isFalse);
      expect(e[2].accesible, isTrue);
    });

    test('los lugares de un mismo nivel se abren juntos y el siguiente espera a todos', () {
      const prado = Bioma(
        id: 'prado',
        nombre: 'Prado',
        descripcion: '',
        color: 0,
        nivel: 2,
        piezas: [Pieza(id: 'p', cuadroId: 'c5')],
      );
      const conPrado = [arbol, bosque, prado, ciudad];
      expect(estadoBiomas(conPrado, {'c1', 'c2'}).map((e) => e.accesible), [
        true,
        true,
        true,
        false,
      ]);
      expect(estadoBiomas(conPrado, {'c1', 'c2', 'c3'}).last.accesible, isFalse);
      expect(estadoBiomas(conPrado, {'c1', 'c2', 'c3', 'c5'}).last.accesible, isTrue);
    });

    test('biomasQueSeCompletan', () {
      expect(biomasQueSeCompletan(todos, {'c1'}, 'c2').map((b) => b.id), ['arbol']);
      expect(biomasQueSeCompletan(todos, {}, 'c1'), isEmpty);
      expect(biomasQueSeCompletan(todos, {'c1', 'c2'}, 'c3').map((b) => b.id), ['bosque']);
    });

    test('modo libre: los coloreados en la historia y los que no son de la historia', () {
      const catalogo = ['c1', 'c2', 'c3', 'c4', 'suelto', idTutorial];
      expect(cuadrosLibres(todos, {}, catalogo), ['suelto']);
      expect(cuadrosLibres(todos, {'c1'}, catalogo), ['c1', 'suelto']);
      expect(cuadrosLibres(todos, {'c1', 'c2', 'c3'}, catalogo), ['c1', 'c2', 'c3', 'suelto']);
    });

    test('piezaDeCuadro', () {
      expect(piezaDeCuadro(todos, 'c3')?.bioma.id, 'bosque');
      expect(piezaDeCuadro(todos, 'nada'), isNull);
    });

    test('validarBiomas detecta problemas', () {
      expect(validarBiomas(todos, ['c1', 'c2', 'c3', 'c4']), isEmpty);
      const roto = Bioma(
        id: 'r',
        nombre: 'R',
        descripcion: '',
        color: 0,
        piezas: [
          Pieza(id: 'a', cuadroId: 'c1'),
          Pieza(id: 'a', cuadroId: 'c1'),
          Pieza(id: 'z', cuadroId: 'zz'),
        ],
      );
      final todo = validarBiomas([roto], ['c1']).join('\n');
      for (final esperado in ['Pieza repetida', 'dos piezas', 'inexistente']) {
        expect(todo, contains(esperado));
      }
    });
  });

  group('plumas', () {
    test('recompensa diaria una vez por día calendario', () {
      final hoy = DateTime(2026, 11, 24, 9);
      expect(diaDe(hoy), '2026-11-24');
      expect(tocaRecompensaDiaria(null, hoy), isTrue);
      expect(tocaRecompensaDiaria('2026-11-24', DateTime(2026, 11, 24, 23)), isFalse);
      expect(tocaRecompensaDiaria('2026-11-24', DateTime(2026, 11, 25, 0, 1)), isTrue);
    });

    test('reglas: 5 por día, 3 por cuadro, 10 por nivel', () {
      expect((ReglasPlumas.porDia, ReglasPlumas.porObra, ReglasPlumas.porNivel), (5, 3, 10));
      expect(plumasPorTerminar(), 3);
      expect(plumasPorTerminar(nivelesSubidos: 1), 13);
    });

    test('tienda: lupa 5 plumas, bomba 10', () {
      expect((Herramienta.lupa.precio, Herramienta.bomba.precio), (5, 10));
      expect(puedeComprar(4, Herramienta.lupa), isFalse);
      expect(puedeComprar(5, Herramienta.lupa), isTrue);
      expect(puedeComprar(9, Herramienta.bomba), isFalse);
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

  group('animación del relleno', () {
    test('radioParaCubrir llega a la esquina más lejana', () {
      expect(radioParaCubrir(const Caja(0, 0, 3, 4), const Punto(0, 0)), closeTo(5, 1e-9));
      expect(radioParaCubrir(const Caja(0, 0, 10, 10), const Punto(5, 5)), closeTo(7.0711, 1e-4));
    });

    test('avanceAnimacion va de 0 a 1 con salida suave', () {
      const d = Duration(milliseconds: 100);
      expect(avanceAnimacion(Duration.zero, const Duration(milliseconds: 10), d), 0);
      final mitad = avanceAnimacion(const Duration(milliseconds: 50), Duration.zero, d);
      expect(mitad, greaterThan(0.5)); // ease-out: a mitad de tiempo ya pasó la mitad
      expect(avanceAnimacion(const Duration(milliseconds: 200), Duration.zero, d), 1);
    });
  });
}
