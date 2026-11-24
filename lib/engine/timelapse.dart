/// Repetición acelerada (timelapse) de cómo se pintó un cuadro, con el orden
/// de las regiones que guarda el progreso. Dura lo mismo tenga pocas o muchas
/// regiones (entre [minimo] y [maximo]); cada región se expande desde su número.
library;

abstract final class Timelapse {
  static const minimo = Duration(milliseconds: 2500);
  static const maximo = Duration(seconds: 6);

  /// Tiempo por región si hubiera pocas (con muchas, se acelera).
  static const porRegion = Duration(milliseconds: 120);

  /// Lo que tarda en expandirse cada región, en pasos (se superponen).
  static const pasosDeRelleno = 4;

  /// Duración total para [n] regiones.
  static Duration duracion(int n) {
    final ms = (porRegion.inMilliseconds * n).clamp(minimo.inMilliseconds, maximo.inMilliseconds);
    return Duration(milliseconds: ms);
  }

  /// Tiempo entre una región y la siguiente: la última termina de expandirse
  /// justo al final.
  static Duration paso(int n) {
    if (n == 0) return Duration.zero;
    return duracion(n) ~/ (n - 1 + pasosDeRelleno);
  }

  /// Cuándo empieza a pintarse la región número [i] (desde 0) de [n].
  static Duration inicio(int i, int n) => paso(n) * i;

  /// Lo que tarda en expandirse cada región.
  static Duration relleno(int n) => paso(n) * pasosDeRelleno;

  /// Cuántas regiones ya empezaron a pintarse a los [t] de la repetición.
  static int empezadas(Duration t, int n) {
    if (n == 0) return 0;
    if (t >= duracion(n)) return n;
    final p = paso(n).inMicroseconds;
    if (p == 0) return n;
    return (t.inMicroseconds ~/ p + 1).clamp(0, n);
  }
}
