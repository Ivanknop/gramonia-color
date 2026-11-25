import 'dart:math' as math;

import 'package:colores_de_gramonia/datos/biomas.dart';
import 'package:colores_de_gramonia/datos/textos.dart';
import 'package:colores_de_gramonia/engine/motor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Bioma lugar(String id) => biomas.firstWhere((b) => b.id == id);

  test('cada lugar se nombra con su artículo', () {
    expect(lugar('arbol-magico').conArticulo, 'el Árbol Mágico');
    expect(lugar('montana-dragon').conArticulo, 'la Montaña Dragón');
    expect(lugar('tierra-de-las-caperucitas').conArticulo, 'la Tierra de las Caperucitas');
    expect(lugar('ciudad').conArticulo, 'la Ciudad');
    expect(lugar('isla-roja').conArticulo, 'la Isla Roja');
    expect(lugar('prado-de-las-hadas').conArticulo, 'el Prado de las Hadas');
  });

  test('el mensaje depende de cuántas obras le faltan al lugar', () {
    const textos = (
      faltan: ['Faltan {n} de {lugar}.'],
      faltaUna: ['Falta una de {lugar}.'],
      completo: ['¡{Lugar} completo! Volvió el color a {lugar}.'],
    );
    final arbol = lugar('arbol-magico');
    final obras = arbol.cuadroIds.toList();
    final azar = math.Random(1);
    expect(mensajeDeObra(arbol, {obras[0]}, textos, azar), 'Faltan 2 del Árbol Mágico.');
    expect(mensajeDeObra(arbol, {obras[0], obras[1]}, textos, azar), 'Falta una del Árbol Mágico.');
    expect(
      mensajeDeObra(arbol, obras.toSet(), textos, azar),
      '¡El Árbol Mágico completo! Volvió el color al Árbol Mágico.',
    );
  });

  test('los textos de verdad: todos los lugares quedan bien escritos', () {
    for (final b in biomas.where((b) => b.cuadroIds.isNotEmpty)) {
      for (var semilla = 0; semilla < 10; semilla++) {
        for (final hechas in [<String>{}, b.cuadroIds.toSet()]) {
          final m = mensajeDeObra(b, hechas, Textos.mensajesObra, math.Random(semilla));
          expect(m, isNot(contains('{')), reason: m);
          expect(m, isNot(matches(RegExp(r'\b(a|de) el '))), reason: m);
          expect(m, contains(b.nombre.replaceFirst(RegExp('^(El|La) '), '')), reason: m);
        }
      }
    }
  });
}
