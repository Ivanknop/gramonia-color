import 'package:colores_de_gramonia/engine/confeti.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final papelitos = Confeti.lanzar(semilla: 3);

  test('con la misma semilla, el mismo confeti', () {
    final otra = Confeti.lanzar(semilla: 3);
    expect(otra.map((p) => (p.vx, p.vy, p.color)), papelitos.map((p) => (p.vx, p.vy, p.color)));
  });

  test('salen de las esquinas de abajo hacia arriba y hacia el centro', () {
    for (final p in papelitos) {
      expect(p.y, 1.0);
      expect(p.vy, lessThan(0));
      expect(p.x == 0 ? p.vx > 0 : p.vx < 0, isTrue);
    }
  });

  test('antes de su demora no se ve; después sube y vuelve a caer', () {
    final p = papelitos.first;
    expect(Confeti.en(p, p.demora - 0.01).visible, isFalse);
    final arriba = Confeti.en(p, p.demora + 0.5);
    expect(arriba.visible, isTrue);
    expect(arriba.y, lessThan(p.y));
    final despues = Confeti.en(p, p.demora + 2.5);
    expect(despues.y, greaterThan(arriba.y));
  });

  test('todo el confeti desaparece al final del festejo', () {
    for (final p in papelitos) {
      expect(Confeti.en(p, Confeti.duracion + 1).visible, isFalse);
    }
  });

  test('llega a cubrir la pantalla: algún papelito pasa por la mitad de arriba', () {
    final altos = [
      for (final p in papelitos)
        for (var t = 0.0; t < 2; t += 0.1) Confeti.en(p, t),
    ].where((e) => e.visible && e.y < 0.5);
    expect(altos, isNotEmpty);
  });
}
