import 'cuadro.dart';
import 'geometria.dart';

sealed class ResultadoPintar {
  const ResultadoPintar();
}

class Correcto extends ResultadoPintar {
  const Correcto(this.regionId);
  final String regionId;
}

class Incorrecto extends ResultadoPintar {
  const Incorrecto(this.regionId);
  final String regionId;
}

class YaPintada extends ResultadoPintar {
  const YaPintada(this.regionId);
  final String regionId;
}

class Fuera extends ResultadoPintar {
  const Fuera();
}

Region? regionEnPunto(Cuadro cuadro, Punto p) {
  // De arriba hacia abajo: la última dibujada es la que se ve.
  for (var i = cuadro.regiones.length - 1; i >= 0; i--) {
    final r = cuadro.regiones[i];
    if (r.caja.contiene(p) && puntoEnPoligonos(p, r.poligonos)) return r;
  }
  return null;
}

/// Región que corresponde a un toque, con tolerancia para dedos: si en el
/// punto no hay una región pendiente del número elegido, pero hay una a menos
/// de [tolerancia] (unidades del viewBox), se toma la más cercana. Así las
/// regiones chicas se pueden pintar aunque el dedo caiga un poco al costado.
Region? regionParaToque(
  Cuadro cuadro,
  Set<String> pintadas,
  Punto p,
  int numeroElegido, {
  double tolerancia = 0,
}) {
  final directa = regionEnPunto(cuadro, p);
  if (tolerancia <= 0) return directa;
  if (directa != null && directa.numero == numeroElegido && !pintadas.contains(directa.id)) {
    return directa;
  }
  Region? cercana;
  var mejor = tolerancia;
  for (final r in cuadro.regiones) {
    if (r.numero != numeroElegido || pintadas.contains(r.id)) continue;
    final c = r.caja;
    // Descarte rápido por caja antes de medir contra los bordes.
    if (p.x < c.minX - mejor ||
        p.x > c.maxX + mejor ||
        p.y < c.minY - mejor ||
        p.y > c.maxY + mejor) {
      continue;
    }
    final d = distanciaABorde(p, r.poligonos);
    if (d <= mejor) {
      mejor = d;
      cercana = r;
    }
  }
  return cercana ?? directa;
}

ResultadoPintar intentarPintar(
  Cuadro cuadro,
  Set<String> pintadas,
  Punto p,
  int numeroElegido, {
  double tolerancia = 0,
}) {
  final region = regionParaToque(cuadro, pintadas, p, numeroElegido, tolerancia: tolerancia);
  if (region == null) return const Fuera();
  if (pintadas.contains(region.id)) return YaPintada(region.id);
  if (region.numero != numeroElegido) return Incorrecto(region.id);
  return Correcto(region.id);
}

int porcentajeCompletado(Cuadro cuadro, Set<String> pintadas) => porcentaje(
  cuadro.regiones.where((r) => pintadas.contains(r.id)).length,
  cuadro.regiones.length,
);

int porcentaje(int hechas, int total) => total == 0 ? 100 : (hechas * 100 / total).round();

bool estaCompleto(Cuadro cuadro, Set<String> pintadas) =>
    cuadro.regiones.every((r) => pintadas.contains(r.id));

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

/// Regiones pendientes alcanzadas por una bomba en [centro]: las que contienen
/// el centro o tienen su número a menos de [radio]. Se pintan con su color
/// correcto, sea cual sea el elegido.
List<Region> regionesDeBomba(Cuadro cuadro, Set<String> pintadas, Punto centro, double radio) {
  final tocada = regionEnPunto(cuadro, centro);
  return [
    for (final r in cuadro.regiones)
      if (!pintadas.contains(r.id) &&
          (r.id == tocada?.id || r.etiqueta.distanciaA(centro) <= radio))
        r,
  ];
}

/// Regiones pendientes para la lupa, en orden de lectura (de arriba hacia
/// abajo y de izquierda a derecha): las del número elegido, o todas las
/// pendientes si ese color ya está completo.
List<Region> pendientesParaLupa(Cuadro cuadro, Set<String> pintadas, int? numero) {
  var lista = [
    for (final r in cuadro.regiones)
      if (!pintadas.contains(r.id) && r.numero == numero) r,
  ];
  if (lista.isEmpty) {
    lista = [
      for (final r in cuadro.regiones)
        if (!pintadas.contains(r.id)) r,
    ];
  }
  // Por franjas horizontales del 10% del alto, para que el orden se sienta natural.
  final franja = cuadro.alto / 10;
  lista.sort((a, b) {
    final fa = (a.etiqueta.y / franja).floor(), fb = (b.etiqueta.y / franja).floor();
    return fa != fb ? fa.compareTo(fb) : a.etiqueta.x.compareTo(b.etiqueta.x);
  });
  return lista;
}
