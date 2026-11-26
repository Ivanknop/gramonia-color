import 'dart:async';
import 'dart:io';

import 'package:colores_de_gramonia/datos/catalogo.dart';
import 'package:colores_de_gramonia/engine/dificultad.dart';
import 'package:colores_de_gramonia/engine/plumas.dart';
import 'package:colores_de_gramonia/estado/musica.dart';
import 'package:colores_de_gramonia/estado/progreso.dart';

/// Catálogo leído de assets/ sin AssetBundle.
Catalogo catalogoDeDisco() {
  final dir = Directory('assets/cuadros');
  final jsons = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json'));
  return Catalogo.desdeTextos(
    [
      for (final j in jsons)
        (
          json: j.readAsStringSync(),
          svg: File(j.path.replaceFirst(RegExp(r'\.json$'), '.svg')).readAsStringSync(),
        ),
    ],
    dificultades: leerDificultades(File(Catalogo.tablaDificultades).readAsStringSync()),
    leer: (asset) async => File(asset).readAsStringSync(),
  );
}

Map<Herramienta, int> inventario(Progreso p) => {
  for (final h in Herramienta.values) h: p.cantidad(h),
};

/// Registra lo que se le pide, sin sonar.
class ReproductorDePrueba implements Reproductor {
  final llamadas = <String>[];
  final _fin = StreamController<void>.broadcast();

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
