/// Capturas de las pantallas principales, con fuentes e ilustraciones reales,
/// para mirarlas sin teléfono. No es un test: se corre a mano y deja los PNG
/// en temp/ (ignorada por git):
///
///   flutter test tool/capturas_test.dart
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:colores_de_gramonia/datos/catalogo.dart';
import 'package:colores_de_gramonia/engine/dificultad.dart';
import 'package:colores_de_gramonia/engine/genero.dart';
import 'package:colores_de_gramonia/engine/motor.dart';
import 'package:colores_de_gramonia/estado/progreso.dart';
import 'package:colores_de_gramonia/main.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const carpeta = 'temp/capturas';
final fuentesMaterial =
    '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}'
    '/bin/cache/artifacts/material_fonts';

Future<void> cargarFuente(String familia, List<String> archivos) async {
  final cargador = FontLoader(familia);
  for (final a in archivos) {
    final bytes = File(a).readAsBytesSync();
    cargador.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await cargador.load();
}

Future<ui.Image?> decodificar(String asset) async {
  final archivo = File(asset);
  if (!archivo.existsSync()) return null;
  final codec = await ui.instantiateImageCodec(archivo.readAsBytesSync());
  return (await codec.getNextFrame()).image;
}

final imagenes = <String, ui.Image?>{};

/// Catálogo de disco, con las ilustraciones de verdad.
Catalogo catalogo() {
  final jsons = Directory('assets/cuadros')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'));
  return Catalogo.desdeTextos(
    [
      for (final j in jsons)
        (
          json: j.readAsStringSync(),
          svg: File(j.path.replaceFirst(RegExp(r'\.json$'), '.svg')).readAsStringSync(),
        ),
    ],
    conImagen: {
      for (final f in Directory('assets/cuadros').listSync())
        if (f.path.endsWith('.webp')) f.uri.pathSegments.last.replaceAll('.webp', ''),
    },
    // Ya decodificadas (con tiempo real, en setUpAll): dentro del test el
    // reloj es simulado y una decodificación larga no termina.
    cargarImagen: (asset) async => imagenes[asset],
    dificultades: leerDificultades(File(Catalogo.tablaDificultades).readAsStringSync()),
    leer: (asset) async => File(asset).readAsStringSync(),
  );
}

Future<Progreso> progreso({bool nuevo = false}) async {
  final p = await Progreso.cargar(AlmacenEnMemoria());
  p.reclamarRecompensaDiaria(); // sin el aviso de plumas tapando
  if (!nuevo) {
    p.marcarIntroVista();
    p.elegirGenero(Genero.chica);
    p.cambiarNombre('Regi');
    p.saltarTutorial();
  }
  return p;
}

/// Deja correr el tiempo real para que se decodifiquen las imágenes (hasta que
/// no quede ninguna rueda de "cargando", o unos segundos).
Future<void> asentar(WidgetTester t) async {
  for (var i = 0; i < 40; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
    await t.pump(const Duration(milliseconds: 100));
    if (i >= 3 && find.byType(CircularProgressIndicator).evaluate().isEmpty) return;
  }
}

Future<void> foto(WidgetTester t, String nombre) async {
  await asentar(t);
  final raiz = t.renderObject<RenderRepaintBoundary>(find.byType(RepaintBoundary).first);
  await t.runAsync(() async {
    final img = await raiz.toImage(pixelRatio: 2);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    File('$carpeta/$nombre.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(png!.buffer.asUint8List());
  });
}

/// Toca y deja pasar las transiciones (reloj simulado) y la carga de
/// ilustraciones (tiempo real).
Future<void> tocar(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pump(const Duration(milliseconds: 300));
  await t.tap(f);
  for (var i = 0; i < 8; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await t.pump(const Duration(milliseconds: 100));
  }
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
    cat = catalogo();
  });

  Future<void> abrirApp(WidgetTester t, Progreso p) async {
    // Un catálogo por test: guarda las cargas de imágenes, que son de cada test.
    cat = catalogo();
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(App(catalogo: cat, progreso: p));
    await t.pumpAndSettle();
  }

  testWidgets('primera vez: portada, historia, perfil y tutorial', (t) async {
    final p = await progreso(nuevo: true);
    await abrirApp(t, p);
    await foto(t, '01-portada');
    await tocar(t, find.text('Modo historia'));
    await foto(t, '02-historia-a-color');
    for (var i = 0; i < 4; i++) {
      await tocar(t, find.text('Siguiente'));
    }
    await foto(t, '03-historia-apagandose');
    await tocar(t, find.text('Saltar'));
    await t.enterText(find.byKey(const Key('nombre')), 'Regi');
    await tocar(t, find.byKey(const Key('genero-chica')));
    await foto(t, '04-perfil');
    await tocar(t, find.byKey(const Key('perfil-listo')));
    await foto(t, '05-tutorial-elegir-color');
    final tutorial = cat.obtener(idTutorial)!;
    await tocar(t, find.byKey(Key('color-${tutorial.paleta.first.numero}')));
    await foto(t, '06-tutorial-tocar-parte');
  });

  testWidgets('modo historia: galería, mis obras, mapa y tienda', (t) async {
    final p = await progreso();
    p.sumarPlumas(30);
    for (final id in ['nido-de-rocanon', 'arbol-magico-de-noche']) {
      p.pintarRegiones(id, [for (final r in cat.obtener(id)!.regiones) r.id]);
      p.marcarCompletado(id);
    }
    final copa = cat.obtener('rocanon-en-la-copa')!;
    p.pintarRegiones(copa.id, [for (final r in copa.regiones.take(40)) r.id]);
    await abrirApp(t, p);
    await tocar(t, find.text('Modo historia'));
    await foto(t, '07-galeria');
    await tocar(t, find.text('Mis obras').last);
    await foto(t, '08-mis-obras');
    await tocar(t, find.text('Mapa').last);
    await foto(t, '09-mapa');
    await tocar(t, find.text('Tienda').last);
    await foto(t, '10-tienda');
  });

  testWidgets('pintar, festejo, repetición, panel final y capítulos', (t) async {
    final p = await progreso();
    p.sumarPlumas(30);
    p.comprar(Herramienta.lupa);
    p.comprar(Herramienta.bomba);
    // Las otras dos obras del Árbol, hechas: el nido completa el nivel 1.
    for (final id in ['arbol-magico-de-noche', 'rocanon-en-la-copa']) {
      p.pintarRegiones(id, [for (final r in cat.obtener(id)!.regiones) r.id]);
      p.marcarCompletado(id);
    }
    final nido = cat.obtener('nido-de-rocanon')!;
    p.pintarRegiones(nido.id, [for (final r in nido.regiones.take(35)) r.id]);
    await abrirApp(t, p);
    await tocar(t, find.text('Modo historia'));
    await tocar(t, find.text('El nido del Rocanón'));
    await foto(t, '12-pintar');
    await tocar(t, find.byKey(const Key('bomba')));
    await foto(t, '13-bomba-armada');
    await tocar(t, find.byKey(const Key('bomba'))); // cancelar
    // Terminar: todo menos una región (de un color visible en la paleta), que se toca.
    final pendientes = [
      for (final r in nido.regiones)
        if (!p.de(nido.id)!.pintadas.contains(r.id)) r,
    ]..sort((a, b) => a.numero.compareTo(b.numero));
    final ultima = pendientes.first;
    p.pintarRegiones(nido.id, [for (final r in pendientes.skip(1)) r.id]);
    await t.pump();
    await t.tap(find.byKey(Key('color-${ultima.numero}')));
    await t.pump();
    final lienzo = t.getRect(find.byKey(const Key('lienzo')));
    final factor = lienzo.width / nido.ancho;
    await t.tapAt(lienzo.topLeft + Offset(ultima.etiqueta.x * factor, ultima.etiqueta.y * factor));
    await t.pump(const Duration(milliseconds: 700));
    await foto(t, '14-festejo');
    await t.pump(const Duration(seconds: 4));
    await t.pump(const Duration(seconds: 2));
    await foto(t, '15-asi-lo-pintaste');
    await tocar(t, find.byKey(const Key('saltear')));
    await foto(t, '16-capitulo-del-lugar');
    await tocar(t, find.text('Siguiente'));
    await foto(t, '17-capitulo-del-nivel');
    await tocar(t, find.text('Siguiente'));
    await foto(t, '18-capitulo-del-nivel-mututu');
    await tocar(t, find.text('Seguir'));
    await foto(t, '19-panel-final');
  });

  testWidgets('modo libre y créditos', (t) async {
    final p = await progreso();
    await abrirApp(t, p);
    await tocar(t, find.text('Modo libre'));
    await foto(t, '20-modo-libre');
    await tocar(t, find.bySemanticsLabel('El colibrí'));
    await foto(t, '21-elegir-dificultad');
    await tocar(t, find.byKey(const Key('dificultad-normal')));
    await foto(t, '22-pintar-modo-libre');
    await t.pageBack();
    await t.pumpAndSettle();
    await tocar(t, find.byKey(const Key('volver-a-portada')));
    await t.pump(const Duration(seconds: 3));
    await tocar(t, find.text('Créditos'));
    await foto(t, '23-creditos');
  });
}
