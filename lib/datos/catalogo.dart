/// Catálogo de cuadros: lee `assets/cuadros/<id>.json` + `<id>.svg`.
///
/// Los metadatos y el texto del SVG se cargan al iniciar (son livianos); la
/// geometría de cada cuadro se arma la primera vez que se pide y queda en
/// memoria.
library;

import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../engine/motor.dart';

/// Carga y decodifica una imagen de assets (null si no se puede).
typedef CargadorImagen = Future<ui.Image?> Function(String asset);

class Catalogo {
  Catalogo._(this.metas, this._svgs, this._conImagen, this._cargarImagen)
    : cantidadRegiones = {
        for (final e in _svgs.entries) e.key: RegExp(r'<path\b').allMatches(e.value).length,
      };

  /// Arma el catálogo a partir de pares (json, svg) ya leídos.
  ///
  /// [conImagen]: ids que tienen ilustración (`<id>.webp`); [cargarImagen] la
  /// decodifica (sin cargador, los cuadros se dibujan con colores planos).
  factory Catalogo.desdeTextos(
    Iterable<({String json, String svg})> cuadros, {
    Set<String> conImagen = const {},
    CargadorImagen? cargarImagen,
  }) {
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
    return Catalogo._(metas, svgs, conImagen, cargarImagen);
  }

  static const carpeta = 'assets/cuadros/';

  /// Carga todos los cuadros declarados como assets.
  static Future<Catalogo> cargar(AssetBundle bundle) async {
    final manifiesto = await AssetManifest.loadFromAssetBundle(bundle);
    final assets = manifiesto.listAssets().where((a) => a.startsWith(carpeta)).toList();
    final jsons = assets.where((a) => a.endsWith('.json')).toList();
    final conImagen = {
      for (final a in assets)
        if (a.endsWith('.webp')) a.substring(carpeta.length, a.length - '.webp'.length),
    };
    final cuadros = await Future.wait(
      jsons.map((j) async {
        final svg = '${j.substring(0, j.length - '.json'.length)}.svg';
        return (json: await bundle.loadString(j), svg: await bundle.loadString(svg));
      }),
    );
    return Catalogo.desdeTextos(
      cuadros,
      conImagen: conImagen,
      cargarImagen: (asset) => cargarImagenDeBundle(bundle, asset),
    );
  }

  /// Decodifica una imagen de un AssetBundle (null si falla).
  static Future<ui.Image?> cargarImagenDeBundle(AssetBundle bundle, String asset) async {
    try {
      final datos = await bundle.load(asset);
      final codec = await ui.instantiateImageCodec(datos.buffer.asUint8List());
      return (await codec.getNextFrame()).image;
    } on Object catch (e) {
      debugPrint('No se pudo cargar $asset: $e');
      return null;
    }
  }

  /// Metadatos en el orden de la galería.
  final List<MetaCuadro> metas;
  final Map<String, String> _svgs;

  /// Cantidad de regiones de cada cuadro (sin armar la geometría).
  final Map<String, int> cantidadRegiones;

  final Map<String, Cuadro> _cache = {};
  final Set<String> _conImagen;
  final CargadorImagen? _cargarImagen;
  final Map<String, Future<ui.Image?>> _imagenes = {};

  bool tieneImagen(String id) => _conImagen.contains(id) && _cargarImagen != null;

  /// Ilustración del cuadro (se decodifica una sola vez). Null si no tiene.
  Future<ui.Image?> imagen(String id) {
    if (!tieneImagen(id)) return Future.value();
    return _imagenes[id] ??= _cargarImagen!('$carpeta$id.webp');
  }

  /// Imagen cualquiera de los assets (por ejemplo, el mapa), también en caché.
  Future<ui.Image?> imagenAsset(String asset) {
    final cargar = _cargarImagen;
    if (cargar == null) return Future.value();
    return _imagenes[asset] ??= cargar(asset);
  }

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
