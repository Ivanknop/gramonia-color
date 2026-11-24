import 'dart:convert';

import 'package:colores_de_gramonia/engine/genero.dart';
import 'package:colores_de_gramonia/engine/plumas.dart';
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

  test('completar un cuadro', () async {
    final (p, _) = await nuevo();
    p.pintarRegion('c1', 'a');
    p.marcarCompletado('c1');
    expect(p.completados, {'c1'});
  });

  test('el progreso se guarda y se vuelve a cargar', () async {
    final (p, almacen) = await nuevo();
    p.pintarRegion('c2', 'x');
    p.marcarCompletado('c2');
    await p.guardado;
    final guardado = jsonDecode(almacen.datos!) as Map<String, dynamic>;
    expect(guardado['version'], 5);
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

  test('tienda: comprar con plumas y usar del inventario', () async {
    final (p, almacen) = await nuevo();
    p.sumarPlumas(14);
    expect(p.comprar(Herramienta.bomba), isTrue);
    expect(p.comprar(Herramienta.bomba), isFalse); // quedan 4
    expect(p.comprar(Herramienta.lupa), isFalse);
    p.sumarPlumas(1);
    expect(p.comprar(Herramienta.lupa), isTrue);
    expect((p.plumas, p.cantidad(Herramienta.lupa), p.cantidad(Herramienta.bomba)), (0, 1, 1));
    expect(p.usar(Herramienta.lupa), isTrue);
    expect(p.usar(Herramienta.lupa), isFalse);
    await p.guardado;
    final (otra, _) = await nuevo(almacen.datos);
    expect((otra.cantidad(Herramienta.lupa), otra.cantidad(Herramienta.bomba)), (0, 1));
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

  test('migra un guardado v2 (sin género): queda sin elegir y habla en neutro', () async {
    const v2 =
        '{"version":2,"cuadros":{"c1":{"pintadas":["a"],"completadoEn":4}},'
        '"plumas":15,"introVista":true,"capitulosVistos":["arbol-magico"]}';
    final (p, _) = await nuevo(v2);
    expect((p.plumas, p.introVista), (15, true));
    expect(p.completados, {'c1'});
    expect(p.genero, isNull);
    expect(p.texto('{Listo|Lista|Todo listo}'), 'Todo listo');
  });

  test('el género elegido se guarda y elige la variante de los textos', () async {
    final (p, almacen) = await nuevo();
    p.elegirGenero(Genero.chica);
    expect(p.texto('¡{Bienvenido|Bienvenida|Qué alegría tenerte}!'), '¡Bienvenida!');
    await p.guardado;
    final (otra, _) = await nuevo(almacen.datos);
    expect(otra.genero, Genero.chica);
  });

  test('migra un guardado v3: las terminadas quedan desbloqueadas', () async {
    const v3 =
        '{"version":3,"cuadros":{"c1":{"pintadas":["a"],"completadoEn":4},'
        '"c2":{"pintadas":["b"]}},"genero":"chico"}';
    final (p, _) = await nuevo(v3);
    expect(p.completados, {'c1'});
    expect(p.genero, Genero.chico);
    p.rehacer('c1', 'facil');
    expect(p.completados, {'c1'}); // rehacer no tapa lo ganado
  });

  test(
    'rehacer una obra de la historia: en blanco, en otra dificultad y sin perder el desbloqueo',
    () async {
      final (p, almacen) = await nuevo();
      p.pintarRegiones('c1', ['a', 'b']);
      p.marcarCompletado('c1');
      ahora = 77;
      expect(p.rehacer('c1', 'dificil'), 'c1');
      final rehecha = p.de('c1')!;
      expect(rehecha.pintadas, isEmpty);
      expect((rehecha.terminado, rehecha.dificultad), (false, 'dificil'));
      expect(p.completados, {'c1'});
      // Se puede volver a terminar, y rehacer otra vez en otra dificultad.
      p.pintarRegion('c1', 'r9');
      p.marcarCompletado('c1');
      expect(p.de('c1')!.dificultad, 'dificil');
      p.rehacer('c1', 'super-facil');
      expect(p.de('c1')!.dificultad, 'super-facil');
      await p.guardado;
      final (otra, _) = await nuevo(almacen.datos);
      expect(otra.de('c1')!.dificultad, 'super-facil');
      expect(otra.completados, {'c1'});
    },
  );

  test('rehacer una obra del modo libre pasa a la variante de la dificultad nueva', () async {
    final (p, _) = await nuevo();
    p.pintarRegion('c1--facil', 'a');
    p.marcarCompletado('c1--facil');
    expect(p.completados.contains('c1'), isFalse); // el modo libre no desbloquea
    expect(p.rehacer('c1--facil', 'divino'), 'c1--divino');
    expect(p.de('c1--facil'), isNull);
    expect(p.de('c1--divino'), isNull);
  });

  test('migra un guardado v4: sin lupas ni bombas, con sus plumas', () async {
    const v4 = '{"version":4,"cuadros":{},"plumas":40,"desbloqueadas":["c1"]}';
    final (p, _) = await nuevo(v4);
    expect((p.plumas, p.cantidad(Herramienta.lupa), p.cantidad(Herramienta.bomba)), (40, 0, 0));
    expect(p.completados, {'c1'});
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

    test('las variantes del modo libre y las obras rehechas en blanco también cuentan', () {
      final obras = clasificarObras({
        'a--facil': const ProgresoCuadro(pintadas: ['r1'], actualizadoEn: 1),
        'b': const ProgresoCuadro(dificultad: 'facil', actualizadoEn: 2),
        'x--facil': const ProgresoCuadro(pintadas: ['r1'], actualizadoEn: 3),
      }, existentes);
      expect(obras.enProgreso.map((o) => o.cuadroId), ['b', 'a--facil']);
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
