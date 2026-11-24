/// Modelos de cuadro y su construcción a partir del JSON de metadatos y el SVG.
library;

import 'etiquetas.dart';
import 'geometria.dart';
import 'svg.dart';

enum Categoria { paisaje, animal, objeto, persona, arte }

/// Un color de la paleta. El número es el que ve el jugador.
class ColorPaleta {
  const ColorPaleta({required this.numero, required this.nombre, required this.hex});

  factory ColorPaleta.desdeJson(Map<String, dynamic> j) => ColorPaleta(
    numero: j['numero'] as int,
    nombre: j['nombre'] as String,
    hex: j['hex'] as String,
  );

  final int numero;
  final String nombre;

  /// Color objetivo en formato #RRGGBB.
  final String hex;
}

/// Metadatos de un cuadro (archivo `<id>.json`).
class MetaCuadro {
  const MetaCuadro({
    required this.id,
    required this.titulo,
    required this.categoria,
    required this.dificultad,
    required this.paleta,
    required this.mensajeMututu,
    this.orden = 0,
  });

  factory MetaCuadro.desdeJson(Map<String, dynamic> j) => MetaCuadro(
    id: j['id'] as String,
    titulo: j['titulo'] as String,
    categoria: Categoria.values.byName(j['categoria'] as String),
    dificultad: j['dificultad'] as int,
    paleta: [for (final c in j['paleta'] as List) ColorPaleta.desdeJson(c as Map<String, dynamic>)],
    mensajeMututu: j['mensajeMututu'] as String,
    orden: (j['orden'] as int?) ?? 0,
  );

  final String id;
  final String titulo;
  final Categoria categoria;

  /// 1 = muy fácil … 5 = muy difícil.
  final int dificultad;
  final List<ColorPaleta> paleta;

  /// Frase que se muestra al devolverle los colores al cuadro.
  final String mensajeMututu;

  /// Posición en la galería (menor primero).
  final int orden;
}

/// Una región pintable, lista para el motor y para dibujarse.
class Region {
  const Region({
    required this.id,
    required this.numero,
    required this.comandos,
    required this.poligonos,
    required this.caja,
    required this.etiqueta,
    required this.radioEtiqueta,
  });

  final String id;

  /// Número de la paleta que corresponde a esta región.
  final int numero;

  /// Comandos de dibujo con las curvas reales (para el Path de Flutter).
  final List<Comando> comandos;

  /// Geometría aplanada, para detectar toques.
  final List<Poligono> poligonos;
  final Caja caja;

  /// Dónde va el número (parte visible de la región).
  final Punto etiqueta;

  /// Espacio libre alrededor de la etiqueta: define el tamaño del número.
  final double radioEtiqueta;
}

/// Un cuadro completo: metadatos + geometría.
class Cuadro {
  const Cuadro({
    required this.meta,
    required this.ancho,
    required this.alto,
    required this.regiones,
  });

  final MetaCuadro meta;
  final double ancho;
  final double alto;

  /// En orden de dibujo: las últimas quedan arriba.
  final List<Region> regiones;

  String get id => meta.id;
  List<ColorPaleta> get paleta => meta.paleta;
}

final _hex = RegExp(r'^#[0-9a-fA-F]{6}$');

Cuadro construirCuadro(MetaCuadro meta, String svgTexto) {
  final svg = leerSvg(svgTexto);
  FormatException error(String msg) => FormatException('Cuadro "${meta.id}": $msg');

  final numeros = <int>{};
  for (final c in meta.paleta) {
    if (!numeros.add(c.numero)) throw error('número de paleta repetido: ${c.numero}');
    if (!_hex.hasMatch(c.hex)) throw error('color inválido "${c.hex}" (usar #RRGGBB)');
  }

  final leidos = <PathLeido>[];
  final formas = <FormaRegion>[];
  for (final p in svg.paths) {
    if (!numeros.contains(p.numero)) {
      throw error('la región "${p.id}" usa el número ${p.numero}, que no está en la paleta');
    }
    final leido = leerPath(p.d);
    if (leido.poligonos.isEmpty) throw error('la región "${p.id}" no tiene superficie');
    leidos.add(leido);
    formas.add(FormaRegion(leido.poligonos, cajaDe(leido.poligonos)));
  }

  final regiones = <Region>[];
  for (var i = 0; i < svg.paths.length; i++) {
    final p = svg.paths[i];
    Punto etiqueta;
    double radio;
    // Etiqueta precalculada (cuadros del conversor): no hace falta buscarla,
    // que es lo más costoso de cargar un cuadro con muchas regiones.
    if (p.etiqueta != null && p.radio != null) {
      etiqueta = p.etiqueta!;
      radio = p.radio!;
    } else {
      final calculada = calcularEtiqueta(formas, i);
      if (calculada == null) throw error('la región "${p.id}" queda totalmente tapada por otras');
      etiqueta = p.etiqueta ?? calculada.punto;
      radio = calculada.radio;
    }
    regiones.add(
      Region(
        id: p.id,
        numero: p.numero,
        comandos: leidos[i].comandos,
        poligonos: formas[i].poligonos,
        caja: formas[i].caja,
        etiqueta: etiqueta,
        radioEtiqueta: radio,
      ),
    );
  }

  final usados = {for (final r in regiones) r.numero};
  for (final n in numeros) {
    if (!usados.contains(n)) throw error('el color $n de la paleta no se usa en ninguna región');
  }
  return Cuadro(meta: meta, ancho: svg.ancho, alto: svg.alto, regiones: regiones);
}
