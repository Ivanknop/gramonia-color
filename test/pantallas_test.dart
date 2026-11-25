/// Pruebas de las pantallas con el catálogo real (sin ilustraciones: en los
/// tests se dibuja con colores planos) y el progreso en memoria, en una
/// pantalla de teléfono vertical.
library;

import 'package:colores_de_gramonia/datos/biomas.dart';
import 'package:colores_de_gramonia/datos/catalogo.dart';
import 'package:colores_de_gramonia/engine/genero.dart';
import 'package:colores_de_gramonia/engine/intro.dart';
import 'package:colores_de_gramonia/engine/motor.dart';
import 'package:colores_de_gramonia/engine/timelapse.dart';
import 'package:colores_de_gramonia/estado/progreso.dart';
import 'package:colores_de_gramonia/main.dart';
import 'package:colores_de_gramonia/ui/comun.dart';
import 'package:colores_de_gramonia/ui/festejo.dart';
import 'package:colores_de_gramonia/ui/pantallas/pintar.dart';
import 'package:colores_de_gramonia/ui/pintor_cuadro.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'ayuda.dart';

final Catalogo catalogo = catalogoDeDisco();

/// Progreso en blanco. Con [introVista], también con el género elegido y los
/// tutoriales salteados (salvo que [tutorialPasado] o [tutorialTienda] digan
/// otra cosa).
Future<Progreso> progresoNuevo({
  bool introVista = true,
  bool? tutorialPasado,
  bool? tutorialTienda,
}) async {
  final p = await Progreso.cargar(AlmacenEnMemoria());
  if (introVista) {
    p.marcarIntroVista();
    p.elegirGenero(Genero.neutro);
    p.cambiarNombre('Regi');
  }
  if (tutorialPasado ?? introVista) p.saltarTutorial();
  if (tutorialTienda ?? introVista) p.terminarTutorialTienda();
  return p;
}

/// Desde la portada, entra al modo historia (con el tutorial ya pasado, a la galería).
Future<void> entrarALaHistoria(WidgetTester tester) async {
  await tester.tap(find.text('Modo historia'));
  await tester.pumpAndSettle();
}

