/// Pruebas de las pantallas con el catálogo real y progreso en memoria.
library;

import 'package:colores_de_gramonia/datos/catalogo.dart';
import 'package:colores_de_gramonia/estado/progreso.dart';
import 'package:colores_de_gramonia/main.dart';
import 'package:colores_de_gramonia/ui/pantallas/mapa.dart';
import 'package:colores_de_gramonia/ui/pantallas/pintar.dart';
import 'package:colores_de_gramonia/ui/comun.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'ayuda.dart';

final Catalogo catalogo = catalogoDeDisco();

Future<Progreso> progresoVacio() => Progreso.cargar(AlmacenEnMemoria());

/// Toca el lienzo en coordenadas del viewBox del cuadro (zoom 1).
Future<void> tocarLienzo(WidgetTester tester, String cuadroId, double x, double y) async {
  final cuadro = catalogo.obtener(cuadroId)!;
  final lienzo = find.byKey(const Key('lienzo'));
  final origen = tester.getTopLeft(lienzo);
  final factor = tester.getSize(lienzo).width / cuadro.ancho;
  await tester.tapAt(origen + Offset(x * factor, y * factor));
  await tester.pump();
}

Future<void> abrirPintar(WidgetTester tester, Progreso progreso, String id) async {
  await tester.pumpWidget(
    Dependencias(
      catalogo: catalogo,
      progreso: progreso,
      child: MaterialApp(home: Pintar(cuadroId: id)),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('inicio → galería muestra los cuadros de arte/', (tester) async {
    await tester.pumpWidget(App(catalogo: catalogo, progreso: await progresoVacio()));
    expect(find.text('Colores de Gramonia'), findsOneWidget);
    await tester.tap(find.text('Pintar'));
    await tester.pumpAndSettle();
    expect(find.text('La casa de la abuelita'), findsOneWidget);
  });

  testWidgets('un color equivocado no pinta', (tester) async {
    final progreso = await progresoVacio();
    await abrirPintar(tester, progreso, 'pez-naranja');
    final ojo = catalogo.obtener('pez-naranja')!.regiones.firstWhere((r) => r.id == 'ojo');
    await tester.tap(find.byKey(const Key('color-1')));
    await tester.pump();
    await tocarLienzo(tester, 'pez-naranja', ojo.etiqueta.x, ojo.etiqueta.y);
    expect(progreso.de('pez-naranja'), isNull);
  });

  testWidgets('pintar todo el pez muestra el mensaje y destapa la pieza', (tester) async {
    final progreso = await progresoVacio();
    await abrirPintar(tester, progreso, 'pez-naranja');
    final cuadro = catalogo.obtener('pez-naranja')!;
    expect(find.text('0% con color'), findsOneWidget);

    for (final r in cuadro.regiones) {
      final boton = find.byKey(Key('color-${r.numero}'));
      if (boton.evaluate().isNotEmpty) {
        await tester.tap(boton);
        await tester.pump();
      }
      await tocarLienzo(tester, cuadro.id, r.etiqueta.x, r.etiqueta.y);
    }

    expect(progreso.de(cuadro.id)!.terminado, isTrue);
    expect(find.text(cuadro.meta.mensajeMututu), findsOneWidget);
    expect(find.text('Destapaste una pieza de Costa de Espuma.'), findsOneWidget);
    await tester.tap(find.text('Ver el mapa'));
    await tester.pumpAndSettle();
    // La Costa queda debajo del Bosque: hay que desplazar la lista.
    await tester.scrollUntilVisible(
      find.text('1 de 4 piezas destapadas'),
      200,
      scrollable: find.descendant(of: find.byType(Mapa), matching: find.byType(Scrollable)).first,
    );
    expect(find.text('1 de 4 piezas destapadas'), findsOneWidget);
  });

  testWidgets('pinta también en un cuadro grande del conversor', (tester) async {
    final progreso = await progresoVacio();
    await abrirPintar(tester, progreso, 'la-tienda');
    final cuadro = catalogo.obtener('la-tienda')!;
    // La región más grande (la de mayor radio libre) de cualquier color.
    final r = cuadro.regiones.reduce((a, b) => a.radioEtiqueta > b.radioEtiqueta ? a : b);
    await tester.tap(find.byKey(Key('color-${r.numero}')));
    await tester.pump();
    await tocarLienzo(tester, cuadro.id, r.etiqueta.x, r.etiqueta.y);
    expect(progreso.de(cuadro.id)!.pintadas, [r.id]);
  });

  group('Mis obras', () {
    testWidgets('sin obras muestra el mensaje vacío', (tester) async {
      await tester.pumpWidget(App(catalogo: catalogo, progreso: await progresoVacio()));
      await tester.tap(find.text('Pintar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mis obras').last);
      await tester.pumpAndSettle();
      expect(find.text('Todavía no hay obras'), findsOneWidget);
    });

    testWidgets('separa en progreso y terminadas, y permite retomarlas', (tester) async {
      final progreso = await progresoVacio();
      progreso.pintarRegion('taza-de-te', 'pared');
      final pez = catalogo.obtener('pez-naranja')!;
      for (final r in pez.regiones) {
        progreso.pintarRegion(pez.id, r.id);
      }
      progreso.marcarCompletado(pez.id);

      await tester.pumpWidget(App(catalogo: catalogo, progreso: progreso));
      await tester.tap(find.text('Pintar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mis obras').last);
      await tester.pumpAndSettle();

      expect(find.text('En progreso (1)'), findsOneWidget);
      expect(find.text('Terminadas (1)'), findsOneWidget);
      expect(find.bySemanticsLabel('Taza de té, 11%'), findsOneWidget);
      expect(find.bySemanticsLabel('Pez naranja, terminada'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Taza de té, 11%'));
      await tester.pumpAndSettle();
      expect(find.text('11% con color'), findsOneWidget);
    });
  });
}
