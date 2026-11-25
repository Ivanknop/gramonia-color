/// Verifica que los datos del juego (cuadros, biomas, mapa e historia) sean válidos.
library;

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

  test('hay cuadros y cada uno tiene su ilustración', () {
    expect(catalogo.metas.length, greaterThanOrEqualTo(9));
    for (final m in catalogo.metas) {
      expect(File('assets/cuadros/${m.id}.webp').existsSync(), isTrue, reason: m.id);
    }
  });

  for (final m in catalogo.metas) {
    test('cuadro ${m.id}: se construye y cada número queda sobre su región', () {
      final cuadro = catalogo.obtener(m.id)!;
      expect(cuadro.regiones.length, catalogo.cantidadRegiones[m.id]);
      for (final r in cuadro.regiones) {
        expect(regionEnPunto(cuadro, r.etiqueta)?.id, r.id, reason: 'región ${r.id}');
      }
    });
  }

  // Variantes de dificultad: colores exactos, regiones cerca del objetivo (las
  // imágenes con poco detalle pueden quedar un poco cortas) y cada número
  // sobre su región.
  test('hay diez dificultades', () => expect(catalogo.dificultades, hasLength(10)));
  // El tutorial no tiene variantes: se juega solo desde la historia.
  for (final m in catalogo.metas.where((m) => m.id != idTutorial)) {
    test('variantes de ${m.id}: colores y regiones de cada dificultad', () async {
      for (final d in catalogo.dificultades) {
        final v = await catalogo.cargarVariante(m.id, d.id);
        final donde = '${m.id} en ${d.nombre}';
        expect(v, isNotNull, reason: 'falta $donde: correr scripts/convertir_arte.py variantes');
        expect(v!.paleta, hasLength(d.colores), reason: donde);
        expect(
          v.regiones.length,
          inInclusiveRange((d.regiones * 0.8).ceil(), d.regiones),
          reason: donde,
        );
        expect({for (final r in v.regiones) r.numero}, hasLength(d.colores), reason: donde);
        for (final r in v.regiones) {
          expect(regionEnPunto(v, r.etiqueta)?.id, r.id, reason: '$donde, región ${r.id}');
        }
        expect(catalogo.obtener(idVariante(m.id, d.id)), same(v));
      }
    });
  }

  test('los biomas son consistentes con los cuadros', () {
    expect(validarBiomas(biomas, catalogo.ids), isEmpty);
  });

  // Los de solo modo libre (scripts/catalogo-arte.json) no son de la historia.
  final soloLibre = {
    for (final c
        in (jsonDecode(File('scripts/catalogo-arte.json').readAsStringSync())
                as Map<String, dynamic>)['cuadros']
            as List)
      if ((c as Map<String, dynamic>)['solo_libre'] == true) c['id'] as String,
  };

  test('cada cuadro destapa una pieza (menos el tutorial y los de solo modo libre)', () {
    final usados = {for (final b in biomas) ...b.cuadroIds};
    expect(soloLibre, hasLength(6));
    expect(catalogo.ids.difference(usados), {idTutorial, ...soloLibre});
  });

  test('tutorial: el Árbol Mágico con 5 colores y unas 20 partes, primero en el catálogo', () {
    final tutorial = catalogo.obtener(idTutorial)!;
    expect(tutorial.paleta, hasLength(5));
    expect(tutorial.regiones.length, inInclusiveRange(18, 20));
    expect(catalogo.metas.first.id, idTutorial);
  });

  test('están los lugares pedidos, en orden y con su nivel', () {
    expect(
      [for (final b in biomas.take(9)) (b.nombre, b.nivel)],
      [
        ('Árbol Mágico', 1),
        ('Bosque Mágico', 2),
        ('Reino Animal', 3),
        ('Tierra de las Caperucitas', 4),
        ('Prado de las Hadas', 4),
        ('Montaña Dragón', 5),
        ('Reino Helado', 5),
        ('La Ciudad', 6),
        ('La Costa', 6),
      ],
    );
    final islas = biomas.skip(9).take(7);
    expect(islas.where((b) => b.tipo == TipoBioma.isla && b.nivel == 7), hasLength(7));
    expect([for (final b in biomas.skip(16)) (b.nombre, b.nivel)], [('Isla Negra', 8)]);
    // Los niveles nunca bajan a lo largo del recorrido.
    for (var i = 1; i < biomas.length; i++) {
      expect(biomas[i].nivel, greaterThanOrEqualTo(biomas[i - 1].nivel));
    }
  });

  test('dificultad creciente: más regiones por obra; una obra por isla', () {
    // La cantidad de obras depende de cada lugar (el Reino Helado tiene una o
    // dos; las islas, una cada una).
    expect(
      [
        for (final b in biomas)
          if (b.nivel == 7) b.piezas.length,
      ],
      List.filled(7, 1),
      reason: 'Islas Arcoíris: una obra por isla',
    );
    // Regiones: cada obra tiene al menos tantas como la anterior en el recorrido.
    var anterior = 0;
    for (final b in biomas) {
      for (final id in b.cuadroIds) {
        final n = catalogo.cantidadRegiones[id]!;
        expect(n, greaterThanOrEqualTo(anterior), reason: '$id ($n regiones)');
        anterior = n;
      }
    }
  });

  test('niveles: cada obra de la historia tiene los colores de su nivel', () {
    final recorrido = cuadrosDelRecorrido(biomas);
    for (final (i, id) in recorrido.indexed) {
      final meta = catalogo.meta(id)!;
      // El conversor calcula el nivel con el orden del catálogo: tiene que ser el del recorrido.
      expect(meta.orden, i + 1, reason: '$id está en otro orden en scripts/catalogo-arte.json');
      final nivel = nivelDeObra(biomas, id)!;
      expect(meta.paleta, hasLength(coloresDelNivel(nivel)), reason: '$id es del nivel $nivel');
    }
  });

  test('cada nivel (del tutorial al 8) tiene su capítulo', () {
    final niveles = {nivelTutorial, for (final b in biomas) b.nivel};
    expect(niveles, {for (var n = 0; n <= 8; n++) n});
    for (final n in niveles) {
      expect(capitulosDeNivel[n], isNotEmpty, reason: 'capítulo del nivel $n');
    }
  });

  test('la versión de la portada es la de pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(r'^version: ([\d.]+)', multiLine: true).firstMatch(pubspec)!.group(1);
    expect(Textos.version, 'v$version');
  });

  test('cada bioma tiene su zona en el mapa', () {
    for (final b in biomas) {
      expect(zonasMapa.containsKey(b.id), isTrue, reason: 'zona de ${b.id}');
      expect(manchasDeZona(zonasMapa[b.id]!, b.piezas.length), hasLength(b.piezas.length));
    }
    expect(introduccion, isNotEmpty);
  });
}
