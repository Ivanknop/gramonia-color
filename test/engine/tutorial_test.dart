import 'package:colores_de_gramonia/engine/motor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('los pasos del tutorial van en orden: color, completar, lupa, bomba, terminar', () {
    var hechos = <PasoTutorial>{};
    expect(pasoActual(hechos), PasoTutorial.elegirColor);
    hechos = cumplirPaso(hechos, PasoTutorial.elegirColor);
    expect(pasoActual(hechos), PasoTutorial.completarColor);
    hechos = cumplirPaso(hechos, PasoTutorial.completarColor);
    expect(pasoActual(hechos), PasoTutorial.lupa);
    hechos = cumplirPaso(hechos, PasoTutorial.lupa);
    expect(pasoActual(hechos), PasoTutorial.bomba);
    hechos = cumplirPaso(hechos, PasoTutorial.bomba);
    expect(pasoActual(hechos), PasoTutorial.terminar);
  });

  test('adelantarse no cuenta: solo se cumple el paso que toca', () {
    final hechos = {PasoTutorial.elegirColor};
    expect(cumplirPaso(hechos, PasoTutorial.bomba), hechos);
    expect(cumplirPaso(hechos, PasoTutorial.lupa), hechos);
    expect(cumplirPaso(hechos, PasoTutorial.elegirColor), hechos);
  });

  test('en cada paso solo se puede hacer lo que pide', () {
    bool puede(PasoTutorial p, AccionPintar a) => accionPermitida(p, a);
    expect(puede(PasoTutorial.elegirColor, AccionPintar.elegirColor), isTrue);
    expect(puede(PasoTutorial.elegirColor, AccionPintar.pintar), isFalse);
    expect(puede(PasoTutorial.elegirColor, AccionPintar.lupa), isFalse);
    expect(puede(PasoTutorial.completarColor, AccionPintar.pintar), isTrue);
    expect(puede(PasoTutorial.completarColor, AccionPintar.bomba), isFalse);
    expect(puede(PasoTutorial.lupa, AccionPintar.lupa), isTrue);
    expect(puede(PasoTutorial.lupa, AccionPintar.elegirColor), isTrue);
    expect(puede(PasoTutorial.lupa, AccionPintar.pintar), isFalse);
    expect(puede(PasoTutorial.bomba, AccionPintar.bomba), isTrue);
    expect(puede(PasoTutorial.bomba, AccionPintar.pintar), isFalse);
    for (final a in AccionPintar.values) {
      expect(puede(PasoTutorial.terminar, a), isTrue);
    }
  });

  test('tutorial de la tienda: pendiente al completar el nivel 1, hasta hacerlo o saltearlo', () {
    expect(
      estadoTutorialTienda(hecho: false, nivelesCompletos: const []),
      EstadoTutorialTienda.todaviaNo,
    );
    expect(
      estadoTutorialTienda(hecho: false, nivelesCompletos: const [1]),
      EstadoTutorialTienda.pendiente,
    );
    expect(
      estadoTutorialTienda(hecho: true, nivelesCompletos: const [1, 2]),
      EstadoTutorialTienda.hecho,
    );
    // Regala justo lo que cuesta la lupa.
    expect(plumasTutorialTienda, Herramienta.lupa.precio);
  });

  test('premios: 20 plumas por el tutorial y 3 lupas y 3 bombas al empezar', () {
    expect(ReglasPlumas.porTutorial, 20);
    expect(herramientasIniciales, {Herramienta.lupa: 3, Herramienta.bomba: 3});
  });
}
