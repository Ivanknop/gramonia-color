import 'package:colores_de_gramonia/engine/motor.dart';
import 'package:flutter_test/flutter_test.dart';

// Fondo de 100x100 con un cuadrado encima (superpuesto) y otro de otro color.
const meta = MetaCuadro(
  id: 'prueba',
  titulo: 'Prueba',
  categoria: Categoria.arte,
  dificultad: 1,
  paleta: [
    ColorPaleta(numero: 1, nombre: 'Uno', hex: '#FF0000'),
    ColorPaleta(numero: 2, nombre: 'Dos', hex: '#00FF00'),
  ],
);
const svg = '''<svg viewBox="0 0 100 100">
  <path id="fondo" data-numero="1" d="M0 0 H100 V100 H0 Z" />
  <path id="cuadrado" data-numero="2" d="M10 10 H40 V40 H10 Z" />
  <path id="otro" data-numero="2" d="M60 60 H90 V90 H60 Z" />
</svg>''';

void main() {
  final cuadro = construirCuadro(meta, svg);

  group('regionEnPunto', () {
    test('devuelve la región de arriba cuando se superponen', () {
      expect(regionEnPunto(cuadro, const Punto(20, 20))?.id, 'cuadrado');
      expect(regionEnPunto(cuadro, const Punto(50, 20))?.id, 'fondo');
    });
    test('fuera del cuadro no hay región', () {
      expect(regionEnPunto(cuadro, const Punto(150, 20)), isNull);
    });
  });

  group('intentarPintar', () {
    test('color correcto', () {
      final r = intentarPintar(cuadro, {}, const Punto(20, 20), 2);
      expect(r, isA<Correcto>());
      r as Correcto;
      expect((r.regionId, r.cuadroCompleto, r.colorCompleto), ('cuadrado', false, false));
    });

    test('color incorrecto informa el número esperado', () {
      final r = intentarPintar(cuadro, {}, const Punto(20, 20), 1) as Incorrecto;
      expect((r.regionId, r.numeroEsperado), ('cuadrado', 2));
    });

    test('región ya pintada y toque fuera', () {
      expect(intentarPintar(cuadro, {'cuadrado'}, const Punto(20, 20), 2), isA<YaPintada>());
      expect(intentarPintar(cuadro, {}, const Punto(-5, 0), 1), isA<Fuera>());
    });

    test('avisa cuando se completa un color y cuando se completa el cuadro', () {
      final r1 = intentarPintar(cuadro, {'cuadrado'}, const Punto(70, 70), 2) as Correcto;
      expect((r1.colorCompleto, r1.cuadroCompleto), (true, false));
      final r2 = intentarPintar(cuadro, {'cuadrado', 'otro'}, const Punto(50, 50), 1) as Correcto;
      expect((r2.colorCompleto, r2.cuadroCompleto), (true, true));
    });
  });

  test('porcentaje, faltantes y completo', () {
    expect(porcentajeCompletado(cuadro, {'cuadrado'}), 33);
    expect(faltantesDeColor(cuadro, {'cuadrado'}, 2), 1);
    expect(estaCompleto(cuadro, {'fondo', 'cuadrado', 'otro'}), isTrue);
    expect(porcentaje(0, 0), 100);
  });

  test('sanearPintadas descarta ids que ya no existen', () {
    expect(sanearPintadas(cuadro, ['fondo', 'borrada']), {'fondo'});
  });

  group('construirCuadro', () {
    test('ubica el número del fondo en una zona visible, no debajo del cuadrado', () {
      final fondo = cuadro.regiones.first;
      expect(regionEnPunto(cuadro, fondo.etiqueta)?.id, 'fondo');
      expect(fondo.radioEtiqueta, greaterThan(5));
    });

    test('respeta etiqueta y radio precalculados', () {
      final c = construirCuadro(
        meta,
        svg.replaceFirst('id="otro"', 'id="otro" data-etiqueta="61 62" data-radio="1.5"'),
      );
      expect(c.regiones[2].etiqueta, const Punto(61, 62));
      expect(c.regiones[2].radioEtiqueta, 1.5);
    });

    test('falla si una región usa un número fuera de la paleta', () {
      expect(
        () => construirCuadro(meta, svg.replaceFirst('data-numero="2"', 'data-numero="9"')),
        throwsA(isA<FormatException>().having((e) => e.message, 'mensaje', contains('paleta'))),
      );
    });

    test('falla si una región queda totalmente tapada', () {
      final tapada = svg.replaceFirst(
        '<path id="fondo"',
        '<path id="chiquito" data-numero="2" d="M70 70 H80 V80 H70 Z" />\n  <path id="fondo"',
      );
      expect(
        () => construirCuadro(meta, tapada),
        throwsA(isA<FormatException>().having((e) => e.message, 'mensaje', contains('tapada'))),
      );
    });

    test('falla si un color de la paleta no se usa', () {
      final conTres = MetaCuadro(
        id: meta.id,
        titulo: meta.titulo,
        categoria: meta.categoria,
        dificultad: 1,
        paleta: [
          ...meta.paleta,
          const ColorPaleta(numero: 3, nombre: 'Tres', hex: '#0000FF'),
        ],
      );
      expect(
        () => construirCuadro(conTres, svg),
        throwsA(isA<FormatException>().having((e) => e.message, 'mensaje', contains('no se usa'))),
      );
    });
  });

  group('toque tolerante', () {
    test('sin tolerancia, el punto manda', () {
      final r = regionParaToque(cuadro, {}, const Punto(42, 20), 2);
      expect(r?.id, 'fondo');
    });

    test('con tolerancia, toma la región pendiente del color elegido más cercana', () {
      // A 2 unidades del borde del cuadrado (que es del color 2).
      expect(regionParaToque(cuadro, {}, const Punto(42, 20), 2, tolerancia: 3)?.id, 'cuadrado');
      final r = intentarPintar(cuadro, {}, const Punto(42, 20), 2, tolerancia: 3);
      expect(r, isA<Correcto>());
    });

    test('no se pasa de la tolerancia ni elige regiones ya pintadas', () {
      expect(regionParaToque(cuadro, {}, const Punto(48, 20), 2, tolerancia: 3)?.id, 'fondo');
      expect(
        regionParaToque(cuadro, {'cuadrado'}, const Punto(42, 20), 2, tolerancia: 3)?.id,
        'fondo',
      );
    });
  });

  test('bomba: pinta las pendientes cercanas, sin importar el color', () {
    final ids = regionesDeBomba(cuadro, {}, const Punto(25, 25), 30).map((r) => r.id).toSet();
    expect(ids, containsAll(['cuadrado']));
    expect(ids, isNot(contains('otro'))); // queda lejos
    expect(regionesDeBomba(cuadro, {'cuadrado', 'fondo'}, const Punto(25, 25), 30), isEmpty);
  });

  test('lupa: pendientes del color elegido, o todas si ese color terminó', () {
    expect(pendientesParaLupa(cuadro, {}, 2).map((r) => r.id), ['cuadrado', 'otro']);
    expect(pendientesParaLupa(cuadro, {'cuadrado', 'otro'}, 2).map((r) => r.id), ['fondo']);
    expect(pendientesParaLupa(cuadro, {'fondo', 'cuadrado', 'otro'}, 1), isEmpty);
  });
}
