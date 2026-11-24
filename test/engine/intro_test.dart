import 'package:colores_de_gramonia/engine/intro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('matriz de saturación: 1 deja la imagen igual, 0 la pasa a grises', () {
    expect(matrizSaturacion(1), [
      1, 0, 0, 0, 0, //
      0, 1, 0, 0, 0,
      0, 0, 1, 0, 0,
      0, 0, 0, 1, 0,
    ]);
    final gris = matrizSaturacion(0);
    // Las tres filas de color son iguales: r = g = b (gris).
    expect(gris.sublist(0, 5), gris.sublist(5, 10));
    expect(gris.sublist(5, 10), gris.sublist(10, 15));
    expect(gris[0] + gris[1] + gris[2], closeTo(1, 1e-9)); // el blanco sigue blanco
  });

  test('línea de tiempo: color, se apaga, "Gramonia…", pausa, "Color", botones', () {
    final inicio = Intro.en(0);
    expect((inicio.saturacion, inicio.gramonia, inicio.color, inicio.botones), (1, 0, 0, 0));
    expect(Intro.en(Intro.quieto).saturacion, 1);
    final medio = Intro.en(Intro.quieto + Intro.apagado / 2).saturacion;
    expect(medio, closeTo(0.5, 1e-9));
    expect(Intro.apagado, inInclusiveRange(2, 3));
    // Ya en blanco y negro aparece "Gramonia…" y, después de una pausa, "Color".
    final conGramonia = Intro.en(Intro.inicioGramonia + Intro.aparicion);
    expect((conGramonia.saturacion, conGramonia.gramonia, conGramonia.color), (0, 1, 0));
    final enPausa = Intro.en(Intro.inicioColor - 0.01);
    expect(enPausa.color, 0);
    final fin = Intro.en(Intro.duracion + 0.01);
    expect((fin.saturacion, fin.gramonia, fin.color, fin.botones), (0, 1, 1, 1));
  });
}
