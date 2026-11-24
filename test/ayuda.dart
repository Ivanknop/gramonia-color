/// Utilidades compartidas por los tests.
library;

import 'dart:io';

import 'package:colores_de_gramonia/datos/catalogo.dart';
import 'package:colores_de_gramonia/engine/dificultad.dart';

/// Catálogo leído directamente de assets/cuadros (sin AssetBundle).
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
