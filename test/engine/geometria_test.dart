import 'package:colores_de_gramonia/engine/geometria.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('aplanarPath', () {
    test('un rectángulo con H/V da 4 puntos', () {
      expect(aplanarPath('M0 0 H10 V5 H0 Z').single, const [
        Punto(0, 0),
        Punto(10, 0),
        Punto(10, 5),
        Punto(0, 5),
      ]);
    });

    test('comandos relativos y pares implícitos después de M', () {
      expect(aplanarPath('m10 10 10 0 0 10 z').single, const [
        Punto(10, 10),
        Punto(20, 10),
        Punto(20, 20),
      ]);
    });

    test('varios subpaths generan varios polígonos', () {
      expect(aplanarPath('M0 0 H10 V10 H0 Z M2 2 H8 V8 H2 Z'), hasLength(2));
    });

    test('una curva cúbica termina en su punto final y pasa por el medio esperado', () {
      final pol = aplanarPath('M0 0 C0 10 10 10 10 0 Z').single;
      expect(pol.last, const Punto(10, 0));
      expect(pol[6].x, closeTo(5, 1e-9)); // s = 0.5 con 12 pasos
      expect(pol[6].y, closeTo(7.5, 1e-9));
    });

    test('S refleja el control anterior', () {
      final pol = aplanarPath('M0 0 C0 10 10 10 10 0 S20 -10 20 0 Z').single;
      expect(pol.last, const Punto(20, 0));
      expect(pol[18].y, closeTo(-7.5, 1e-9));
    });

    test('números pegados con signo negativo y decimales', () {
      expect(aplanarPath('M0,0L10-5L.5.5Z').single, const [
        Punto(0, 0),
        Punto(10, -5),
        Punto(0.5, 0.5),
      ]);
    });

    test('rechaza cantidades de parámetros inválidas', () {
      expect(() => aplanarPath('M0 0 L10'), throwsFormatException);
    });
  });

  test('leerPath conserva las curvas para dibujar', () {
    final c = leerPath('M0 0 C0 10 10 10 10 0 Q15 5 20 0 Z').comandos;
    expect(c.map((x) => x.runtimeType), [MoverA, CubicaA, CuadraticaA, Cerrar]);
  });

  group('puntoEnPoligonos', () {
    final anillo = aplanarPath('M0 0 H10 V10 H0 Z M3 3 H7 V7 H3 Z');
    test(
      'dentro del borde del anillo',
      () => expect(puntoEnPoligonos(const Punto(1, 1), anillo), isTrue),
    );
    test(
      'en el agujero (evenodd)',
      () => expect(puntoEnPoligonos(const Punto(5, 5), anillo), isFalse),
    );
    test('afuera', () => expect(puntoEnPoligonos(const Punto(11, 5), anillo), isFalse));
  });

  test('distanciaABorde y cajaDe', () {
    final cuadrado = aplanarPath('M0 0 H10 V10 H0 Z');
    expect(distanciaABorde(const Punto(5, 2), cuadrado), closeTo(2, 1e-9));
    expect(cajaDe(cuadrado), const Caja(0, 0, 10, 10));
  });
}
