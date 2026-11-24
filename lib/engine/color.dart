/// Colores: el cuadro "robado por Mututu" se ve en grises claros que conservan
/// algo de la luminosidad original, para que se lea la forma sin tapar los
/// números.
library;

import 'dart:math' as math;

/// Convierte "#RRGGBB" a 0xFFRRGGBB (ARGB opaco).
int argbDeHex(String hex) => 0xFF000000 | int.parse(hex.substring(1), radix: 16);

/// Luminancia relativa (0 = negro, 1 = blanco), según WCAG.
double luminancia(String hex) {
  final n = int.parse(hex.substring(1), radix: 16);
  double canal(int v) {
    final c = v / 255;
    return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * canal((n >> 16) & 255) + 0.7152 * canal((n >> 8) & 255) + 0.0722 * canal(n & 255);
}

/// Gris "sin color" (ARGB) para una región sin pintar: comprime la
/// luminosidad al rango [minimo, maximo] para que siempre sea claro.
int grisSinColor(String hex, {double minimo = 0.72, double maximo = 0.95}) {
  final l = math.sqrt(luminancia(hex)); // raíz: reparte mejor los tonos medios
  final v = ((minimo + (maximo - minimo) * l) * 255).round();
  return 0xFF000000 | (v << 16) | (v << 8) | v;
}

/// Texto (negro o blanco, ARGB) que contrasta con el fondo dado.
/// 0.179 es el punto donde ambos dan el mismo contraste WCAG.
int textoSobre(String hex) => luminancia(hex) > 0.179 ? 0xFF000000 : 0xFFFFFFFF;
