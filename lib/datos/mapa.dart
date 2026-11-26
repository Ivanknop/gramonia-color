/// Mapa provisorio (assets/mapa/gramonia.webp): la zona de cada bioma, aproximada y dibujada a
/// mano. Con un mapa definitivo se reemplazan, y fondo-caminatas vuelve a ser obra.
library;

import 'dart:math' as math;

import '../engine/geometria.dart';

const anchoMapa = 768.0;
const altoMapa = 1376.0;

class ZonaMapa {
  const ZonaMapa(this.contorno, {this.agujeros = const []});

  /// Polígono en píxeles de la ilustración.
  final List<Punto> contorno;

  /// Partes que no son de esta zona (por ejemplo, el Árbol dentro del Bosque).
  final List<List<Punto>> agujeros;

  List<Poligono> get poligonos => [contorno, ...agujeros];
}

List<Punto> _elipse(double cx, double cy, double rx, double ry, {int lados = 40}) => [
  for (var i = 0; i < lados; i++)
    Punto(cx + rx * math.cos(2 * math.pi * i / lados), cy + ry * math.sin(2 * math.pi * i / lados)),
];

List<Punto> _pol(List<(double, double)> p) => [for (final (x, y) in p) Punto(x, y)];

final _arbol = _elipse(385, 560, 150, 200);

final zonasMapa = <String, ZonaMapa>{
  'arbol-magico': ZonaMapa(_arbol),
  'bosque-magico': ZonaMapa(_elipse(340, 720, 255, 200), agujeros: [_arbol]),
  'ciudad': ZonaMapa(_pol([(310, 985), (565, 980), (575, 1090), (470, 1112), (318, 1092)])),
  'reino-animal': ZonaMapa(
    _pol([(470, 905), (600, 870), (700, 880), (705, 990), (575, 1000), (470, 970)]),
  ),
  'montana-dragon': ZonaMapa(
    _pol([(405, 205), (560, 75), (705, 150), (725, 470), (580, 520), (430, 400)]),
  ),
  'prado-de-las-hadas': ZonaMapa(
    _pol([(575, 530), (725, 500), (730, 860), (590, 865), (560, 700)]),
  ),
  'tierra-de-las-caperucitas': ZonaMapa(
    _pol([(60, 330), (235, 255), (290, 340), (215, 515), (75, 560)]),
  ),
  'reino-helado': ZonaMapa(_pol([(200, 185), (395, 175), (420, 300), (300, 335), (205, 300)])),
  'costa': ZonaMapa(
    _pol([(175, 990), (305, 990), (330, 1110), (560, 1115), (590, 1200), (300, 1215), (175, 1150)]),
  ),
  for (final (i, id) in const [
    'isla-roja',
    'isla-naranja',
    'isla-amarilla',
    'isla-verde',
    'isla-celeste',
    'isla-azul',
    'isla-violeta',
  ].indexed)
    id: ZonaMapa(_elipse(110.0 + i * 92, 1290, 30, 22, lados: 24)),
  // Más allá de las Islas Arcoíris.
  'isla-negra': ZonaMapa(_elipse(386, 1345, 38, 22, lados: 24)),
};

/// Puntos donde se van "manchando" de color las piezas de una zona: se
/// reparten por la zona eligiendo cada vez el punto más alejado de los ya
/// elegidos (muestreo del punto más lejano), así cubren la zona de forma pareja.
List<Punto> manchasDeZona(ZonaMapa zona, int cantidad) =>
    _manchas[(zona, cantidad)] ??= _calcularManchas(zona, cantidad);

final _manchas = <(ZonaMapa, int), List<Punto>>{};

List<Punto> _calcularManchas(ZonaMapa zona, int cantidad) {
  if (cantidad <= 0) return const [];
  final caja = cajaDe([zona.contorno]);
  final candidatos = <Punto>[];
  const pasos = 24;
  for (var i = 0; i < pasos; i++) {
    for (var j = 0; j < pasos; j++) {
      final p = Punto(
        caja.minX + (caja.maxX - caja.minX) * (i + 0.5) / pasos,
        caja.minY + (caja.maxY - caja.minY) * (j + 0.5) / pasos,
      );
      if (puntoEnPoligonos(p, zona.poligonos)) candidatos.add(p);
    }
  }
  if (candidatos.isEmpty) return [for (var i = 0; i < cantidad; i++) zona.contorno.first];
  final centro = Punto((caja.minX + caja.maxX) / 2, (caja.minY + caja.maxY) / 2);
  final elegidos = [
    candidatos.reduce((a, b) => a.distanciaA(centro) <= b.distanciaA(centro) ? a : b),
  ];
  double alMasCercano(Punto p) => elegidos.map(p.distanciaA).reduce(math.min);
  while (elegidos.length < cantidad) {
    elegidos.add(candidatos.reduce((a, b) => alMasCercano(a) >= alMasCercano(b) ? a : b));
  }
  return elegidos;
}

double radioDeMancha(ZonaMapa zona, int cantidad) {
  final c = cajaDe([zona.contorno]);
  final area = (c.maxX - c.minX) * (c.maxY - c.minY) * 0.7; // aproximada
  return math.sqrt(area / (math.pi * math.max(1, cantidad))) * 1.3;
}
