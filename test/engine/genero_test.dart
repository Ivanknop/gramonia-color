import 'package:colores_de_gramonia/engine/genero.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const texto =
      '¡{Bienvenido|Bienvenida|Qué alegría tenerte}! Sos {un pintor|una pintora|quien pinta}.';

  test('elige la variante de cada género', () {
    expect(conGenero(texto, Genero.chico), '¡Bienvenido! Sos un pintor.');
    expect(conGenero(texto, Genero.chica), '¡Bienvenida! Sos una pintora.');
    expect(conGenero(texto, Genero.neutro), '¡Qué alegría tenerte! Sos quien pinta.');
  });

  test('un texto sin variantes queda igual', () {
    expect(conGenero('Pintalos', Genero.chica), 'Pintalos');
  });

  test('llaves que no son de género no se tocan', () {
    expect(conGenero('{a|b} y {x}', Genero.chico), '{a|b} y {x}');
  });

  test('la variante puede estar vacía', () {
    expect(conGenero('list{o|a|}', Genero.neutro), 'list');
  });
}
