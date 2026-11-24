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
    expect(guardado['version'], 1);
    final (otra, _) = await nuevo(almacen.datos);
    expect(otra.de('c2')!.pintadas, ['x']);
    expect(otra.completados, {'c2'});
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
