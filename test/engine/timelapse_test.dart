import 'package:colores_de_gramonia/engine/timelapse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dura entre 2,5 y 6 segundos, tenga pocas o muchas regiones', () {
    expect(Timelapse.duracion(3), Timelapse.minimo);
    expect(Timelapse.duracion(30), const Duration(milliseconds: 3600));
    expect(Timelapse.duracion(700), Timelapse.maximo);
  });

  test('las regiones arrancan en orden y la última termina al final', () {
    for (final n in [1, 10, 70, 700]) {
      final ultima = Timelapse.inicio(n - 1, n) + Timelapse.relleno(n);
      expect(ultima, lessThanOrEqualTo(Timelapse.duracion(n)), reason: '$n regiones');
      expect(Timelapse.inicio(0, n), Duration.zero);
      if (n > 1) expect(Timelapse.inicio(1, n), greaterThan(Duration.zero));
    }
  });

  test('cuántas regiones empezaron a cada momento', () {
    const n = 70;
    expect(Timelapse.empezadas(Duration.zero, n), 1);
    expect(Timelapse.empezadas(Timelapse.inicio(10, n), n), 11);
    expect(Timelapse.empezadas(Timelapse.duracion(n), n), n);
    expect(Timelapse.empezadas(const Duration(hours: 1), n), n);
    expect(Timelapse.empezadas(Duration.zero, 0), 0);
  });
}
