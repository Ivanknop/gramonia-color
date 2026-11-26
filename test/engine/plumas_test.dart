import 'package:colores_de_gramonia/engine/motor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recompensa diaria una vez por día calendario', () {
    final hoy = DateTime(2026, 11, 24, 9);
    expect(diaDe(hoy), '2026-11-24');
    expect(tocaRecompensaDiaria(null, hoy), isTrue);
    expect(tocaRecompensaDiaria('2026-11-24', DateTime(2026, 11, 24, 23)), isFalse);
    expect(tocaRecompensaDiaria('2026-11-24', DateTime(2026, 11, 25, 0, 1)), isTrue);
  });

  test('subir de nivel suma las plumas del nivel a las de la obra', () {
    expect(plumasPorTerminar(), ReglasPlumas.porObra);
    expect(plumasPorTerminar(nivelesSubidos: 2), ReglasPlumas.porObra + 2 * ReglasPlumas.porNivel);
  });

  test('se compra solo si alcanza el saldo', () {
    for (final h in Herramienta.values) {
      expect(puedeComprar(h.precio - 1, h), isFalse, reason: h.name);
      expect(puedeComprar(h.precio, h), isTrue, reason: h.name);
    }
  });

  test('el tutorial de la tienda regala justo lo que cuesta la lupa', () {
    expect(plumasTutorialTienda, Herramienta.lupa.precio);
  });
}
