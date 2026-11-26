import 'package:colores_de_gramonia/engine/motor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('luminancia de blanco y negro', () {
    expect(luminancia('#FFFFFF'), closeTo(1, 1e-9));
    expect(luminancia('#000000'), closeTo(0, 1e-9));
  });

  test('el gris sin color siempre es claro y es gris', () {
    for (final hex in ['#000000', '#FFFFFF', '#674EA7', '#FFD966']) {
      final g = grisSinColor(hex);
      final r = (g >> 16) & 255, v = (g >> 8) & 255, a = g & 255;
      expect((r, v), (a, a));
      expect(r, greaterThan(0.6 * 255));
    }
    expect(grisSinColor('#222222') & 255, lessThan(grisSinColor('#EEEEEE') & 255));
  });

  test('textoSobre elige el contraste', () {
    expect(textoSobre('#FFFFFF'), 0xFF000000);
    expect(textoSobre('#222222'), 0xFFFFFFFF);
    expect(argbDeHex('#12AB34'), 0xFF12AB34);
  });
}
