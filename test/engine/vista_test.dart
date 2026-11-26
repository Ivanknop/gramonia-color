import 'package:colores_de_gramonia/engine/motor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tamanoNumero se acota entre 1.2 y 18', () {
    expect(tamanoNumero(0.5), 1.2);
    expect(tamanoNumero(10), closeTo(11, 1e-9));
    expect(tamanoNumero(100), 18);
  });

  test('escalaMaxima permite leer y tocar lo más chico, entre 4x y 16x', () {
    expect(escalaMaxima([20, 30], 1), 4); // ya se ve bien: mínimo 4x
    expect(escalaMaxima([0.8], 2), closeTo(10 / 1.6, 1e-9)); // radio 1.6 pt → 6.25x
    expect(escalaMaxima([0.5], 0.1), 16); // tope
  });

  test('radioParaCubrir llega a la esquina más lejana', () {
    expect(radioParaCubrir(const Caja(0, 0, 3, 4), const Punto(0, 0)), closeTo(5, 1e-9));
    expect(radioParaCubrir(const Caja(0, 0, 10, 10), const Punto(5, 5)), closeTo(7.0711, 1e-4));
  });

  test('avanceAnimacion va de 0 a 1 con salida suave', () {
    const d = Duration(milliseconds: 100);
    expect(avanceAnimacion(Duration.zero, const Duration(milliseconds: 10), d), 0);
    final mitad = avanceAnimacion(const Duration(milliseconds: 50), Duration.zero, d);
    expect(mitad, greaterThan(0.5)); // ease-out: a mitad de tiempo ya pasó la mitad
    expect(avanceAnimacion(const Duration(milliseconds: 200), Duration.zero, d), 1);
  });
}
