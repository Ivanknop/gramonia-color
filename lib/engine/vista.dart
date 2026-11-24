/// Tamaños para la vista del lienzo: tamaño de los números y zoom máximo.
/// (El zoom y el desplazamiento en sí los maneja InteractiveViewer.)
library;

import 'dart:math' as math;

/// Tamaño de fuente (unidades del viewBox) del número de una región:
/// proporcional al espacio libre para que entre, entre 1.2 y 18.
/// Los números chicos se leen con zoom (ver [escalaMaxima]).
double tamanoNumero(double radioEtiqueta) => (radioEtiqueta * 1.1).clamp(1.2, 18.0);

/// Zoom máximo: el suficiente para que el número más chico se lea (al menos
/// [tamanoLegible] puntos) y la región más chica se pueda tocar con el dedo
/// (radio de al menos [radioTocable] puntos). Entre 4x y 16x.
///
/// [factor] = puntos de pantalla por unidad del viewBox con el cuadro ajustado.
double escalaMaxima(
  Iterable<double> radios,
  double factor, {
  double tamanoLegible = 14,
  double radioTocable = 10,
}) {
  if (radios.isEmpty || factor <= 0) return 4;
  final menorRadio = radios.reduce(math.min);
  final porNumero = tamanoLegible / (tamanoNumero(menorRadio) * factor);
  final porRadio = menorRadio > 0 ? radioTocable / (menorRadio * factor) : 0.0;
  return math.max(4.0, math.max(porNumero, porRadio)).clamp(4.0, 16.0);
}
