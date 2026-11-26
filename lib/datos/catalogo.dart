/// Catálogo de cuadros. La geometría se arma la primera vez que se pide; las variantes
/// (assets/variantes/, que son muchas) se leen recién cuando se piden.
library;

import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../engine/dificultad.dart';
import '../engine/motor.dart';

typedef CargadorImagen = Future<ui.Image?> Function(String asset);

typedef LectorTexto = Future<String> Function(String asset);

class Catalogo {
  Catalogo._(
    this.metas,
    this._svgs,
    this._conImagen,
    this._cargarImagen,
    this.dificultades,
    this._leer,
  ) : cantidadRegiones = {
        for (final e in _svgs.entries) e.key: RegExp(r'<path\b').allMatches(e.value).length,
      };

  /// [conImagen]: ids que tienen ilustración (`<id>.webp`); [cargarImagen] la
  /// decodifica (sin cargador, los cuadros se dibujan con colores planos).
  factory Catalogo.desdeTextos(
    Iterable<({String json, String svg})> cuadros, {
    Set<String> conImagen = const {},
    CargadorImagen? cargarImagen,
    List<Dificultad> dificultades = const [],
    LectorTexto? leer,
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
    return Catalogo._(metas, svgs, conImagen, cargarImagen, dificultades, leer);
  }

  static const carpeta = 'assets/cuadros/';
  static const carpetaVariantes = 'assets/variantes/';
  static const tablaDificultades = 'assets/dificultades.json';

  /// Las variantes usan la ilustración de su cuadro.
  static String ilustracion(String id) => '$carpeta${cuadroBase(id)}.webp';

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
      dificultades: leerDificultades(await bundle.loadString(tablaDificultades)),
      leer: bundle.loadString,
    );
  }

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
  final List<Dificultad> dificultades;
  final LectorTexto? _leer;
  final Map<String, Cuadro> _cache = {};
  final Map<String, MetaCuadro> _metasVariantes = {};
  final Set<String> _conImagen;
  final CargadorImagen? _cargarImagen;
  final Map<String, Future<ui.Image?>> _imagenes = {};

  bool tieneImagen(String id) => _conImagen.contains(id) && _cargarImagen != null;

  /// Ilustración del cuadro (se decodifica una sola vez). Null si no tiene.
  Future<ui.Image?> imagen(String id) {
    id = cuadroBase(id);
    if (!tieneImagen(id)) return Future.value();
    return _imagenes[id] ??= _cargarImagen!(ilustracion(id));
  }

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
    return _metasVariantes[id];
  }

  Dificultad? dificultad(String id) => dificultades.where((d) => d.id == id).firstOrNull;

  /// La de la variante del modo libre o la de la obra de la historia [rehecha] en otra.
  Dificultad? dificultadDeObra(String clave, {String? rehecha}) =>
      dificultad(dificultadDe(clave) ?? rehecha ?? '');

  /// Lee y arma la variante de [cuadroId] en la dificultad [dificultadId]
  /// (queda en memoria: después la da [obtener] con su id de variante).
  Future<Cuadro?> cargarVariante(String cuadroId, String dificultadId) async {
    final id = idVariante(cuadroId, dificultadId);
    final enCache = _cache[id];
    if (enCache != null) return enCache;
    final leer = _leer;
    if (leer == null) return null;
    try {
      final json = await leer('$carpetaVariantes$id.json');
      final svg = await leer('$carpetaVariantes$id.svg');
      final m = MetaCuadro.desdeJson(jsonDecode(json) as Map<String, dynamic>);
      _metasVariantes[id] = m;
      return _cache[id] = construirCuadro(m, svg);
    } on Object catch (e) {
      debugPrint('No se pudo cargar la variante $id: $e');
      return null;
    }
  }

  /// Id de la geometría de una obra: la clave misma, o la variante si es una
  /// obra de la historia rehecha en otra [dificultad].
  static String geometriaDeObra(String clave, String? dificultad) =>
      dificultadDe(clave) == null && dificultad != null ? idVariante(clave, dificultad) : clave;

  /// Cuadro de una obra ya en memoria (null si es una variante sin leer).
  Cuadro? obtenerDeObra(String clave, {String? dificultad}) =>
      obtener(geometriaDeObra(clave, dificultad));

  Future<Cuadro?> cuadroDeObra(String clave, {String? dificultad}) async {
    final id = geometriaDeObra(clave, dificultad);
    final enMemoria = obtener(id);
    if (enMemoria != null) return enMemoria;
    final d = dificultadDe(id);
    return d == null ? null : cargarVariante(cuadroBase(id), d);
  }

  /// Cuadro listo para jugar (la geometría se arma una sola vez). Las
  /// variantes, solo después de [cargarVariante].
  Cuadro? obtener(String id) {
    final enCache = _cache[id];
    if (enCache != null) return enCache;
    final m = meta(id);
    final svg = _svgs[id];
    if (m == null || svg == null) return null;
    return _cache[id] = construirCuadro(m, svg);
  }
}
