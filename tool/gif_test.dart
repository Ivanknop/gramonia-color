/// Graba la introducción (portada → pantalla de niveles) y el tutorial como secuencias de cuadros (PNG), con
/// las fuentes e ilustraciones reales, simulando a alguien que juega. No es un
/// test: se corre a mano y después `scripts/armar_gif.py` arma los GIF:
///
///   flutter test tool/gif_test.dart
///   python3 scripts/armar_gif.py        # → temp/gif/introduccion.gif, tutorial.gif
///
/// Cada secuencia queda en `temp/gif/<nombre>/` (ignorada por git) con un
/// cuadros.json que dice cuánto dura cada cuadro y dónde tocó el dedo.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:colores_de_gramonia/datos/catalogo.dart';
import 'package:colores_de_gramonia/engine/motor.dart';
import 'package:colores_de_gramonia/main.dart';
import 'package:colores_de_gramonia/ui/comun.dart';
import 'package:colores_de_gramonia/ui/pantallas/pintar.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'capturas_test.dart'
    show asentar, cargarFuente, catalogo, decodificar, fuentesMaterial, imagenes, progreso;

const carpetaGif = 'temp/gif';

/// Paso del reloj simulado entre cuadro y cuadro (10 cuadros por segundo).
const paso = Duration(milliseconds: 100);

class Grabador {
  Grabador(this.nombre) {
    final dir = Directory('$carpetaGif/$nombre');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
  }

  final String nombre;
  final _cuadros = <Map<String, Object>>[];

  /// Captura lo que se ve ahora; dura [ms] en el GIF. [dedo]: dónde se está
  /// tocando (en puntos de pantalla).
  Future<void> cuadro(WidgetTester t, {int ms = 100, Offset? dedo}) async {
    final raiz = t.renderObject<RenderRepaintBoundary>(find.byType(RepaintBoundary).first);
    final archivo = 'f${_cuadros.length.toString().padLeft(4, '0')}.png';
    await t.runAsync(() async {
      final img = await raiz.toImage(pixelRatio: 1);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$carpetaGif/$nombre/$archivo').writeAsBytesSync(png!.buffer.asUint8List());
    });
    _cuadros.add({
      'archivo': archivo,
      'ms': ms,
      if (dedo != null) 'dedo': [dedo.dx, dedo.dy],
    });
  }

  /// Deja correr [total] de tiempo simulado, capturando cada [paso]. Los
  /// primeros [conDedo] cuadros muestran el dedo en [dedo].
  Future<void> correr(WidgetTester t, Duration total, {Offset? dedo, int conDedo = 0}) async {
    final n = (total.inMilliseconds / paso.inMilliseconds).ceil();
    for (var i = 0; i < n; i++) {
      await t.pump(paso);
      await cuadro(t, dedo: i < conDedo ? dedo : null);
    }
  }

  Future<void> esperar(WidgetTester t, Duration espera) async {
    await t.pump(paso);
    await cuadro(t, ms: espera.inMilliseconds);
  }

  /// Toca en [p]: el dedo se ve un momento antes y durante el toque.
  Future<void> tocarEn(
    WidgetTester t,
    Offset p, {
    Duration despues = const Duration(milliseconds: 700),
  }) async {
    await cuadro(t, ms: 250, dedo: p);
    await t.tapAt(p);
    await correr(t, despues, dedo: p, conDedo: 2);
  }

  Future<void> tocar(
    WidgetTester t,
    Finder f, {
    Duration despues = const Duration(milliseconds: 700),
  }) => tocarEn(t, t.getCenter(f), despues: despues);

  void guardar() =>
      File('$carpetaGif/$nombre/cuadros.json')
          .writeAsStringSync(const JsonEncoder.withIndent(' ').convert({'cuadros': _cuadros}));
}

