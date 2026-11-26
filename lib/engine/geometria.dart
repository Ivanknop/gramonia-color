/// Paths SVG: polígonos aplanados para detectar toques y comandos absolutos para dibujar las curvas
/// reales. El arco (A) se aproxima con una recta al punto final: conviene evitarlo.
library;

import 'dart:math' as math;

class Punto {
  const Punto(this.x, this.y);
  final double x;
  final double y;

  double distanciaA(Punto otro) =>
      math.sqrt((x - otro.x) * (x - otro.x) + (y - otro.y) * (y - otro.y));

  @override
  bool operator ==(Object other) => other is Punto && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Punto($x, $y)';
}

typedef Poligono = List<Punto>;

class Caja {
  const Caja(this.minX, this.minY, this.maxX, this.maxY);
  final double minX;
  final double minY;
  final double maxX;
  final double maxY;

  bool contiene(Punto p) => p.x >= minX && p.x <= maxX && p.y >= minY && p.y <= maxY;

  bool toca(Caja o) => minX <= o.maxX && o.minX <= maxX && minY <= o.maxY && o.minY <= maxY;

  @override
  bool operator ==(Object other) =>
      other is Caja &&
      other.minX == minX &&
      other.minY == minY &&
      other.maxX == maxX &&
      other.maxY == maxY;

  @override
  int get hashCode => Object.hash(minX, minY, maxX, maxY);
}

sealed class Comando {
  const Comando();
}

class MoverA extends Comando {
  const MoverA(this.p);
  final Punto p;
}

class LineaA extends Comando {
  const LineaA(this.p);
  final Punto p;
}

class CubicaA extends Comando {
  const CubicaA(this.c1, this.c2, this.p);
  final Punto c1;
  final Punto c2;
  final Punto p;
}

class CuadraticaA extends Comando {
  const CuadraticaA(this.c, this.p);
  final Punto c;
  final Punto p;
}

class Cerrar extends Comando {
  const Cerrar();
}

class PathLeido {
  const PathLeido(this.poligonos, this.comandos);
  final List<Poligono> poligonos;
  final List<Comando> comandos;
}

/// Cantidad de segmentos rectos con que se aproxima cada curva al aplanar.
const _pasosCurva = 12;

const _cantParams = {
  'M': 2,
  'L': 2,
  'H': 1,
  'V': 1,
  'C': 6,
  'S': 4,
  'Q': 4,
  'T': 2,
  'A': 7,
  'Z': 0,
};

final _reToken = RegExp(r'([MmLlHhVvCcSsQqTtAaZz])|(-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?)');

