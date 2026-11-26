/// Niveles del modo historia: el 0 es el tutorial; del 1 en adelante, los
/// lugares con ese [Bioma.nivel], que se abren juntos.
library;

import 'progresion.dart';

const nivelTutorial = 0;
const coloresDelNivel1 = 10;

/// Cada nivel suma la mitad de los colores del anterior: 10, 15, 22, 33…
/// (el conversor aplica la misma regla).
int coloresDelNivel(int n) {
  if (n < 1) throw ArgumentError.value(n, 'n', 'los niveles con obras empiezan en 1');
  var colores = coloresDelNivel1;
  for (var i = 1; i < n; i++) {
    colores += colores ~/ 2;
  }
  return colores;
}

List<Bioma> lugaresDelNivel(List<Bioma> biomas, int n) => [
  for (final b in biomas)
    if (b.nivel == n) b,
];

/// Obras de cada nivel, en orden, salteando los niveles que todavía no tienen.
Iterable<(int, List<String>)> _obrasPorNivel(List<Bioma> biomas) sync* {
  for (final n in {for (final b in biomas) b.nivel}.toList()..sort()) {
    final obras = [for (final b in lugaresDelNivel(biomas, n)) ...b.cuadroIds];
    if (obras.isNotEmpty) yield (n, obras);
  }
}

typedef EstadoNivel = ({int nivel, int hechas, int necesarias});

/// El primer nivel con obras sin terminar; si no queda ninguno, el último, completo.
EstadoNivel nivelActual(
  List<Bioma> biomas,
  Set<String> completados, {
  required bool tutorialPasado,
}) {
  if (!tutorialPasado) return (nivel: nivelTutorial, hechas: 0, necesarias: 1);
  EstadoNivel? ultimo;
  for (final (n, obras) in _obrasPorNivel(biomas)) {
    ultimo = (nivel: n, hechas: obras.where(completados.contains).length, necesarias: obras.length);
    if (ultimo.hechas < ultimo.necesarias) return ultimo;
  }
  return ultimo ?? (nivel: 1, hechas: 0, necesarias: 0);
}

int nivelesSubidos(List<Bioma> biomas, Set<String> antes, Set<String> despues) =>
    nivelActual(biomas, despues, tutorialPasado: true).nivel -
    nivelActual(biomas, antes, tutorialPasado: true).nivel;

/// Los niveles con todas sus obras terminadas, en orden hasta el primero que falte.
List<int> nivelesCompletos(List<Bioma> biomas, Set<String> completados) => [
  for (final (n, _) in _obrasPorNivel(
    biomas,
  ).takeWhile((nivel) => nivel.$2.every(completados.contains)))
    n,
];

List<int> nivelesQueSeCompletan(List<Bioma> biomas, Set<String> antes, Set<String> despues) {
  final previos = nivelesCompletos(biomas, antes).toSet();
  return [
    for (final n in nivelesCompletos(biomas, despues))
      if (!previos.contains(n)) n,
  ];
}

/// Los que se ven a color en la portada: los lugares con obras de los niveles completos.
List<Bioma> lugaresRecuperados(List<Bioma> biomas, Set<String> completados) {
  final niveles = nivelesCompletos(biomas, completados).toSet();
  return [
    for (final b in biomas)
      if (niveles.contains(b.nivel) && b.cuadroIds.isNotEmpty) b,
  ];
}
