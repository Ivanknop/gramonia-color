import 'package:colores_de_gramonia/engine/motor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
    expect(estadoBiomas(conPrado, {'c1', 'c2'}).map((e) => e.accesible), [true, true, true, false]);
    expect(estadoBiomas(conPrado, {'c1', 'c2', 'c3'}).last.accesible, isFalse);
    expect(estadoBiomas(conPrado, {'c1', 'c2', 'c3', 'c5'}).last.accesible, isTrue);
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
}
