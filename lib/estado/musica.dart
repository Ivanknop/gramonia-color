/// Música de fondo mientras se pinta: un tema al azar en cada dibujo y otro al terminar. El
/// silencio se guarda en el progreso.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'progreso.dart';

abstract class Reproductor {
  Future<void> reproducir(String asset);
  Future<void> pausar();
  Future<void> reanudar();
  Future<void> detener();

  Stream<void> get alTerminar;
}

class ReproductorAudioplayers implements Reproductor {
  /// [volumen]: la música de fondo va a volumen medio; los efectos, más fuerte.
  ReproductorAudioplayers({this.volumen = 0.6}) {
    // Sin repetir (al terminar un tema se elige otro).
    unawaited(_player.setReleaseMode(ReleaseMode.stop));
  }

  final _player = AudioPlayer();
  final double volumen;

  @override
  Future<void> reproducir(String asset) => _player.play(
    // AssetSource agrega el prefijo "assets/".
    AssetSource(asset.replaceFirst(RegExp('^assets/'), '')),
    volume: volumen,
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
    this.efectos,
    math.Random? azar,
  }) : _azar = azar ?? math.Random() {
    _suscripcion = reproductor.alTerminar.listen((_) {
      if (_activa) unawaited(_tocar(elegirTema(temas, actual, _azar)));
    });
  }

  final List<String> temas;
  final Reproductor reproductor;
  final Progreso progreso;

  /// Reproductor aparte para los efectos (así no cortan la música).
  final Reproductor? efectos;
  final math.Random _azar;
  StreamSubscription<void>? _suscripcion;

  String? actual;

  /// Hay un dibujo abierto (la música "debería" estar sonando).
  bool _activa = false;
  bool get silenciada => progreso.musicaSilenciada;

  Future<void> _tocar(String tema) async {
    actual = tema;
    notifyListeners();
    if (!silenciada) await reproductor.reproducir(tema);
  }

  Future<void> empezar() async {
    if (temas.isEmpty) return;
    _activa = true;
    await _tocar(elegirTema(temas, actual, _azar));
  }

  Future<void> cambiar() async {
    if (temas.isEmpty) return;
    await _tocar(elegirTema(temas, actual, _azar));
  }

  Future<void> alternarSilencio() async {
    progreso.silenciarMusica(!silenciada);
    notifyListeners();
    if (silenciada) {
      await reproductor.pausar();
    } else if (_activa && actual != null) {
      await reproductor.reproducir(actual!);
    }
  }

  /// Sonido del festejo al terminar un cuadro. "Silenciar" también lo calla.
  Future<void> festejar() async {
    if (!silenciada) await efectos?.reproducir(sonidoFestejo);
  }

  static const sonidoFestejo = 'assets/sonidos/festejo.m4a';

  Future<void> detener() async {
    _activa = false;
    await reproductor.detener();
  }

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