/// Pinta todo [cuadro] menos una región visible, que se pinta tocándola.
Future<void> terminarTocando(
  WidgetTester tester,
  Progreso progreso,
  String clave,
  Cuadro cuadro,
) async {
  final ultima = regionVisible(tester, cuadro, sin: {...?progreso.de(clave)?.pintadas});
  progreso.pintarRegiones(clave, [
    for (final r in cuadro.regiones)
      if (r.id != ultima.id) r.id,
  ]);
  await tester.pump();
  await tester.tap(find.byKey(Key('color-${ultima.numero}')));
  await tester.pump();
  await tester.tapAt(enPantalla(tester, cuadro, ultima.etiqueta));
  await tester.pump();
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
  testWidgets('intro: el mapa se apaga y aparece el título en dos tiempos', (tester) async {
    usarTelefono(tester);
    final progreso = await progresoNuevo(introVista: false);
    await tester.pumpWidget(App(catalogo: catalogo, progreso: progreso));
    double opacidad(String texto) => tester
        .widget<Opacity>(
          find.ancestor(of: find.text(texto).last, matching: find.byType(Opacity)).first,
        )
        .opacity;
    // Al principio, a color y sin título.
    expect(opacidad('Gramonia...'), 0);
    await tester.pump(
      Duration(milliseconds: ((Intro.inicioGramonia + Intro.aparicion) * 1000).round()),
    );
    // Ya en gris: "Gramonia…" sí, "Color" todavía no.
    expect(opacidad('Gramonia...'), closeTo(1, 1e-6));
    expect(opacidad('a Color'), 0);
    await tester.pumpAndSettle();
    expect(opacidad('a Color'), closeTo(1, 1e-6));
    expect(find.text('Modo historia'), findsOneWidget);
    expect(find.text('Modo libre'), findsOneWidget);
    expect(find.text('Créditos'), findsOneWidget);
  });

  testWidgets('primera vez: el modo historia cuenta la historia, pregunta el género y '
      'arranca el tutorial, que se puede saltear', (tester) async {
    usarTelefono(tester);
    final progreso = await progresoNuevo(introVista: false);
    await tester.pumpWidget(App(catalogo: catalogo, progreso: progreso));
    await tester.pump(const Duration(milliseconds: 500));
    // Tocar durante la animación la saltea: título y botones de una.
    await tester.tapAt(const Offset(180, 700));
    await tester.pump();
    await entrarALaHistoria(tester);
    expect(find.text('Saltar'), findsOneWidget); // la historia de Gobi
    await tester.tap(find.text('Saltar'));
    await tester.pumpAndSettle();
    expect(progreso.introVista, isTrue);
    // Perfil: nombre y cómo hablarle; "Listo" recién con las dos cosas.
    expect(find.text('¿Cómo te llamás?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('genero-chica')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('perfil-listo')));
    await tester.pumpAndSettle();
    expect(progreso.genero, isNull); // falta el nombre: no se guardó nada
    await tester.enterText(find.byKey(const Key('nombre')), '  Regi  ');
    await tester.pump();
    await tester.tap(find.byKey(const Key('perfil-listo')));
    await tester.pumpAndSettle();
    expect((progreso.nombre, progreso.genero), ('Regi', Genero.chica));
    // El tutorial (nivel 0).
    expect(find.byType(Pintar), findsOneWidget);
    expect(find.text('Elegí un color de la paleta de abajo.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('saltar-tutorial')));
    await tester.pumpAndSettle();
    expect(find.text('Nivel 1'), findsWidgets); // la galería
    expect((progreso.tutorialPasado, progreso.tutorialPremiado), (true, false));
    expect(progreso.plumas, ReglasPlumas.porDia);
    expect(find.text('Hacer el tutorial'), findsOneWidget);
    expect(find.text('La primera vez que lo terminás, ganás 20 plumas.'), findsOneWidget);
  });

  testWidgets('con el tutorial pasado, el modo historia abre la galería; la flecha vuelve '
      'a la portada', (tester) async {
    usarTelefono(tester);
    final progreso = await progresoNuevo();
    await tester.pumpWidget(App(catalogo: catalogo, progreso: progreso));
    await tester.pumpAndSettle();
    await entrarALaHistoria(tester);
    expect(find.text('Nivel 1'), findsWidgets);
    await tester.tap(find.text('Portada'));
    await tester.pumpAndSettle();
    expect(find.text('Modo historia'), findsOneWidget);
    await tester.tap(find.text('Modo libre'));
    await tester.pumpAndSettle();
    expect(find.text('Modo libre'), findsOneWidget); // el título
    await tester.tap(find.byKey(const Key('volver-a-portada')));
    await tester.pumpAndSettle();
    expect(find.text('Modo historia'), findsOneWidget);
  });

  testWidgets('tutorial: pasos obligatorios en orden, lupa y bomba gratis, y al terminar '
      'nivel 1, 20 plumas y 3 lupas y 3 bombas', (tester) async {
    final progreso = await progresoNuevo(tutorialPasado: false);
    progreso.reclamarRecompensaDiaria();
    await abrirPintar(tester, progreso, idTutorial);
    final cuadro = catalogo.obtener(idTutorial)!;
    expect(cuadro.paleta, hasLength(5));
    expect(find.text('Elegí un color de la paleta de abajo.'), findsOneWidget);

    // Paso 1: antes de elegir color, ni el dibujo ni la bomba responden.
    final r = regionVisible(tester, cuadro);
    await tester.tap(find.byKey(const Key('bomba')));
    await tester.pump();
    expect(find.text('Tocá el dibujo donde quieras tirar la bomba de color.'), findsNothing);
    await tester.tap(find.byKey(Key('color-${r.numero}')));
    await tester.pump();
    expect(find.textContaining('hasta pintarlas todas'), findsOneWidget);

    // Paso 2: la lupa todavía no responde; se pinta hasta completar el color.
    await tester.tap(find.byKey(const Key('lupa')));
    await tester.pump();
    expect(find.text('Tocá un color y la lupa te muestra una parte que falta.'), findsNothing);
    progreso.pintarRegiones(idTutorial, [
      for (final o in cuadro.regiones)
        if (o.numero == r.numero && o.id != r.id) o.id,
    ]);
    await tester.pump();
    await tester.tapAt(enPantalla(tester, cuadro, r.etiqueta));
    await tester.pump();
    expect(find.textContaining('Tocá la lupa (se enciende)'), findsOneWidget);

    // Paso 3: pintar no vale; la lupa se enciende y se usa tocando un color.
    final pintadasAntes = progreso.de(idTutorial)!.pintadas.length;
    final otra = regionVisible(tester, cuadro, sin: progreso.de(idTutorial)!.pintadas.toSet());
    await tester.tap(find.byKey(Key('color-${otra.numero}')));
    await tester.pump();
    await tester.tapAt(enPantalla(tester, cuadro, otra.etiqueta));
    await tester.pump();
    expect(progreso.de(idTutorial)!.pintadas, hasLength(pintadasAntes));
    await tester.tap(find.byKey(const Key('lupa')));
    await tester.pump();
    expect(find.text('Tocá un color y la lupa te muestra una parte que falta.'), findsOneWidget);
    // Un color completo no gasta la lupa: sigue encendida.
    await tester.tap(find.byKey(Key('color-${r.numero}')));
    await tester.pump();
    expect(find.text('Tocá un color y la lupa te muestra una parte que falta.'), findsOneWidget);
    await tester.tap(find.byKey(Key('color-${otra.numero}')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ahora la bomba de color'), findsOneWidget);
    // Con partes grandes, la lupa puede no hacer zoom; si lo hizo, se vuelve a encuadrar.
    if (find.text('Encuadrar').evaluate().isNotEmpty) {
      await tester.tap(find.text('Encuadrar'));
      await tester.pumpAndSettle();
    }

    // Paso 4: la bomba se enciende, se apaga y se vuelve a encender; después, al dibujo.
    await tester.tap(find.byKey(const Key('bomba')));
    await tester.pump();
    expect(find.text('Tocá el dibujo donde quieras tirar la bomba de color.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('bomba')));
    await tester.pump();
    expect(find.text('Tocá el dibujo donde quieras tirar la bomba de color.'), findsNothing);
    await tester.tap(find.byKey(const Key('bomba')));
    await tester.pump();
    final pendiente = regionVisible(tester, cuadro, sin: progreso.de(idTutorial)!.pintadas.toSet());
    await tester.tapAt(enPantalla(tester, cuadro, pendiente.etiqueta));
    await tester.pump();
    expect(find.text('¡Muy bien! Terminá de pintar el Árbol.'), findsOneWidget);
    // En el tutorial no se gastan (ni hacen falta) lupas y bombas.
    expect((progreso.cantidad(Herramienta.lupa), progreso.cantidad(Herramienta.bomba)), (0, 0));
    await tester.pump(const Duration(seconds: 4)); // se apaga el destacado de la lupa
    tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger)).removeCurrentSnackBar();
    await tester.pumpAndSettle();

    await terminarTocando(tester, progreso, idTutorial, cuadro);
    expect(progreso.de(idTutorial)!.terminado, isTrue);
    expect((progreso.tutorialPasado, progreso.tutorialPremiado), (true, true));
    expect(progreso.plumas, ReglasPlumas.porDia + ReglasPlumas.porTutorial);
    expect((progreso.cantidad(Herramienta.lupa), progreso.cantidad(Herramienta.bomba)), (3, 3));
    expect(find.text('¡Llegaste al nivel 1!'), findsOneWidget);
    expect(find.text(' +20 plumas del Rocanón'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.tap(find.byKey(const Key('saltear')));
    await tester.pumpAndSettle();
    // Gobi cuenta que empieza la historia, con el nombre de quien juega.
    expect(find.text('¡Nivel 1!'), findsOneWidget);
    expect(find.textContaining('¡Ya sabés pintar, Regi!'), findsOneWidget);
    await tester.tap(find.text('Seguir'));
    await tester.pumpAndSettle();
    expect(find.text('¡A la historia!'), findsOneWidget);
    expect(progreso.capitulosVistos, {'nivel-0'});
  });

  testWidgets('tutorial: volver a hacerlo desde la galería ya no da premio', (tester) async {
    usarTelefono(tester);
    final progreso = await progresoNuevo();
    progreso.reclamarRecompensaDiaria();
    final cuadro = catalogo.obtener(idTutorial)!;
    progreso.pintarRegiones(idTutorial, [for (final r in cuadro.regiones) r.id]);
    progreso.marcarCompletado(idTutorial);
    progreso.terminarTutorial();
    final plumas = progreso.plumas;
    await tester.pumpWidget(App(catalogo: catalogo, progreso: progreso));
    await tester.pumpAndSettle();
    await entrarALaHistoria(tester);
    await tester.tap(find.text('Volver a hacer'));
    await tester.pumpAndSettle();
    expect(find.text('0% con color'), findsOneWidget);
    await terminarTocando(tester, progreso, idTutorial, cuadro);
    expect(progreso.de(idTutorial)!.terminado, isTrue);
    expect(progreso.plumas, plumas);
    expect(find.text('¡Muy bien! Ya te acordás de todo.'), findsOneWidget);
    expect(find.textContaining('Llegaste'), findsNothing);
    await tester.pump(const Duration(seconds: 4));
    await tester.tap(find.byKey(const Key('saltear')));
    await tester.pumpAndSettle();
  });

  testWidgets('galería por lugares: el primero abierto, el siguiente bloqueado', (tester) async {
    usarTelefono(tester);
    final progreso = await progresoNuevo();
    await tester.pumpWidget(App(catalogo: catalogo, progreso: progreso));
    await tester.pumpAndSettle();
    await entrarALaHistoria(tester);
    expect(find.text('Árbol Mágico'), findsOneWidget);
    expect(find.text('Nivel 1'), findsWidgets); // el actual y el encabezado
    expect(find.text('0 de 3 obras para llegar al nivel 2'), findsOneWidget);
    expect(
      find.text('Se desbloquea al terminar el nivel anterior', skipOffstage: false),
      findsWidgets,
    );
    // Una obra del Bosque (bloqueado) no se abre.
    await tester.scrollUntilVisible(
      find.text('El hormiguero del árbol'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('El hormiguero del árbol'));
    await tester.pumpAndSettle();
    expect(find.byType(Pintar), findsNothing);
    // Una del Árbol sí.
    await tester.scrollUntilVisible(
      find.text('El nido del Rocanón'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('El nido del Rocanón'));
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

  testWidgets('la bomba se enciende y se apaga; encendida, pinta varias regiones y gasta una', (
    tester,
  ) async {
    final progreso = await progresoNuevo();
    // Al llegar al nivel 1 se regalan 3 lupas y 3 bombas.
    expect(progreso.cantidad(Herramienta.bomba), 3);
    await abrirPintar(tester, progreso, 'nido-de-rocanon');
    final cuadro = catalogo.obtener('nido-de-rocanon')!;
    // Solo el ícono, con un globito que dice cuántas quedan.
    expect(find.descendant(of: find.byKey(const Key('bomba')), matching: find.text('3')), findsOne);
    await tester.tap(find.byKey(const Key('bomba')));
    await tester.pump();
    expect(find.textContaining('tirar la bomba'), findsOneWidget);
    await tester.tap(find.byKey(const Key('bomba'))); // se apaga sin gastar
    await tester.pump();
    expect(find.textContaining('tirar la bomba'), findsNothing);
    await tester.tapAt(areaVisible(tester).center);
    await tester.pump();
    expect(progreso.cantidad(Herramienta.bomba), 3);
    await tester.tap(find.byKey(const Key('bomba')));
    await tester.pump();
    await tester.tapAt(areaVisible(tester).center);
    await tester.pump();
    expect(progreso.de(cuadro.id)!.pintadas.length, greaterThan(1));
    expect(find.textContaining('tirar la bomba'), findsNothing);
    expect(progreso.cantidad(Herramienta.bomba), 2);
    // Sin bombas no se enciende: avisa que se consiguen en la tienda.
    while (progreso.usar(Herramienta.bomba)) {}
    await tester.pump();
    await tester.tap(find.byKey(const Key('bomba')));
    await tester.pump();
    expect(find.textContaining('tirar la bomba'), findsNothing);
    expect(find.text('No te quedan bombas. Conseguí más en la Tienda.'), findsOneWidget);
  });

  testWidgets('la lupa se enciende y, al tocar un color, acerca la vista a una parte que falta', (
    tester,
  ) async {
    final progreso = await progresoNuevo();
    await abrirPintar(tester, progreso, 'nido-de-rocanon');
    final antes = tester.getRect(find.byKey(const Key('lienzo')));
    await tester.tap(find.byKey(const Key('lupa')));
    await tester.pump();
    expect(find.text('Tocá un color y la lupa te muestra una parte que falta.'), findsOneWidget);
    // Apagarla no gasta.
    await tester.tap(find.byKey(const Key('lupa')));
    await tester.pump();
    expect(find.text('Tocá un color y la lupa te muestra una parte que falta.'), findsNothing);
    expect(progreso.cantidad(Herramienta.lupa), 3);
    await tester.tap(find.byKey(const Key('lupa')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('color-2')));
    await tester.pumpAndSettle();
    final despues = tester.getRect(find.byKey(const Key('lienzo')));
    expect(despues.width, greaterThan(antes.width)); // hizo zoom
    expect(find.text('Encuadrar'), findsOneWidget);
    expect(progreso.cantidad(Herramienta.lupa), 2);
    expect(find.text('Tocá un color y la lupa te muestra una parte que falta.'), findsNothing);
    await tester.pump(const Duration(seconds: 4)); // se apaga el destacado
  });

  testWidgets('terminar la última obra del Árbol: festejo, plumas y capítulo del nivel', (
    tester,
  ) async {
    final progreso = await progresoNuevo();
    // Las otras obras del Árbol, ya terminadas.
    for (final id in biomas.first.cuadroIds.where((id) => id != 'nido-de-rocanon')) {
      final c = catalogo.obtener(id)!;
      progreso.pintarRegiones(id, [for (final r in c.regiones) r.id]);
      progreso.marcarCompletado(id);
    }

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
    // Última obra del Árbol: se completa el nivel 1 y se pasa al 2.
    const ganadas = ReglasPlumas.porObra + ReglasPlumas.porNivel;
    expect(progreso.plumas, ganadas);
    expect(find.text(' +$ganadas plumas del Rocanón'), findsOneWidget);
    expect(find.text('¡Llegaste al nivel 2!'), findsOneWidget);
    expect(find.text('Destapaste una parte del Árbol Mágico.'), findsOneWidget);

    // Festejo con confeti; el capítulo espera a que termine.
    expect(find.byType(Festejo), findsOneWidget);
    expect(find.text('¡Terminaste!'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('¡Nivel 2!'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.byType(Festejo), findsNothing);
    // Después, el timelapse de cómo se pintó; se saltea.
    expect(find.text('Así lo pintaste'), findsOneWidget);
    expect(find.text('¡Nivel 2!'), findsNothing);
    await tester.tap(find.byKey(const Key('saltear')));
    await tester.pumpAndSettle();
    // Gobi habla solo al completar el nivel (no hay capítulo del lugar).
    expect(find.text('¡Nivel 2!'), findsOneWidget);
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Mututu anda cerca'), findsOneWidget);
    expect(progreso.capitulosVistos, {'nivel-1'});
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
    await entrarALaHistoria(tester);
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
    await entrarALaHistoria(tester);
    await tester.tap(find.text('Mapa'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('0 de ${biomas.first.piezas.length} partes recuperadas'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('0 de ${biomas.first.piezas.length} partes recuperadas'), findsOneWidget);
  });

  testWidgets('créditos desde la portada y desde el menú', (tester) async {
    usarTelefono(tester);
    final progreso = await progresoNuevo();
    await tester.pumpWidget(App(catalogo: catalogo, progreso: progreso));
    await tester.pumpAndSettle();
    // En la portada, "Créditos" es solo texto (un enlace), sin botón.
    expect(find.byKey(const Key('enlace-creditos')), findsOneWidget);
    expect(
      find.ancestor(of: find.text('Créditos'), matching: find.byType(TextButton)),
      findsNothing,
    );
    await tester.tap(find.text('Créditos'));
    await tester.pumpAndSettle();
    expect(find.text('Gramonia a Color'), findsWidgets);
    expect(find.text('Guion y desarrollo'), findsOneWidget);
    expect(find.text('Iván y Regina Knopoff'), findsOneWidget);
    expect(find.text('Imágenes y Música'), findsOneWidget);
    expect(find.text('Gemini'), findsOneWidget);
    expect(find.byKey(const Key('fondo-creditos')), findsOneWidget);
    // El enlace al blog abre el navegador por el canal nativo.
    final abiertos = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('gramonia/enlaces'),
      (llamada) async {
        abiertos.add(llamada.arguments);
        return true;
      },
    );
    await tester.tap(find.byKey(const Key('enlace-cuentos')));
    await tester.pumpAndSettle();
    expect(abiertos, [
      {'url': 'https://cuentosdegramonia.substack.com/'},
    ]);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await entrarALaHistoria(tester);
    await tester.tap(find.byKey(const Key('menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créditos'));
    await tester.pumpAndSettle();
    expect(find.text('Claude'), findsOneWidget);
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
    // "Repetir" la vuelve a empezar: casi al final, se reinicia y sigue en pantalla.
    await tester.pump(Timelapse.maximo - const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const Key('repetir')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Así lo pintaste'), findsOneWidget);
    await tester.pump(Timelapse.maximo);
    await tester.pumpAndSettle();
    expect(find.text('Así lo pintaste'), findsNothing); // volvió solo
    expect(find.byType(Pintar), findsOneWidget);
  });

  testWidgets(
    'modo libre: elegir dibujo y dificultad, pintar con las plumas de la dificultad y sin piezas',
    (tester) async {
      usarTelefono(tester);
      final progreso = await progresoNuevo();
      // Una obra de la historia ya coloreada; el nido, todavía no.
      final copa = catalogo.obtener('arbol-magico-de-noche')!;
      progreso.pintarRegiones(copa.id, [for (final r in copa.regiones) r.id]);
      progreso.marcarCompletado(copa.id);
      await tester.pumpWidget(App(catalogo: catalogo, progreso: progreso));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Modo libre'));
      await tester.pumpAndSettle();
      // Los de solo modo libre y los ya coloreados en la historia.
      expect(find.bySemanticsLabel('El Árbol Mágico de noche'), findsOneWidget);
      expect(find.bySemanticsLabel('El nido del Rocanón'), findsNothing);
      expect(find.bySemanticsLabel('La casa de la abuelita'), findsNothing);
      await tester.scrollUntilVisible(find.bySemanticsLabel('El petirrojo'), 300);

      await tester.tap(find.bySemanticsLabel('El petirrojo'));
      await tester.pumpAndSettle();
      expect(find.text('¿Qué tan difícil lo querés?'), findsOneWidget);
      // Cada dificultad muestra las plumas que da: de +1 a +100.
      expect(
        find.descendant(of: find.byKey(const Key('plumas-super-facil')), matching: find.text('+1')),
        findsOneWidget,
      );
      final hoja = find.byType(Scrollable).last;
      await tester.scrollUntilVisible(
        find.byKey(const Key('plumas-divino')),
        200,
        scrollable: hoja,
      );
      expect(
        find.descendant(of: find.byKey(const Key('plumas-divino')), matching: find.text('+100')),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('dificultad-super-facil')),
        -200,
        scrollable: hoja,
      );
      await tester.tap(find.byKey(const Key('dificultad-super-facil')));
      await tester.pumpAndSettle();
      expect(find.text('El petirrojo · Súper fácil'), findsOneWidget);
      const clave = 'el-petirrojo--super-facil';
      final v = catalogo.obtener(clave)!;
      expect(v.paleta, hasLength(4));
      for (var n = 1; n <= 4; n++) {
        expect(find.byKey(Key('color-$n')), findsOneWidget);
      }
      expect(find.byKey(const Key('color-5')), findsNothing);

      // Terminar: todo pintado menos una región visible, que se toca.
      final ultima = regionVisible(tester, v);
      progreso.pintarRegiones(clave, [
        for (final r in v.regiones)
          if (r.id != ultima.id) r.id,
      ]);
      await tester.pump();
      await tester.tap(find.byKey(Key('color-${ultima.numero}')));
      await tester.pump();
      await tester.tapAt(enPantalla(tester, v, ultima.etiqueta));
      await tester.pump();
      expect(progreso.de(clave)!.terminado, isTrue);
      expect(find.byType(Festejo), findsOneWidget);
      // El modo libre da las plumas de la dificultad (pero no niveles): Súper fácil, 1.
      expect(progreso.plumas, ReglasPlumas.porDia + 1);
      expect(find.text(' +1 plumas del Rocanón'), findsOneWidget);
      expect(progreso.completados.contains('el-petirrojo'), isFalse); // no es de la historia
      expect(find.text('¡Obra terminada! Quedó hermosa.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.tap(find.byKey(const Key('saltear')));
      await tester.pumpAndSettle();

      // Vuelve a elegir otro y la obra queda en Mis obras con su dificultad.
      await tester.tap(find.text('Elegir otro dibujo'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('volver-a-portada')));
      await tester.pumpAndSettle();
      await entrarALaHistoria(tester);
      await tester.tap(find.text('Mis obras').last);
      await tester.pumpAndSettle();
      expect(find.text('Modo libre · Súper fácil'), findsOneWidget);
    },
  );

  testWidgets('rehacer en Mis obras: otra dificultad, en blanco y sin perder el desbloqueo', (
    tester,
  ) async {
    usarTelefono(tester);
    final progreso = await progresoNuevo();
    progreso.reclamarRecompensaDiaria(); // sin el aviso de plumas tapando botones
    final arbol = biomas.first.cuadroIds.toList();
    for (final id in arbol) {
      final c = catalogo.obtener(id)!;
      progreso.pintarRegiones(id, [for (final r in c.regiones) r.id]);
      progreso.marcarCompletado(id);
    }
    await tester.pumpWidget(App(catalogo: catalogo, progreso: progreso));
    await tester.pumpAndSettle();
    await entrarALaHistoria(tester);
    await tester.tap(find.text('Mis obras').last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('rehacer-nido-de-rocanon')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    // Centrado, para que no quede debajo de la barra de navegación.
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('rehacer-nido-de-rocanon'))),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rehacer-nido-de-rocanon')));
    await tester.pumpAndSettle();
    expect(find.text('¿En qué dificultad la volvés a pintar?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('dificultad-facil')));
    await tester.pumpAndSettle();

    // Se pinta la variante Fácil, en blanco; el Bosque sigue desbloqueado.
    expect(find.text('El nido del Rocanón · Fácil'), findsOneWidget);
    expect(find.text('0% con color'), findsOneWidget);
    expect(find.byKey(const Key('color-6')), findsOneWidget);
    expect(find.byKey(const Key('color-7')), findsNothing);
    final obra = progreso.de('nido-de-rocanon')!;
    expect((obra.terminado, obra.dificultad), (false, 'facil'));
    expect(progreso.completados, containsAll(arbol));
    expect(estadoBiomas(biomas, progreso.completados)[1].accesible, isTrue);

    // Terminarla de nuevo: festejo, pero sin plumas extra ni pieza nueva.
    final v = catalogo.obtener('nido-de-rocanon--facil')!;
    final plumas = progreso.plumas;
    final ultima = regionVisible(tester, v);
    progreso.pintarRegiones('nido-de-rocanon', [
      for (final r in v.regiones)
        if (r.id != ultima.id) r.id,
    ]);
    await tester.pump();
    await tester.tap(find.byKey(Key('color-${ultima.numero}')));
    await tester.pump();
    await tester.tapAt(enPantalla(tester, v, ultima.etiqueta));
    await tester.pump();
    expect(progreso.de('nido-de-rocanon')!.terminado, isTrue);
    expect(find.byType(Festejo), findsOneWidget);
    expect(progreso.plumas, plumas + ReglasPlumas.porObra); // plumas sí; pieza no
    expect(find.textContaining('Destapaste'), findsNothing);
    await tester.pump(const Duration(seconds: 4));
    await tester.tap(find.byKey(const Key('saltear')));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    // Vuelve a Mis obras: la rehecha, ahora la terminada más reciente, arriba.
    await tester.scrollUntilVisible(
      find.text('Rehecha · Fácil'),
      -300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Rehecha · Fácil'), findsOneWidget);
  });

  testWidgets('tienda: comprar lupas y bombas con plumas', (tester) async {
    usarTelefono(tester);
    final progreso = await progresoNuevo();
    progreso.reclamarRecompensaDiaria();
    progreso.sumarPlumas(10); // 15 en total
    await tester.pumpWidget(App(catalogo: catalogo, progreso: progreso));
    await tester.pumpAndSettle();
    await entrarALaHistoria(tester);
    await tester.tap(find.text('Tienda').last);
    await tester.pumpAndSettle();
    expect(find.text('«No explico mucho. Vendo.»'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('saldo-tienda'))).data, '15');

    // Arranca con el regalo del nivel 1: 3 de cada una.
    expect(find.text('Tenés 3'), findsNWidgets(2));

    // Cada compra se confirma: "Mejor no" no compra.
    await tester.tap(find.byKey(const Key('comprar-bomba')));
    await tester.pumpAndSettle();
    expect(find.text('¿Comprás una bomba de color por 10 plumas?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cancelar-compra')));
    await tester.pumpAndSettle();
    expect((progreso.plumas, progreso.cantidad(Herramienta.bomba)), (15, 3));

    // "¡Sí, comprar!" compra y muestra el cartelito.
    await tester.tap(find.byKey(const Key('comprar-bomba')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmar-compra')));
    await tester.pump();
    expect(find.text('¡Listo! Compraste una bomba de color. Ahora tenés 4.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('comprar-lupa')));
    await tester.pumpAndSettle();
    expect(find.text('¿Comprás una lupa por 5 plumas?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirmar-compra')));
    await tester.pumpAndSettle();
    expect(
      (progreso.plumas, progreso.cantidad(Herramienta.bomba), progreso.cantidad(Herramienta.lupa)),
      (0, 4, 4),
    );
    expect(find.text('Tenés 4'), findsNWidgets(2));

    // Sin plumas no compra (ni pregunta).
    await tester.tap(find.byKey(const Key('comprar-lupa')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('confirmar-compra')), findsNothing);
    expect(progreso.cantidad(Herramienta.lupa), 4);
    expect(find.text('Te faltan plumas. Terminá cuadros para juntar más.'), findsOneWidget);
  });

  testWidgets('al completar el nivel 1, el juego lleva a la tienda, regala 5 plumas y pide '
      'comprar una lupa', (tester) async {
    usarTelefono(tester);
    final progreso = await progresoNuevo(tutorialTienda: false);
    progreso.reclamarRecompensaDiaria();
    progreso.sumarPlumas(-progreso.plumas); // sin plumas propias
    final arbol = biomas.first.cuadroIds.toList();
    for (final id in arbol.skip(1)) {
      final c = catalogo.obtener(id)!;
      progreso.pintarRegiones(id, [for (final r in c.regiones) r.id]);
      progreso.marcarCompletado(id);
    }
    final ultima = catalogo.obtener(arbol.first)!;
    await abrirPintar(tester, progreso, ultima.id);
    await terminarTocando(tester, progreso, ultima.id, ultima);
    await tester.pump(const Duration(seconds: 4));
    await tester.tap(find.byKey(const Key('saltear')));
    await tester.pumpAndSettle();
    // Gobi cuenta los capítulos del lugar y del nivel.
    while (find.text('Siguiente').evaluate().isNotEmpty) {
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Seguir'));
    await tester.pumpAndSettle();
    final plumas = progreso.plumas;

    // El panel final lleva a la tienda.
    await tester.tap(find.text('¡A la tienda!'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tutorial-tienda')), findsOneWidget);
    expect(progreso.plumas, plumas + plumasTutorialTienda);
    // Las otras pestañas no responden hasta comprar la lupa (o saltear).
    await tester.tap(find.text('Mapa'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tutorial-tienda')), findsOneWidget);
    expect(find.text('Primero comprá la lupa (o tocá Saltar).'), findsOneWidget);
    tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger)).removeCurrentSnackBar();
    await tester.pumpAndSettle();
    final lupas = progreso.cantidad(Herramienta.lupa);
    await tester.tap(find.byKey(const Key('comprar-lupa')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmar-compra')));
    await tester.pumpAndSettle();
    expect(progreso.cantidad(Herramienta.lupa), lupas + 1);
    expect(progreso.tutorialTiendaHecho, isTrue);
    expect(find.byKey(const Key('tutorial-tienda')), findsNothing);
    // Ya se puede ir a cualquier pestaña.
    await tester.tap(find.text('Mapa'));
    await tester.pumpAndSettle();
    expect(find.text('Mapa de Gramonia'), findsWidgets);
  });

  testWidgets('el tutorial de la tienda se puede saltear (sin la lupa)', (tester) async {
    usarTelefono(tester);
    final progreso = await progresoNuevo(tutorialTienda: false);
    progreso.reclamarRecompensaDiaria();
    for (final id in biomas.first.cuadroIds) {
      final c = catalogo.obtener(id)!;
      progreso.pintarRegiones(id, [for (final r in c.regiones) r.id]);
      progreso.marcarCompletado(id);
    }
    await tester.pumpWidget(App(catalogo: catalogo, progreso: progreso));
    await tester.pumpAndSettle();
    await entrarALaHistoria(tester);
    expect(find.byKey(const Key('tutorial-tienda')), findsOneWidget);
    final lupas = progreso.cantidad(Herramienta.lupa);
    await tester.tap(find.byKey(const Key('saltar-tutorial-tienda')));
    await tester.pumpAndSettle();
    expect(progreso.tutorialTiendaHecho, isTrue);
    expect(progreso.cantidad(Herramienta.lupa), lupas);
    expect(find.byKey(const Key('tutorial-tienda')), findsNothing);
  });

  testWidgets('una obra que no completa el nivel da solo las plumas del cuadro', (tester) async {
    final progreso = await progresoNuevo();
    final primera = cuadrosDelRecorrido(biomas).first;
    await abrirPintar(tester, progreso, primera);
    await terminarTocando(tester, progreso, primera, catalogo.obtener(primera)!);
    expect(progreso.de(primera)!.terminado, isTrue);
    expect(progreso.plumas, ReglasPlumas.porObra);
    expect(find.textContaining('Llegaste'), findsNothing);
    await tester.pump(const Duration(seconds: 4)); // termina el festejo
    await tester.tap(find.byKey(const Key('saltear')));
    await tester.pumpAndSettle();
  });

  testWidgets('el perfil se puede editar desde el menú y desde la portada', (tester) async {
    usarTelefono(tester);
    final progreso = await progresoNuevo();
    await tester.pumpWidget(App(catalogo: catalogo, progreso: progreso));
    await tester.pumpAndSettle();
    await entrarALaHistoria(tester);
    await tester.tap(find.byKey(const Key('menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mi perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Regi'), findsOneWidget); // lo que ya estaba
    await tester.enterText(find.byKey(const Key('nombre')), 'Regina');
    await tester.tap(find.byKey(const Key('genero-chica')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('perfil-listo')));
    await tester.pumpAndSettle();
    expect((progreso.nombre, progreso.genero), ('Regina', Genero.chica));
    // Desde la portada; volver sin tocar "Listo" no cambia nada.
    await tester.tap(find.text('Portada'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('editar-perfil')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('nombre')), 'Otra');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(progreso.nombre, 'Regina');
  });

  testWidgets('portada: los lugares de los niveles completos no pierden el color', (tester) async {
    usarTelefono(tester);
    final progreso = await progresoNuevo();
    await tester.pumpWidget(App(catalogo: catalogo, progreso: progreso));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('portada-recuperada')), findsNothing);
    // Se completa el nivel 1 (el Árbol Mágico): su zona queda a color.
    for (final id in biomas.first.cuadroIds) {
      final c = catalogo.obtener(id)!;
      progreso.pintarRegiones(id, [for (final r in c.regiones) r.id]);
      progreso.marcarCompletado(id);
    }
    await tester.pump();
    expect(find.byKey(const Key('portada-recuperada')), findsOneWidget);
  });

  testWidgets('portada: los dos modos, créditos y la versión', (tester) async {
    usarTelefono(tester);
    final progreso = await progresoNuevo();
    await tester.pumpWidget(App(catalogo: catalogo, progreso: progreso));
    await tester.pumpAndSettle();
    final historia = tester.getRect(find.text('Modo historia'));
    final libre = tester.getRect(find.text('Modo libre'));
    expect(historia.center.dy, closeTo(libre.center.dy, 1)); // uno al lado del otro
    expect(find.text('v1.0.0'), findsOneWidget);
  });

  testWidgets('tienda: el Lobo, con la tienda de fondo', (tester) async {
    usarTelefono(tester);
    final progreso = await progresoNuevo();
    progreso.reclamarRecompensaDiaria();
    await tester.pumpWidget(App(catalogo: catalogo, progreso: progreso));
    await tester.pumpAndSettle();
    await entrarALaHistoria(tester);
    await tester.tap(find.text('Tienda').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lobo-tienda')), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is ResizeImage &&
            ((w.image as ResizeImage).imageProvider as AssetImage).assetName ==
                'assets/cuadros/la-tienda.webp',
      ),
      findsOneWidget,
    );
  });
}
