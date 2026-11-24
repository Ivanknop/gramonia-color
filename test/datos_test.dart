/// Verifica que los datos del juego (cuadros y biomas) sean válidos.
library;

import 'package:colores_de_gramonia/datos/biomas.dart';
import 'package:colores_de_gramonia/engine/motor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda.dart';

void main() {
  final catalogo = catalogoDeDisco();

  test('hay cuadros y están en el orden de la galería', () {
    expect(catalogo.metas.length, greaterThanOrEqualTo(13));
    expect(catalogo.metas.first.id, 'casa-de-la-abuelita');
  });

  for (final m in catalogo.metas) {
    group('cuadro ${m.id}', () {
      test('se construye y cada número queda sobre su propia región', () {
        final cuadro = catalogo.obtener(m.id)!;
        expect(cuadro.regiones.length, catalogo.cantidadRegiones[m.id]);
        for (final r in cuadro.regiones) {
          expect(regionEnPunto(cuadro, r.etiqueta)?.id, r.id, reason: 'región ${r.id}');
        }
      });
    });
  }

  test('los biomas son consistentes con los cuadros', () {
    expect(validarBiomas(biomas, catalogo.ids), isEmpty);
  });

  test('cada cuadro destapa una pieza', () {
    final usados = {
      for (final b in biomas)
        for (final p in b.piezas) p.cuadroId,
    };
    expect(catalogo.ids.difference(usados), isEmpty);
  });
}
