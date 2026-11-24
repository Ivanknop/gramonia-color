/// Catálogo de cuadros: lee `assets/cuadros/<id>.json` + `<id>.svg`.
///
/// Los metadatos y el texto del SVG se cargan al iniciar (son livianos); la
/// geometría de cada cuadro se arma la primera vez que se pide y queda en
/// memoria.
library;

import 'dart:convert';

import 'package:flutter/services.dart';

import '../engine/motor.dart';

class Catalogo {
  Catalogo._(this.metas, this._svgs)
    : cantidadRegiones = {
        for (final e in _svgs.entries) e.key: RegExp(r'<path\b').allMatches(e.value).length,
      };

  /// Arma el catálogo a partir de pares (json, svg) ya leídos.
  factory Catalogo.desdeTextos(Iterable<({String json, String svg})> cuadros) {
    final metas = <MetaCuadro>[];
    final svgs = <String, String>{};
    for (final c in cuadros) {
      final meta = MetaCuadro.desdeJson(jsonDecode(c.json) as Map<String, dynamic>);
      metas.add(meta);
      svgs[meta.id] = c.svg;
    }
    metas.sort((a, b) {
      final porOrden = a.orden.compareTo(b.orden);
      return porOrden != 0 ? porOrden : a.id.compareTo(b.id);
    });
    return Catalogo._(metas, svgs);
  }

  static const carpeta = 'assets/cuadros/';

  /// Carga todos los cuadros declarados como assets.
  static Future<Catalogo> cargar(AssetBundle bundle) async {
    final manifiesto = await AssetManifest.loadFromAssetBundle(bundle);
    final jsons = manifiesto
        .listAssets()
        .where((a) => a.startsWith(carpeta) && a.endsWith('.json'))
        .toList();
    final cuadros = await Future.wait(
      jsons.map((j) async {
        final svg = '${j.substring(0, j.length - '.json'.length)}.svg';
        return (json: await bundle.loadString(j), svg: await bundle.loadString(svg));
      }),
    );
    return Catalogo.desdeTextos(cuadros);
  }

  /// Metadatos en el orden de la galería.
  final List<MetaCuadro> metas;
  final Map<String, String> _svgs;

  /// Cantidad de regiones de cada cuadro (sin armar la geometría).
  final Map<String, int> cantidadRegiones;

  final Map<String, Cuadro> _cache = {};

  Set<String> get ids => {for (final m in metas) m.id};

  MetaCuadro? meta(String id) {
    for (final m in metas) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Cuadro listo para jugar (la geometría se arma una sola vez).
  Cuadro? obtener(String id) {
    final enCache = _cache[id];
    if (enCache != null) return enCache;
    final m = meta(id);
    final svg = _svgs[id];
    if (m == null || svg == null) return null;
    return _cache[id] = construirCuadro(m, svg);
  }
}
