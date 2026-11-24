/// Verifica que los datos del juego (cuadros, biomas, mapa e historia) sean válidos.
library;

import 'dart:io';

import 'package:colores_de_gramonia/datos/biomas.dart';
import 'package:colores_de_gramonia/datos/historia.dart';
import 'package:colores_de_gramonia/datos/mapa.dart';
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
  for (final m in catalogo.metas) {
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

  test('cada cuadro destapa una pieza', () {
    final usados = {for (final b in biomas) ...b.cuadroIds};
    expect(catalogo.ids.difference(usados), isEmpty);
  });

  test('están los lugares pedidos, en orden, con las siete Islas Arcoíris al final', () {
    expect(biomas.take(9).map((b) => b.nombre), [
      'Árbol Mágico',
      'Bosque Mágico',
      'Reino Animal',
      'Tierra de las Caperucitas',
      'Montaña Dragón',
      'Reino Helado',
      'Prado de las Hadas',
      'La Ciudad',
      'La Costa',
    ]);
    expect(biomas.skip(9).where((b) => b.tipo == TipoBioma.isla), hasLength(7));
  });

  test('dificultad creciente: más obras por lugar y más regiones por obra', () {
    for (var i = 1; i < biomas.length; i++) {
      expect(
        biomas[i].piezas.length,
        greaterThanOrEqualTo(biomas[i - 1].piezas.length),
        reason: '${biomas[i].id} tiene menos obras que ${biomas[i - 1].id}',
      );
    }
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
      expect(meta.paleta, hasLength(coloresDelNivel(nivelDeObra(i))), reason: id);
    }
  });

  test('cada bioma tiene su zona en el mapa y su capítulo en la historia', () {
    for (final b in biomas) {
      expect(zonasMapa.containsKey(b.id), isTrue, reason: 'zona de ${b.id}');
      expect(capitulos.containsKey(b.id), isTrue, reason: 'capítulo de ${b.id}');
      expect(manchasDeZona(zonasMapa[b.id]!, b.piezas.length), hasLength(b.piezas.length));
    }
    expect(introduccion, isNotEmpty);
  });
}
