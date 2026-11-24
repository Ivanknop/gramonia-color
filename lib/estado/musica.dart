/// Música de fondo mientras se pinta: un tema al azar en cada dibujo; al
/// terminar, sigue otro distinto. Se puede cambiar de tema y silenciar (el
/// silencio se recuerda entre sesiones, en el progreso).
///
/// La lógica no depende del reproductor real ([Reproductor]); en la app se usa
/// audioplayers y en los tests uno de mentira.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'progreso.dart';

/// Lo mínimo que necesita la música de un reproductor.
abstract class Reproductor {
  /// Reproduce un asset (ruta completa, por ejemplo `assets/musica/x.m4a`).
  Future<void> reproducir(String asset);
  Future<void> pausar();
  Future<void> reanudar();
  Future<void> detener();

  /// Avisa cuando termina el tema que estaba sonando.
  Stream<void> get alTerminar;
}

/// Reproductor real (audioplayers: usa el reproductor nativo de Android).
class ReproductorAudioplayers implements Reproductor {
  ReproductorAudioplayers() {
    // Música de fondo: volumen medio, sin repetir (al terminar se elige otra).
    unawaited(_player.setReleaseMode(ReleaseMode.stop));
  }

  final _player = AudioPlayer();
  static const _volumen = 0.6;

  @override
  Future<void> reproducir(String asset) => _player.play(
    // AssetSource agrega el prefijo "assets/".
    AssetSource(asset.replaceFirst(RegExp('^assets/'), '')),
    volume: _volumen,
  );

  @override
  Future<void> pausar() => _player.pause();

  @override
  Future<void> reanudar() => _player.resume();

  @override
  Future<void> detener() => _player.stop();

  @override
  Stream<void> get alTerminar => _player.onPlayerComplete;
}

/// Elige un tema al azar, distinto de [excepto] si hay más de uno.
String elegirTema(List<String> temas, String? excepto, math.Random azar) {
  final opciones = temas.length > 1 ? temas.where((t) => t != excepto).toList() : temas;
  return opciones[azar.nextInt(opciones.length)];
}

/// Nombre lindo de un tema a partir del archivo (`walking-for-gramonia.m4a`
/// → `Walking For Gramonia`).
String nombreDeTema(String asset) {
  final archivo = asset.split('/').last.replaceFirst(RegExp(r'\.\w+$'), '');
  return archivo
      .split(RegExp('[-_]'))
      .where((p) => p.isNotEmpty)
      .map((p) => p[0].toUpperCase() + p.substring(1))
      .join(' ');
}

class Musica extends ChangeNotifier {
  Musica({
    required this.temas,
    required this.reproductor,
    required this.progreso,
    math.Random? azar,
  }) : _azar = azar ?? math.Random() {
    _suscripcion = reproductor.alTerminar.listen((_) {
      if (_activa) unawaited(_tocar(elegirTema(temas, actual, _azar)));
    });
  }

  /// Assets de los temas (por ejemplo `assets/musica/x.m4a`).
  final List<String> temas;
  final Reproductor reproductor;
  final Progreso progreso;
  final math.Random _azar;
  StreamSubscription<void>? _suscripcion;

  /// Tema elegido (suene o esté silenciado).
  String? actual;

  /// Hay un dibujo abierto (la música "debería" estar sonando).
  bool _activa = false;

  bool get silenciada => progreso.musicaSilenciada;

  Future<void> _tocar(String tema) async {
    actual = tema;
    notifyListeners();
    if (!silenciada) await reproductor.reproducir(tema);
  }

  /// Al abrir un dibujo: un tema al azar.
  Future<void> empezar() async {
    if (temas.isEmpty) return;
    _activa = true;
    await _tocar(elegirTema(temas, actual, _azar));
  }

  /// Botón "Cambiar música": otro tema al azar.
  Future<void> cambiar() async {
    if (temas.isEmpty) return;
    await _tocar(elegirTema(temas, actual, _azar));
  }

  /// Botón "Silenciar" / "Activar sonido".
  Future<void> alternarSilencio() async {
    progreso.silenciarMusica(!silenciada);
    notifyListeners();
    if (silenciada) {
      await reproductor.pausar();
    } else if (_activa && actual != null) {
      await reproductor.reproducir(actual!);
    }
  }

  /// Al salir del dibujo.
  Future<void> detener() async {
    _activa = false;
    await reproductor.detener();
  }

  /// La app pasó a segundo plano / volvió.
  Future<void> pausarPorSegundoPlano() async {
    if (_activa && !silenciada) await reproductor.pausar();
  }

  Future<void> reanudarDesdeSegundoPlano() async {
    if (_activa && !silenciada) await reproductor.reanudar();
  }

  @override
  void dispose() {
    unawaited(_suscripcion?.cancel());
    super.dispose();
  }
}

/// Reproductor que no suena: para tests (registra lo que se le pidió).
class ReproductorDePrueba implements Reproductor {
  final llamadas = <String>[];
  final _fin = StreamController<void>.broadcast();

  /// Simula que terminó el tema.
  void terminar() => _fin.add(null);

  @override
  Future<void> reproducir(String asset) async => llamadas.add('reproducir $asset');

  @override
  Future<void> pausar() async => llamadas.add('pausar');

  @override
  Future<void> reanudar() async => llamadas.add('reanudar');

  @override
  Future<void> detener() async => llamadas.add('detener');

  @override
  Stream<void> get alTerminar => _fin.stream;
}
