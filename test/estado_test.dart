import 'dart:convert';

import 'package:colores_de_gramonia/estado/obras.dart';
import 'package:colores_de_gramonia/estado/progreso.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var ahora = 1000;
  Future<(Progreso, AlmacenEnMemoria)> nuevo([String? datos]) async {
    final almacen = AlmacenEnMemoria(datos);
    return (await Progreso.cargar(almacen, reloj: () => ahora), almacen);
  }

  test('pintar es idempotente, respeta el orden y guarda la fecha', () async {
    final (p, _) = await nuevo();
    ahora = 5;
    p.pintarRegion('c1', 'a');
    p.pintarRegion('c1', 'b');
    p.pintarRegion('c1', 'a');
    expect(p.de('c1')!.pintadas, ['a', 'b']);
    expect(p.de('c1')!.actualizadoEn, 5);
  });

  test('completar y reiniciar un cuadro', () async {
    final (p, _) = await nuevo();
    p.pintarRegion('c1', 'a');
    p.marcarCompletado('c1');
    expect(p.completados, {'c1'});
    p.reiniciarCuadro('c1');
    expect(p.de('c1'), isNull);
  });

  test('el progreso se guarda y se vuelve a cargar', () async {
    final (p, almacen) = await nuevo();
    p.pintarRegion('c2', 'x');
    p.marcarCompletado('c2');
    await p.guardado;
    final guardado = jsonDecode(almacen.datos!) as Map<String, dynamic>;
    expect(guardado['version'], 2);
    final (otra, _) = await nuevo(almacen.datos);
    expect(otra.de('c2')!.pintadas, ['x']);
    expect(otra.completados, {'c2'});
  });

  test('pintar varias regiones de una vez (bomba)', () async {
    final (p, _) = await nuevo();
    p.pintarRegiones('c1', ['a', 'b', 'a']);
    p.pintarRegiones('c1', ['b', 'c']);
    expect(p.de('c1')!.pintadas, ['a', 'b', 'c']);
  });

  test('marcarCompletado avisa si ya estaba terminado', () async {
    final (p, _) = await nuevo();
    expect(p.marcarCompletado('c1'), isTrue);
    expect(p.marcarCompletado('c1'), isFalse);
  });

  test('plumas: recompensa diaria una sola vez por día', () async {
    ahora = DateTime(2026, 11, 24, 10).millisecondsSinceEpoch;
    final (p, almacen) = await nuevo();
    expect(p.reclamarRecompensaDiaria(), 5);
    expect(p.reclamarRecompensaDiaria(), 0);
    expect(p.plumas, 5);
    await p.guardado;
    ahora = DateTime(2026, 11, 25, 8).millisecondsSinceEpoch;
    final (otra, _) = await nuevo(almacen.datos);
    expect(otra.reclamarRecompensaDiaria(), 5);
    expect(otra.plumas, 10);
  });

  test('plumas: sumar y gastar (gratis mientras herramientasGratis)', () async {
    final (p, _) = await nuevo();
    p.sumarPlumas(30);
    expect(p.gastarPlumas(5), isTrue);
    expect(p.plumas, 30); // por ahora las herramientas no cobran
  });

  test('historia: intro y capítulos vistos se guardan', () async {
    final (p, almacen) = await nuevo();
    p.marcarIntroVista();
    p.marcarCapituloVisto('arbol-magico');
    await p.guardado;
    final (otra, _) = await nuevo(almacen.datos);
    expect(otra.introVista, isTrue);
    expect(otra.capitulosVistos, {'arbol-magico'});
  });

  test('migra un guardado v1 (sin plumas ni historia)', () async {
    const v1 = '{"version":1,"cuadros":{"c1":{"pintadas":["a"],"actualizadoEn":3}}}';
    final (p, _) = await nuevo(v1);
    expect(p.de('c1')!.pintadas, ['a']);
    expect((p.plumas, p.introVista), (0, false));
  });

  test('datos corruptos no impiden jugar', () async {
    final (p, _) = await nuevo('{esto no es json');
    expect(p.cuadros, isEmpty);
  });

  group('clasificarObras', () {
    const existentes = {'a', 'b', 'c', 'd'};

    test('separa en progreso y terminadas, la más reciente primero', () {
      final obras = clasificarObras({
        'a': const ProgresoCuadro(pintadas: ['r1'], actualizadoEn: 100),
        'b': const ProgresoCuadro(pintadas: ['r1', 'r2'], actualizadoEn: 300),
        'c': const ProgresoCuadro(pintadas: ['r1'], actualizadoEn: 50, completadoEn: 60),
        'd': const ProgresoCuadro(pintadas: ['r1'], actualizadoEn: 400, completadoEn: 500),
      }, existentes);
      expect(obras.enProgreso.map((o) => o.cuadroId), ['b', 'a']);
      expect(obras.terminadas.map((o) => o.cuadroId), ['d', 'c']);
    });

    test('ignora cuadros sin pintar y cuadros que ya no existen', () {
      final obras = clasificarObras({
        'a': const ProgresoCuadro(),
        'viejo': const ProgresoCuadro(pintadas: ['r1'], actualizadoEn: 1),
      }, existentes);
      expect(obras.enProgreso, isEmpty);
      expect(obras.terminadas, isEmpty);
    });
  });
}
