import 'dart:io';
import 'dart:math' as math;

import 'package:colores_de_gramonia/estado/musica.dart';
import 'package:colores_de_gramonia/estado/progreso.dart';
import 'package:colores_de_gramonia/ui/comun.dart';
import 'package:colores_de_gramonia/ui/pantallas/pintar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'ayuda.dart';

const temas = ['assets/musica/a.m4a', 'assets/musica/b.m4a', 'assets/musica/c.m4a'];

Future<(Musica, ReproductorDePrueba, Progreso)> nueva() async {
  final progreso = await Progreso.cargar(AlmacenEnMemoria());
  final reproductor = ReproductorDePrueba();
  final musica = Musica(
    temas: temas,
    reproductor: reproductor,
    progreso: progreso,
    azar: math.Random(1),
  );
  return (musica, reproductor, progreso);
}

void main() {
  test('elegirTema nunca repite el actual (si hay más de uno)', () {
    final azar = math.Random(3);
    for (var i = 0; i < 50; i++) {
      expect(elegirTema(temas, 'assets/musica/b.m4a', azar), isNot('assets/musica/b.m4a'));
    }
    expect(elegirTema(['solo'], 'solo', azar), 'solo');
  });

  test('nombreDeTema', () {
    expect(nombreDeTema('assets/musica/walking-for-gramonia.m4a'), 'Walking For Gramonia');
  });

  test('al abrir un dibujo suena un tema; cambiar elige otro distinto', () async {
    final (musica, reproductor, _) = await nueva();
    await musica.empezar();
    final primero = musica.actual!;
    expect(reproductor.llamadas, ['reproducir $primero']);
    await musica.cambiar();
    expect(musica.actual, isNot(primero));
    expect(reproductor.llamadas.last, 'reproducir ${musica.actual}');
  });

  test('al terminar un tema sigue otro, solo mientras haya un dibujo abierto', () async {
    final (musica, reproductor, _) = await nueva();
    await musica.empezar();
    final primero = musica.actual;
    reproductor.terminar();
    await Future<void>.delayed(Duration.zero);
    expect(musica.actual, isNot(primero));
    expect(reproductor.llamadas.where((l) => l.startsWith('reproducir')), hasLength(2));
    await musica.detener();
    reproductor.terminar();
    await Future<void>.delayed(Duration.zero);
    expect(reproductor.llamadas.where((l) => l.startsWith('reproducir')), hasLength(2));
  });

  test('silenciar pausa, se recuerda y no suena al abrir otro dibujo', () async {
    final (musica, reproductor, progreso) = await nueva();
    await musica.empezar();
    await musica.alternarSilencio();
    expect(musica.silenciada, isTrue);
    expect(progreso.musicaSilenciada, isTrue);
    expect(reproductor.llamadas.last, 'pausar');
    await musica.detener();
    reproductor.llamadas.clear();
    await musica.empezar();
    expect(reproductor.llamadas, isEmpty); // silenciada: elige tema pero no suena
    await musica.alternarSilencio();
    expect(reproductor.llamadas, ['reproducir ${musica.actual}']);
  });

  test('segundo plano: pausa y reanuda solo si está sonando', () async {
    final (musica, reproductor, _) = await nueva();
    await musica.pausarPorSegundoPlano();
    expect(reproductor.llamadas, isEmpty); // no hay dibujo abierto
    await musica.empezar();
    await musica.pausarPorSegundoPlano();
    await musica.reanudarDesdeSegundoPlano();
    expect(reproductor.llamadas.skip(1), ['pausar', 'reanudar']);
  });

  test('la música de la app existe en assets', () {
    final archivos = Directory('assets/musica').listSync().whereType<File>().toList();
    expect(archivos.where((f) => f.path.endsWith('.m4a')), hasLength(greaterThanOrEqualTo(4)));
  });

  testWidgets('pantalla de pintar: suena al entrar, botones de cambiar y silenciar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final (musica, reproductor, progreso) = await nueva();
    await tester.pumpWidget(
      Dependencias(
        catalogo: catalogoDeDisco(),
        progreso: progreso,
        musica: musica,
        child: const MaterialApp(home: Pintar(cuadroId: 'nido-de-rocanon')),
      ),
    );
    await tester.pumpAndSettle();
    expect(reproductor.llamadas, hasLength(1));

    final antes = musica.actual;
    await tester.tap(find.byKey(const Key('cambiar-musica')));
    await tester.pump();
    expect(musica.actual, isNot(antes));
    expect(find.textContaining('Sonando:'), findsOneWidget);

    expect(find.byTooltip('Silenciar'), findsOneWidget);
    await tester.tap(find.byKey(const Key('silenciar')));
    await tester.pump();
    expect(find.byTooltip('Activar sonido'), findsOneWidget);
    expect(musica.silenciada, isTrue);

    // Al salir del dibujo, se corta.
    await tester.pumpWidget(const SizedBox());
    expect(reproductor.llamadas.last, 'detener');
  });
}
