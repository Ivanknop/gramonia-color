/// Ubicación automática de los números dentro de cada región.
///
/// Las regiones se dibujan en orden y pueden superponerse (las últimas tapan a
/// las primeras). El número se busca en la parte VISIBLE de la región: el punto
/// más alejado de cualquier borde (versión simple del "polo de
/// inaccesibilidad"), con una grilla gruesa y refinamientos.
///
/// Los cuadros generados por el conversor traen la etiqueta precalculada; esto
/// se usa para los cuadros hechos a mano.
library;

import 'geometria.dart';

class FormaRegion {
  const FormaRegion(this.poligonos, this.caja);
  final List<Poligono> poligonos;
  final Caja caja;
}

const _celdas = 24;
const _refinamientos = 3;

/// Calcula la etiqueta de la región `indice` considerando las que están encima.
/// Devuelve null si la región queda totalmente tapada.
({Punto punto, double radio})? calcularEtiqueta(List<FormaRegion> formas, int indice) {
  final propia = formas[indice];
  final encima = [
    for (final f in formas.skip(indice + 1))
      if (f.caja.toca(propia.caja)) f,
  ];

  double evaluar(Punto p) {
    if (!puntoEnPoligonos(p, propia.poligonos)) return -1;
    var radio = distanciaABorde(p, propia.poligonos);
    for (final f in encima) {
      if (f.caja.contiene(p) && puntoEnPoligonos(p, f.poligonos)) return -1;
      final d = distanciaABorde(p, f.poligonos);
      if (d < radio) radio = d;
    }
    return radio;
  }

  final c = propia.caja;
  var pasoX = (c.maxX - c.minX) / _celdas;
  var pasoY = (c.maxY - c.minY) / _celdas;
  ({Punto punto, double radio})? mejor;

  void buscar(double x0, double y0, double x1, double y1) {
    for (var x = x0 + pasoX / 2; x < x1; x += pasoX) {
      for (var y = y0 + pasoY / 2; y < y1; y += pasoY) {
        final p = Punto(x, y);
        final radio = evaluar(p);
        if (radio > 0 && (mejor == null || radio > mejor!.radio)) mejor = (punto: p, radio: radio);
      }
    }
  }

  buscar(c.minX, c.minY, c.maxX, c.maxY);
  for (var i = 0; i < _refinamientos && mejor != null; i++) {
    // Ventana de ±1 celda alrededor del mejor punto, con celdas 4 veces menores.
    final centro = mejor!.punto;
    final ventanaX = pasoX, ventanaY = pasoY;
    pasoX /= 4;
    pasoY /= 4;
    buscar(centro.x - ventanaX, centro.y - ventanaY, centro.x + ventanaX, centro.y + ventanaY);
  }
  return mejor;
}
