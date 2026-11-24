/// Pruebas de las pantallas con el catálogo real (sin ilustraciones: en los
/// tests se dibuja con colores planos) y el progreso en memoria, en una
/// pantalla de teléfono vertical.
library;

import 'package:colores_de_gramonia/datos/catalogo.dart';
import 'package:colores_de_gramonia/engine/genero.dart';
import 'package:colores_de_gramonia/engine/motor.dart';
import 'package:colores_de_gramonia/engine/timelapse.dart';
import 'package:colores_de_gramonia/estado/progreso.dart';
import 'package:colores_de_gramonia/main.dart';
import 'package:colores_de_gramonia/ui/comun.dart';
import 'package:colores_de_gramonia/ui/festejo.dart';
import 'package:colores_de_gramonia/ui/pantallas/pintar.dart';
import 'package:colores_de_gramonia/ui/pintor_cuadro.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'ayuda.dart';

final Catalogo catalogo = catalogoDeDisco();

Future<Progreso> progresoNuevo({bool introVista = true}) async {
  final p = await Progreso.cargar(AlmacenEnMemoria());
  if (introVista) {
    p.marcarIntroVista();
    p.elegirGenero(Genero.neutro);
  }
  return p;
}

/// Teléfono vertical de 360x780 puntos.
void usarTelefono(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> abrirPintar(WidgetTester tester, Progreso progreso, String id) async {
  usarTelefono(tester);
  await tester.pumpWidget(
    Dependencias(
      catalogo: catalogo,
      progreso: progreso,
      child: MaterialApp(home: Pintar(cuadroId: id)),
    ),
  );
  await tester.pumpAndSettle();
}

/// Posición en pantalla de un punto del viewBox (con el zoom actual).
Offset enPantalla(WidgetTester tester, Cuadro cuadro, Punto p) {
  final rect = tester.getRect(find.byKey(const Key('lienzo')));
  final factor = rect.width / cuadro.ancho;
  return rect.topLeft + Offset(p.x * factor, p.y * factor);
}

/// Área visible del lienzo (lo que no tapan la barra ni la paleta).
Rect areaVisible(WidgetTester tester) => tester.getRect(find.byType(InteractiveViewer));

/// Una región del número dado cuya etiqueta se ve en pantalla (con margen).
Region regionVisible(
  WidgetTester tester,
  Cuadro cuadro, {
  int? numero,
  Set<String> sin = const {},
}) {
  final area = areaVisible(tester).deflate(20);
  return cuadro.regiones.firstWhere(
    (r) =>
        (numero == null || r.numero == numero) &&
        !sin.contains(r.id) &&
        area.contains(enPantalla(tester, cuadro, r.etiqueta)),
  );
}

void main() {
  testWidgets('la primera vez, Gobi cuenta la introducción y después regala plumas', (
    tester,
  ) async {
    usarTelefono(tester);
    final progreso = await progresoNuevo(introVista: false);
    await tester.pumpWidget(App(catalogo: catalogo, progreso: progreso));
    await tester.pumpAndSettle();
    expect(find.text('Gobi, el Lobito Guardián'), findsNothing); // escena 1 primero
    expect(find.text('Saltar'), findsOneWidget);
    await tester.tap(find.text('Saltar'));
    await tester.pumpAndSettle();
    expect(progreso.introVista, isTrue);
    // Gobi pregunta cómo hablarle.
    await tester.tap(find.text('Chica'));
    await tester.pumpAndSettle();
    expect(progreso.genero, Genero.chica);
    expect(progreso.plumas, ReglasPlumas.porDia);
    expect(find.textContaining('plumas del Rocanón'), findsOneWidget);
    expect(find.text('La historia'), findsOneWidget);
  });

  testWidgets('galería por lugares: el primero abierto, el siguiente bloqueado', (tester) async {
    usarTelefono(tester);
    final progreso = await progresoNuevo();
    await tester.pumpWidget(App(catalogo: catalogo, progreso: progreso));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pintar'));
    await tester.pumpAndSettle();
    expect(find.text('Árbol Mágico'), findsOneWidget);
    expect(find.text('Nivel 1'), findsOneWidget);
    expect(find.text('0 de 2 obras para llegar al nivel 2'), findsOneWidget);
    expect(find.text('Se desbloquea al recuperar el lugar anterior'), findsWidgets);
    // Una obra del Bosque (bloqueado) no se abre.
    await tester.tap(find.text('La casa de la abuelita'));
    await tester.pumpAndSettle();
    expect(find.byType(Pintar), findsNothing);
    // Una del Árbol sí.
    await tester.tap(find.text('El nido de Rocanon'));
    await tester.pumpAndSettle();
    expect(find.byType(Pintar), findsOneWidget);
  });

  testWidgets('arranca con el color 1 y el toque perdona un dedo que cae al costado', (
    tester,
  ) async {
    final progreso = await progresoNuevo();
    await abrirPintar(tester, progreso, 'nido-de-rocanon');
    final cuadro = catalogo.obtener('nido-de-rocanon')!;
    final r = regionVisible(tester, cuadro, numero: 1);
    // Desde el número, avanzar hacia la derecha hasta salir de la región…
    var x = r.etiqueta.x;
    while (regionEnPunto(cuadro, Punto(x, r.etiqueta.y))?.id == r.id) {
      x += 0.1;
    }
    // …y tocar 6 puntos de pantalla más afuera (dentro de la tolerancia de 14).
    final afuera = enPantalla(tester, cuadro, Punto(x, r.etiqueta.y)) + const Offset(6, 0);
    expect(regionEnPunto(cuadro, Punto(x + 0.5, r.etiqueta.y))?.numero, isNot(1));
    await tester.tapAt(afuera);
    await tester.pump();
    final pintadas = progreso.de(cuadro.id)?.pintadas ?? const <String>[];
    // Puede haber tomado esa u otra región del color 1 igual de cerca: lo
    // importante es que pintó una del color elegido.
    expect(pintadas, hasLength(1));
    expect(cuadro.regiones.firstWhere((x) => x.id == pintadas.single).numero, 1);
  });

  testWidgets('el color se expande con movimiento desde el toque', (tester) async {
    final progreso = await progresoNuevo();
    await abrirPintar(tester, progreso, 'nido-de-rocanon');
    final cuadro = catalogo.obtener('nido-de-rocanon')!;
    final r = regionVisible(tester, cuadro, numero: 1);
    PintorCuadro pintor() =>
        tester.widget<CustomPaint>(find.byKey(const Key('lienzo'))).painter! as PintorCuadro;

    await tester.tapAt(enPantalla(tester, cuadro, r.etiqueta));
    await tester.pump(); // registra el toque
    await tester.pump(const Duration(milliseconds: 100));
    // A mitad de camino: pintada en el progreso, pero todavía llenándose.
    expect(progreso.de(cuadro.id)!.pintadas, [r.id]);
    final anim = pintor().animaciones[r.id];
    expect(anim, isNotNull);
    expect(anim!.origen.x, closeTo(r.etiqueta.x, 0.5)); // nace donde se tocó
    expect(
      avanceAnimacion(pintor().reloj!.value, anim.inicio, anim.duracion),
      inExclusiveRange(0, 1),
    );

    await tester.pumpAndSettle();
    expect(pintor().animaciones, isEmpty); // terminó de llenarse
  });

  testWidgets('un color equivocado no pinta', (tester) async {
    final progreso = await progresoNuevo();
    await abrirPintar(tester, progreso, 'nido-de-rocanon');
    final cuadro = catalogo.obtener('nido-de-rocanon')!;
    final r = regionVisible(tester, cuadro, numero: 2);
    // Color 1 elegido; se toca justo en el número de una región del 2.
    await tester.tapAt(enPantalla(tester, cuadro, r.etiqueta));
    await tester.pump();
    final pintadas = progreso.de(cuadro.id)?.pintadas ?? const <String>[];
    expect(pintadas, isNot(contains(r.id)));
  });

  testWidgets('la bomba pinta varias regiones de una vez con su color', (tester) async {
    final progreso = await progresoNuevo();
    await abrirPintar(tester, progreso, 'nido-de-rocanon');
    final cuadro = catalogo.obtener('nido-de-rocanon')!;
    await tester.tap(find.byKey(const Key('bomba')));
    await tester.pump();
    expect(find.textContaining('tirar la bomba'), findsOneWidget);
    await tester.tapAt(areaVisible(tester).center);
    await tester.pump();
    expect(progreso.de(cuadro.id)!.pintadas.length, greaterThan(1));
    expect(find.textContaining('tirar la bomba'), findsNothing);
  });

  testWidgets('la lupa acerca la vista a una región pendiente', (tester) async {
    final progreso = await progresoNuevo();
    await abrirPintar(tester, progreso, 'nido-de-rocanon');
    final antes = tester.getRect(find.byKey(const Key('lienzo')));
    await tester.tap(find.byKey(const Key('lupa')));
    await tester.pumpAndSettle();
    final despues = tester.getRect(find.byKey(const Key('lienzo')));
    expect(despues.width, greaterThan(antes.width)); // hizo zoom
    expect(find.text('Encuadrar'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4)); // se apaga el destacado
  });

  testWidgets('terminar la última obra del Árbol: festejo, plumas y capítulo de Gobi', (
    tester,
  ) async {
    final progreso = await progresoNuevo();
    final hormiguero = catalogo.obtener('hormiguero-del-arbol')!;
    progreso.pintarRegiones(hormiguero.id, [for (final r in hormiguero.regiones) r.id]);
    progreso.marcarCompletado(hormiguero.id);

    final nido = catalogo.obtener('nido-de-rocanon')!;
    await abrirPintar(tester, progreso, nido.id);
    // Todo pintado menos una región visible; se la pinta tocándola.
    final ultima = regionVisible(tester, nido);
    progreso.pintarRegiones(nido.id, [
      for (final r in nido.regiones)
        if (r.id != ultima.id) r.id,
    ]);
    await tester.pump();
    await tester.tap(find.byKey(Key('color-${ultima.numero}')));
    await tester.pump();
    await tester.tapAt(enPantalla(tester, nido, ultima.etiqueta));
    await tester.pump();

    expect(progreso.de(nido.id)!.terminado, isTrue);
    const ganadas = ReglasPlumas.porObra + ReglasPlumas.porBioma;
    expect(progreso.plumas, ganadas);
    expect(find.text(' +$ganadas plumas del Rocanón'), findsOneWidget);
    expect(find.text('Destapaste una parte de Árbol Mágico.'), findsOneWidget);

    // Festejo con confeti; el capítulo espera a que termine.
    expect(find.byType(Festejo), findsOneWidget);
    expect(find.text('¡Terminaste!'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('El Árbol Mágico'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.byType(Festejo), findsNothing);
    // Después, el timelapse de cómo se pintó; se saltea.
    expect(find.text('Así lo pintaste'), findsOneWidget);
    expect(find.text('El Árbol Mágico'), findsNothing);
    await tester.tap(find.byKey(const Key('saltear')));
    await tester.pumpAndSettle();
    expect(find.text('El Árbol Mágico'), findsOneWidget); // capítulo de la historia
    expect(progreso.capitulosVistos, {'arbol-magico'});
  });

  testWidgets('Mis obras: en progreso y terminadas, y se pueden retomar', (tester) async {
    usarTelefono(tester);
    final progreso = await progresoNuevo();
    final nido = catalogo.obtener('nido-de-rocanon')!;
    progreso.pintarRegion(nido.id, nido.regiones.first.id);
    final hormiguero = catalogo.obtener('hormiguero-del-arbol')!;
    progreso.pintarRegiones(hormiguero.id, [for (final r in hormiguero.regiones) r.id]);
    progreso.marcarCompletado(hormiguero.id);

    await tester.pumpWidget(App(catalogo: catalogo, progreso: progreso));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pintar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mis obras').last);
    await tester.pumpAndSettle();

    expect(find.text('En progreso (1)'), findsOneWidget);
    expect(find.text('Terminadas (1)'), findsOneWidget);
    final pct = porcentaje(1, nido.regiones.length);
    expect(find.bySemanticsLabel('${nido.meta.titulo}, $pct%'), findsOneWidget);
    expect(find.bySemanticsLabel('${hormiguero.meta.titulo}, terminada'), findsOneWidget);
    expect(find.text('Ver cómo lo pinté'), findsOneWidget); // solo en la terminada

    await tester.tap(find.bySemanticsLabel('${nido.meta.titulo}, $pct%'));
    await tester.pumpAndSettle();
    expect(find.text('$pct% con color'), findsOneWidget);
  });

  testWidgets('el mapa lista los lugares con su estado', (tester) async {
    usarTelefono(tester);
    final progreso = await progresoNuevo();
    await tester.pumpWidget(App(catalogo: catalogo, progreso: progreso));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mapa de Gramonia'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('0 de 2 partes recuperadas'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('0 de 2 partes recuperadas'), findsOneWidget);
  });

  testWidgets('créditos desde la portada y desde el menú', (tester) async {
    usarTelefono(tester);
    final progreso = await progresoNuevo();
    await tester.pumpWidget(App(catalogo: catalogo, progreso: progreso));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créditos'));
    await tester.pumpAndSettle();
    expect(find.text('Iván y Regi (Regina Knopoff)'), findsOneWidget);
    expect(find.text('Hecha con Gemini Lyria'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pintar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créditos'));
    await tester.pumpAndSettle();
    expect(find.text('Con ayuda de Claude'), findsOneWidget);
  });

  testWidgets('timelapse: termina solo y se puede volver a ver desde el panel final', (
    tester,
  ) async {
    final progreso = await progresoNuevo();
    final nido = catalogo.obtener('nido-de-rocanon')!;
    progreso.pintarRegiones(nido.id, [for (final r in nido.regiones.reversed) r.id]);
    progreso.marcarCompletado(nido.id);
    await abrirPintar(tester, progreso, nido.id);
    await tester.tap(find.text('Ver cómo lo pinté'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Así lo pintaste'), findsOneWidget);
    await tester.pump(Timelapse.maximo);
    await tester.pumpAndSettle();
    expect(find.text('Así lo pintaste'), findsNothing); // volvió solo
    expect(find.byType(Pintar), findsOneWidget);
  });
}
