import 'package:colores_de_gramonia/engine/motor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('los pasos del tutorial van en orden: se muestra el primero que falta', () {
    expect(pasoActual({}), PasoTutorial.elegirColor);
    expect(pasoActual({PasoTutorial.elegirColor}), PasoTutorial.tocarParte);
    // Si alguien se adelanta (usa la bomba antes), el paso queda hecho igual.
    expect(
      pasoActual({PasoTutorial.elegirColor, PasoTutorial.tocarParte, PasoTutorial.bomba}),
      PasoTutorial.completarColor,
    );
    expect(pasoActual(PasoTutorial.values.toSet()), PasoTutorial.terminar);
  });

  test('el tutorial da 20 plumas', () => expect(ReglasPlumas.porTutorial, 20));
}
