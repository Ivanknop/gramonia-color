import 'dart:convert';
import 'dart:io';

import 'package:colores_de_gramonia/datos/biomas.dart';
import 'package:colores_de_gramonia/datos/historia.dart';
import 'package:colores_de_gramonia/datos/mapa.dart';
import 'package:colores_de_gramonia/datos/textos.dart';
import 'package:colores_de_gramonia/engine/dificultad.dart';
import 'package:colores_de_gramonia/engine/motor.dart';
import 'package:colores_de_gramonia/engine/niveles.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda.dart';

void main() {
  final catalogo = catalogoDeDisco();
  final catalogoArte =
      jsonDecode(File('scripts/catalogo-arte.json').readAsStringSync()) as Map<String, dynamic>;
  final soloLibre = {
    for (final c in (catalogoArte['cuadros'] as List).cast<Map<String, dynamic>>())
      if (c['solo_libre'] == true) c['id'] as String,
  };
  final recorrido = [for (final b in biomas) ...b.cuadroIds];

  void expectNumerosSobreSusRegiones(Cuadro cuadro, String donde) {
    for (final r in cuadro.regiones) {
      expect(regionEnPunto(cuadro, r.etiqueta)?.id, r.id, reason: '$donde, región ${r.id}');
    }
  }

  for (final m in catalogo.metas) {
    test('cuadro ${m.id}: tiene ilustración y cada número queda sobre su región', () {
      expect(File('assets/cuadros/${m.id}.webp').existsSync(), isTrue);
      final cuadro = catalogo.obtener(m.id)!;
      expect(cuadro.regiones.length, catalogo.cantidadRegiones[m.id]);
      expectNumerosSobreSusRegiones(cuadro, m.id);
    });
  }

  for (final m in catalogo.metas.where((m) => m.id != idTutorial)) {
    test('variantes de ${m.id}: los colores exactos y las regiones de cada dificultad', () async {
      for (final d in catalogo.dificultades) {
        final donde = '${m.id} en ${d.nombre}';
        final v = await catalogo.cargarVariante(m.id, d.id);
        expect(v, isNotNull, reason: 'falta $donde: correr scripts/convertir_arte.py variantes');
        expect(v!.paleta, hasLength(d.colores), reason: donde);
        expect({for (final r in v.regiones) r.numero}, hasLength(d.colores), reason: donde);
        // Las imágenes con poco detalle pueden quedar un poco cortas.
        expect(
          v.regiones.length,
          inInclusiveRange((d.regiones * 0.8).ceil(), d.regiones),
          reason: donde,
        );
        expectNumerosSobreSusRegiones(v, donde);
        expect(catalogo.obtener(idVariante(m.id, d.id)), same(v));
      }
    });
  }

  test('los biomas son consistentes con los cuadros', () {
    expect(validarBiomas(biomas, catalogo.ids), isEmpty);
  });

  test('cada cuadro destapa una pieza, menos el tutorial y los de solo modo libre', () {
    expect(catalogo.ids.difference(recorrido.toSet()), {idTutorial, ...soloLibre});
  });

  test('el tutorial va primero, con los colores y las regiones de catalogo-arte.json', () {
    final pedido = catalogoArte['tutorial'] as Map<String, dynamic>;
    final tutorial = catalogo.obtener(idTutorial)!;
    expect(catalogo.metas.first.id, idTutorial);
    expect(tutorial.paleta, hasLength(pedido['colores'] as int));
    final regiones = pedido['regiones'] as int;
    expect(tutorial.regiones.length, inInclusiveRange((regiones * 0.9).floor(), regiones));
  });

  test('el recorrido: los niveles no bajan, las Islas Arcoíris y al final la Isla Negra', () {
    for (var i = 1; i < biomas.length; i++) {
      expect(biomas[i].nivel, greaterThanOrEqualTo(biomas[i - 1].nivel), reason: biomas[i].id);
    }
    final islasArcoiris = lugaresDelNivel(biomas, biomas.last.nivel - 1);
    for (final isla in islasArcoiris) {
      expect(isla.tipo, TipoBioma.isla, reason: isla.id);
      expect(isla.piezas, hasLength(1), reason: '${isla.id}: una obra por isla');
    }
    expect(biomas.last.id, 'isla-negra');
  });

  test('las obras del recorrido no bajan de regiones', () {
    var anterior = 0;
    for (final id in recorrido) {
      final n = catalogo.cantidadRegiones[id]!;
      expect(n, greaterThanOrEqualTo(anterior), reason: '$id ($n regiones)');
      anterior = n;
    }
  });

  test('cada obra de la historia tiene los colores de su nivel y su orden en el catálogo', () {
    for (final (i, id) in recorrido.indexed) {
      final meta = catalogo.meta(id)!;
      expect(meta.orden, i + 1, reason: '$id está en otro orden en scripts/catalogo-arte.json');
      final nivel = piezaDeCuadro(biomas, id)!.bioma.nivel;
      expect(meta.paleta, hasLength(coloresDelNivel(nivel)), reason: '$id es del nivel $nivel');
    }
  });

  test('cada nivel, del tutorial al último, tiene su capítulo', () {
    for (final n in {nivelTutorial, for (final b in biomas) b.nivel}) {
      expect(capitulosDeNivel[n], isNotEmpty, reason: 'capítulo del nivel $n');
    }
    expect(introduccion, isNotEmpty);
  });

  test('cada bioma tiene su zona en el mapa, con lugar para todas sus piezas', () {
    for (final b in biomas) {
      final zona = zonasMapa[b.id];
      expect(zona, isNotNull, reason: 'zona de ${b.id}');
      expect(manchasDeZona(zona!, b.piezas.length), hasLength(b.piezas.length));
    }
  });

  test('la versión de la portada es la de pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(r'^version: ([\d.]+)', multiLine: true).firstMatch(pubspec)!.group(1);
    expect(Textos.version, 'v$version');
  });
}