PathLeido leerPath(String d) {
  final tokens = <(String, List<double>)>[];
  for (final m in _reToken.allMatches(d)) {
    if (m.group(1) != null) {
      tokens.add((m.group(1)!, <double>[]));
    } else if (tokens.isNotEmpty) {
      tokens.last.$2.add(double.parse(m.group(2)!));
    } else {
      throw FormatException('Path inválido: número antes del primer comando en "$d"');
    }
  }

  final poligonos = <Poligono>[];
  final comandos = <Comando>[];
  var actual = <Punto>[];
  var x = 0.0, y = 0.0, inicioX = 0.0, inicioY = 0.0;
  // Último punto de control, para los comandos "suaves" S y T.
  var ctrlX = 0.0, ctrlY = 0.0;
  var ultimo = '';

  void cerrarSubpath() {
    if (actual.length >= 3) poligonos.add(actual);
    actual = <Punto>[];
  }

  for (final (cmd, args) in tokens) {
    final tipo = cmd.toUpperCase();
    final rel = cmd != tipo;
    final n = _cantParams[tipo]!;

    if (tipo == 'Z') {
      cerrarSubpath();
      comandos.add(const Cerrar());
      x = inicioX;
      y = inicioY;
      ultimo = 'Z';
      continue;
    }
    if (args.isEmpty || args.length % n != 0) {
      throw FormatException(
        'Comando "$cmd" con ${args.length} parámetros (esperaba múltiplo de $n)',
      );
    }

    for (var i = 0; i < args.length; i += n) {
      final a = args.sublist(i, i + n);
      final ox = rel ? x : 0.0;
      final oy = rel ? y : 0.0;
      // Tras el primer par, un M se interpreta como L (regla de SVG).
      final t = tipo == 'M' && i > 0 ? 'L' : tipo;

      switch (t) {
        case 'M':
          cerrarSubpath();
          x = ox + a[0];
          y = oy + a[1];
          inicioX = x;
          inicioY = y;
          actual.add(Punto(x, y));
          comandos.add(MoverA(Punto(x, y)));
        case 'L' || 'H' || 'V' || 'A':
          if (t == 'L') {
            x = ox + a[0];
            y = oy + a[1];
          } else if (t == 'H') {
            x = (rel ? x : 0) + a[0];
          } else if (t == 'V') {
            y = (rel ? y : 0) + a[0];
          } else {
            // Arco: aproximado con una recta (ver comentario del módulo).
            x = ox + a[5];
            y = oy + a[6];
          }
          actual.add(Punto(x, y));
          comandos.add(LineaA(Punto(x, y)));
        case 'C' || 'S':
          double c1x, c1y;
          final int base;
          if (t == 'C') {
            c1x = ox + a[0];
            c1y = oy + a[1];
            base = 2;
          } else {
            final reflejar = ultimo == 'C' || ultimo == 'S';
            c1x = reflejar ? 2 * x - ctrlX : x;
            c1y = reflejar ? 2 * y - ctrlY : y;
            base = 0;
          }
          final c2x = ox + a[base], c2y = oy + a[base + 1];
          final fx = ox + a[base + 2], fy = oy + a[base + 3];
          for (var p = 1; p <= _pasosCurva; p++) {
            final s = p / _pasosCurva, u = 1 - s;
            actual.add(
              Punto(
                u * u * u * x + 3 * u * u * s * c1x + 3 * u * s * s * c2x + s * s * s * fx,
                u * u * u * y + 3 * u * u * s * c1y + 3 * u * s * s * c2y + s * s * s * fy,
              ),
            );
          }
          comandos.add(CubicaA(Punto(c1x, c1y), Punto(c2x, c2y), Punto(fx, fy)));
          ctrlX = c2x;
          ctrlY = c2y;
          x = fx;
          y = fy;
        case 'Q' || 'T':
          double cx, cy, fx, fy;
          if (t == 'Q') {
            cx = ox + a[0];
            cy = oy + a[1];
            fx = ox + a[2];
            fy = oy + a[3];
          } else {
            final reflejar = ultimo == 'Q' || ultimo == 'T';
            cx = reflejar ? 2 * x - ctrlX : x;
            cy = reflejar ? 2 * y - ctrlY : y;
            fx = ox + a[0];
            fy = oy + a[1];
          }
          for (var p = 1; p <= _pasosCurva; p++) {
            final s = p / _pasosCurva, u = 1 - s;
            actual.add(
              Punto(
                u * u * x + 2 * u * s * cx + s * s * fx,
                u * u * y + 2 * u * s * cy + s * s * fy,
              ),
            );
          }
          comandos.add(CuadraticaA(Punto(cx, cy), Punto(fx, fy)));
          ctrlX = cx;
          ctrlY = cy;
          x = fx;
          y = fy;
      }
      ultimo = t;
    }
  }
  cerrarSubpath();
  return PathLeido(poligonos, comandos);
}

List<Poligono> aplanarPath(String d) => leerPath(d).poligonos;

/// ¿El punto está dentro de los polígonos? Regla par-impar (evenodd): un
/// subpath dentro de otro funciona como agujero.
bool puntoEnPoligonos(Punto p, List<Poligono> poligonos) {
  var dentro = false;
  for (final pol in poligonos) {
    for (var i = 0, j = pol.length - 1; i < pol.length; j = i++) {
      final a = pol[i], b = pol[j];
      if ((a.y > p.y) != (b.y > p.y) && p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x) {
        dentro = !dentro;
      }
    }
  }
  return dentro;
}

double distanciaABorde(Punto p, List<Poligono> poligonos) {
  var minimo = double.infinity;
  for (final pol in poligonos) {
    for (var i = 0, j = pol.length - 1; i < pol.length; j = i++) {
      minimo = math.min(minimo, _distanciaASegmento(p, pol[j], pol[i]));
    }
  }
  return minimo;
}

double _distanciaASegmento(Punto p, Punto a, Punto b) {
  final dx = b.x - a.x, dy = b.y - a.y;
  final largo2 = dx * dx + dy * dy;
  var t = largo2 == 0 ? 0.0 : ((p.x - a.x) * dx + (p.y - a.y) * dy) / largo2;
  t = t.clamp(0.0, 1.0);
  final ex = p.x - (a.x + t * dx), ey = p.y - (a.y + t * dy);
  return math.sqrt(ex * ex + ey * ey);
}

Caja cajaDe(List<Poligono> poligonos) {
  var minX = double.infinity, minY = double.infinity;
  var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
  for (final pol in poligonos) {
    for (final p in pol) {
      minX = math.min(minX, p.x);
      minY = math.min(minY, p.y);
      maxX = math.max(maxX, p.x);
      maxY = math.max(maxY, p.y);
    }
  }
  return Caja(minX, minY, maxX, maxY);
}
