/// Reglas de pintar por números: qué región se tocó, si el color es correcto
/// y cuánto falta. Funciones puras: lo pintado lo guarda el estado.
library;

import 'cuadro.dart';
import 'geometria.dart';

/// Lo que pasó al tocar el cuadro con un color.
sealed class ResultadoPintar {
  const ResultadoPintar();
}

class Correcto extends ResultadoPintar {
  const Correcto(this.regionId, {required this.cuadroCompleto, required this.colorCompleto});
  final String regionId;
  final bool cuadroCompleto;
  final bool colorCompleto;
}

class Incorrecto extends ResultadoPintar {
  const Incorrecto(this.regionId, this.numeroEsperado);
  final String regionId;
  final int numeroEsperado;
}

class YaPintada extends ResultadoPintar {
  const YaPintada(this.regionId);
  final String regionId;
}

class Fuera extends ResultadoPintar {
  const Fuera();
}

/// Región visible en el punto (coordenadas del viewBox), o null.
Region? regionEnPunto(Cuadro cuadro, Punto p) {
  // De arriba hacia abajo: la última dibujada es la que se ve.
  for (var i = cuadro.regiones.length - 1; i >= 0; i--) {
    final r = cuadro.regiones[i];
    if (r.caja.contiene(p) && puntoEnPoligonos(p, r.poligonos)) return r;
  }
  return null;
}

/// Intenta pintar el punto tocado con el número elegido. No modifica nada.
ResultadoPintar intentarPintar(Cuadro cuadro, Set<String> pintadas, Punto p, int numeroElegido) {
  final region = regionEnPunto(cuadro, p);
  if (region == null) return const Fuera();
  if (pintadas.contains(region.id)) return YaPintada(region.id);
  if (region.numero != numeroElegido) return Incorrecto(region.id, region.numero);
  final despues = {...pintadas, region.id};
  return Correcto(
    region.id,
    cuadroCompleto: estaCompleto(cuadro, despues),
    colorCompleto: faltantesDeColor(cuadro, despues, numeroElegido) == 0,
  );
}

/// Porcentaje pintado (0 a 100), contando regiones.
int porcentajeCompletado(Cuadro cuadro, Set<String> pintadas) => porcentaje(
  cuadro.regiones.where((r) => pintadas.contains(r.id)).length,
  cuadro.regiones.length,
);

int porcentaje(int hechas, int total) => total == 0 ? 100 : (hechas * 100 / total).round();

bool estaCompleto(Cuadro cuadro, Set<String> pintadas) =>
    cuadro.regiones.every((r) => pintadas.contains(r.id));

/// Cuántas regiones de ese número faltan pintar.
int faltantesDeColor(Cuadro cuadro, Set<String> pintadas, int numero) =>
    cuadro.regiones.where((r) => r.numero == numero && !pintadas.contains(r.id)).length;

/// Descarta ids que ya no existen (por ejemplo, si un cuadro se regeneró).
Set<String> sanearPintadas(Cuadro cuadro, Iterable<String> ids) {
  final validos = {for (final r in cuadro.regiones) r.id};
  return {
    for (final id in ids)
      if (validos.contains(id)) id,
  };
}