void main() {
  late Catalogo cat;

  setUpAll(() async {
    final roboto = [
      for (final peso in ['Regular', 'Medium', 'Bold', 'Black'])
        '$fuentesMaterial/Roboto-$peso.ttf',
    ];
    await cargarFuente('Roboto', roboto);
    await cargarFuente('MaterialIcons', ['$fuentesMaterial/MaterialIcons-Regular.otf']);
    await cargarFuente('LuckiestGuy', ['assets/fuentes/LuckiestGuy-Regular.ttf']);
    for (final f in [
      ...Directory('assets/cuadros').listSync().where((f) => f.path.endsWith('.webp')),
      File('assets/mapa/gramonia.webp'),
    ]) {
      imagenes[f.path] = await decodificar(f.path);
    }
  });

  void telefono(WidgetTester t) {
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
  }

  testWidgets('introducción: portada, modo historia y la pantalla de niveles', (t) async {
    telefono(t);
    cat = catalogo();
    final g = Grabador('introduccion');
    // Con el perfil y el tutorial hechos: "Modo historia" lleva a los niveles.
    final p = await progreso();
    await t.pumpWidget(App(catalogo: cat, progreso: p));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    // La portada: el mapa pierde los colores y aparece el título.
    await g.correr(t, const Duration(milliseconds: 6000));
    await g.esperar(t, const Duration(milliseconds: 1500));
    await g.tocar(t, find.text('Modo historia'), despues: const Duration(milliseconds: 500));
    await asentar(t);
    // La pantalla de niveles: se mira y se recorre un poco.
    await g.esperar(t, const Duration(milliseconds: 2500));
    final lista = find.byType(Scrollable).last;
    final centro = t.getCenter(lista);
    await g.cuadro(t, ms: 250, dedo: centro);
    await t.drag(lista, const Offset(0, -420));
    await g.correr(t, const Duration(milliseconds: 800), dedo: centro, conDedo: 2);
    await g.esperar(t, const Duration(milliseconds: 2500));
    g.guardar();
  });

  testWidgets('tutorial: color, completar, lupa, bomba y terminar', (t) async {
    telefono(t);
    cat = catalogo();
    final g = Grabador('tutorial');
    final p = await progreso(nuevo: true);
    p.marcarIntroVista();
    p.cambiarNombre('Regi');
    await t.pumpWidget(
      Dependencias(
        catalogo: cat,
        progreso: p,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: Tema.datos,
          home: const Pintar(cuadroId: idTutorial),
        ),
      ),
    );
    await asentar(t);
    final cuadro = cat.obtener(idTutorial)!;

    Offset enPantalla(Punto punto) {
      final rect = t.getRect(find.byKey(const Key('lienzo')));
      final factor = rect.width / cuadro.ancho;
      return rect.topLeft + Offset(punto.x * factor, punto.y * factor);
    }

    Set<String> pintadas() => {...?p.de(idTutorial)?.pintadas};
    List<Region> faltan(int numero) => [
      for (final r in cuadro.regiones)
        if (r.numero == numero && !pintadas().contains(r.id)) r,
    ];
    Future<void> elegir(int numero) =>
        g.tocar(t, find.byKey(Key('color-$numero')), despues: const Duration(milliseconds: 400));
    Future<void> pintarColor(
      int numero, {
      Duration entre = const Duration(milliseconds: 600),
    }) async {
      for (final r in faltan(numero)) {
        await g.tocarEn(t, enPantalla(r.etiqueta), despues: entre);
      }
    }

    // 1. Elegir un color: el que menos partes tiene, para completarlo rápido.
    await g.esperar(t, const Duration(milliseconds: 2500));
    final colores = [for (final c in cuadro.paleta) c.numero]
      ..sort((a, b) => faltan(a).length.compareTo(faltan(b).length));
    final primero = colores.first;
    await elegir(primero);
    await g.esperar(t, const Duration(milliseconds: 2500));

    // 2. Pintarlo entero.
    await pintarColor(primero);
    await g.esperar(t, const Duration(milliseconds: 3000));

    // 3. La lupa: se enciende y se toca un color con partes sin pintar.
    await g.tocar(t, find.byKey(const Key('lupa')));
    await g.esperar(t, const Duration(milliseconds: 1500));
    final segundo = colores.firstWhere((n) => faltan(n).isNotEmpty);
    await g.tocar(
      t,
      find.byKey(Key('color-$segundo')),
      despues: const Duration(milliseconds: 1800),
    );
    if (find.text('Encuadrar').evaluate().isNotEmpty) {
      await g.tocar(t, find.text('Encuadrar'), despues: const Duration(milliseconds: 800));
    }
    await g.esperar(t, const Duration(milliseconds: 2500));

    // 4. La bomba: se enciende y se tira sobre el dibujo.
    await g.tocar(t, find.byKey(const Key('bomba')));
    await g.esperar(t, const Duration(milliseconds: 1500));
    final pendientes = [
      for (final r in cuadro.regiones)
        if (!pintadas().contains(r.id)) r,
    ];
    // Donde haya más partes pendientes cerca: la del medio en altura.
    pendientes.sort((a, b) => a.etiqueta.y.compareTo(b.etiqueta.y));
    await g.tocarEn(
      t,
      enPantalla(pendientes[pendientes.length ~/ 2].etiqueta),
      despues: const Duration(milliseconds: 1500),
    );
    await g.esperar(t, const Duration(milliseconds: 2000));

    // 5. Terminar el dibujo, color por color.
    for (final n in colores) {
      if (faltan(n).isEmpty) continue;
      await elegir(n);
      await pintarColor(n, entre: const Duration(milliseconds: 400));
    }
    // Festejo y repetición de cómo se pintó.
    await g.correr(t, const Duration(milliseconds: 4500));
    await g.correr(t, const Duration(milliseconds: 4000));
    if (find.byKey(const Key('saltear')).evaluate().isNotEmpty) {
      await g.tocar(t, find.byKey(const Key('saltear')));
    }
    await asentar(t);
    // Gobi cuenta que empieza la historia.
    while (find.text('Siguiente').evaluate().isNotEmpty) {
      await g.esperar(t, const Duration(milliseconds: 3000));
      await g.tocar(t, find.text('Siguiente'), despues: const Duration(milliseconds: 500));
    }
    if (find.text('Seguir').evaluate().isNotEmpty) {
      await g.esperar(t, const Duration(milliseconds: 3000));
      await g.tocar(t, find.text('Seguir'));
    }
    await g.esperar(t, const Duration(milliseconds: 3500));
    g.guardar();
  });
}
