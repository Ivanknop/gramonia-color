import 'dart:math' as math;

import 'geometria.dart';

/// Tamaño de fuente (unidades del viewBox) del número de una región:
/// proporcional al espacio libre para que entre, entre 1.2 y 18.
/// Los números chicos se leen con zoom (ver [escalaMaxima]).
double tamanoNumero(double radioEtiqueta) => (radioEtiqueta * 1.1).clamp(1.2, 18.0);

/// Zoom máximo: el suficiente para que el número más chico se lea (al menos
/// [tamanoLegible] puntos) y la región más chica se pueda tocar con el dedo
/// (radio de al menos [radioTocable] puntos). Entre 4x y 16x.
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

/// Radio que tiene que alcanzar un círculo que crece desde [origen] para
/// cubrir toda la caja de una región (distancia a la esquina más lejana).
double radioParaCubrir(Caja caja, Punto origen) => [
  Punto(caja.minX, caja.minY),
  Punto(caja.maxX, caja.minY),
  Punto(caja.minX, caja.maxY),
  Punto(caja.maxX, caja.maxY),
].map(origen.distanciaA).reduce(math.max);

/// con salida suave (ease-out): arranca rápido y frena al llenar.
double avanceAnimacion(Duration ahora, Duration inicio, Duration duracion) {
  if (ahora <= inicio) return 0;
  final t = ((ahora - inicio).inMicroseconds / duracion.inMicroseconds).clamp(0.0, 1.0);
  return 1 - (1 - t) * (1 - t) * (1 - t);
}
