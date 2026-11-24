/// "Mis obras": cuadros empezados o terminados por el jugador (de la historia
/// y del modo libre, cuya clave es la de la variante de dificultad).
library;

import '../engine/dificultad.dart';
import 'progreso.dart';

typedef Obra = ({String cuadroId, ProgresoCuadro progreso});

/// Clasifica el progreso en obras en progreso (la más reciente primero) y
/// terminadas (la terminada más recientemente primero). Ignora cuadros sin
/// pintar (salvo los rehechos) y cuadros que ya no existen en el catálogo.
({List<Obra> enProgreso, List<Obra> terminadas}) clasificarObras(
  Map<String, ProgresoCuadro> cuadros,
  Set<String> idsExistentes,
) {
  final enProgreso = <Obra>[];
  final terminadas = <Obra>[];
  for (final e in cuadros.entries) {
    if (!idsExistentes.contains(cuadroBase(e.key))) continue;
    final obra = (cuadroId: e.key, progreso: e.value);
    if (e.value.terminado) {
      terminadas.add(obra);
    } else if (e.value.pintadas.isNotEmpty || e.value.dificultad != null) {
      // Las rehechas aparecen aunque todavía estén en blanco.
      enProgreso.add(obra);
    }
  }
  enProgreso.sort(
    (a, b) => (b.progreso.actualizadoEn ?? 0).compareTo(a.progreso.actualizadoEn ?? 0),
  );
  terminadas.sort((a, b) => (b.progreso.completadoEn ?? 0).compareTo(a.progreso.completadoEn ?? 0));
  return (enProgreso: enProgreso, terminadas: terminadas);
}
