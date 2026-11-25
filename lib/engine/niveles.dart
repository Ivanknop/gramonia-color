/// Niveles del modo historia: cada nivel es un grupo de lugares de Gramonia.
///
/// - Nivel 0: el tutorial (se pasa al terminarlo o al saltearlo).
/// - Del 1 en adelante: los lugares que tengan ese [Bioma.nivel]. Al llegar a
///   un nivel se abren todos sus lugares juntos; se pasa al siguiente al
///   terminar todas sus obras disponibles.
///
/// Las obras de cada nivel tienen una cantidad fija de colores, que sigue la
/// regla valor(n) = valor(n-1) + ⌊valor(n-1) / 2⌋ con el nivel 1 en 10 colores
/// (10, 15, 22, 33, 49, 73…). El conversor (scripts/convertir_arte.py) genera
/// cada obra con los colores de su nivel (campo `nivel` de catalogo-arte.json).
library;

import 'progresion.dart';

/// Valor de la regla en el nivel [n] (desde 1), arrancando en [inicial].
int valorDelNivel(int n, int inicial) {
  if (n < 1) throw ArgumentError.value(n, 'n', 'los niveles con obras empiezan en 1');
  var valor = inicial;
  for (var i = 1; i < n; i++) {
    valor += valor ~/ 2;
  }
  return valor;
}

const nivelTutorial = 0;
const coloresDelNivel1 = 10;

/// Colores de cada obra del nivel [n].
int coloresDelNivel(int n) => valorDelNivel(n, coloresDelNivel1);

/// Lugares del nivel [n], en el orden del recorrido.
List<Bioma> lugaresDelNivel(List<Bioma> biomas, int n) => [
  for (final b in biomas)
    if (b.nivel == n) b,
];

/// Nivel del lugar que destapa [cuadroId] (null si no es de la historia).
int? nivelDeObra(List<Bioma> biomas, String cuadroId) =>
    piezaDeCuadro(biomas, cuadroId)?.bioma.nivel;

/// En qué nivel va quien juega: [hechas] de las [necesarias] obras del nivel.
typedef EstadoNivel = ({int nivel, int hechas, int necesarias});

/// Nivel actual: 0 hasta pasar el tutorial; después, el primer nivel que
/// tenga obras sin terminar. Si no queda ninguna, el último nivel con obras
/// (completo: hechas == necesarias).
EstadoNivel nivelActual(
  List<Bioma> biomas,
  Set<String> completados, {
  required bool tutorialPasado,
}) {
  if (!tutorialPasado) return (nivel: nivelTutorial, hechas: 0, necesarias: 1);
  final niveles = {for (final b in biomas) b.nivel}.toList()..sort();
  EstadoNivel? ultimoConObras;
  for (final n in niveles) {
    final obras = [for (final b in lugaresDelNivel(biomas, n)) ...b.cuadroIds];
    if (obras.isEmpty) continue;
    final hechas = obras.where(completados.contains).length;
    final estado = (nivel: n, hechas: hechas, necesarias: obras.length);
    if (hechas < obras.length) return estado;
    ultimoConObras = estado;
  }
  return ultimoConObras ?? (nivel: 1, hechas: 0, necesarias: 0);
}

/// Cuántos niveles se suben al pasar de [antes] a [despues] obras completadas
/// (con el tutorial ya pasado).
int nivelesSubidos(List<Bioma> biomas, Set<String> antes, Set<String> despues) =>
    nivelActual(biomas, despues, tutorialPasado: true).nivel -
    nivelActual(biomas, antes, tutorialPasado: true).nivel;

/// Niveles (desde 1) completos: todas sus obras disponibles terminadas, en
/// orden y cortando en el primero que falte. Los niveles sin obras todavía no
/// cuentan (ni se completan ni traban).
List<int> nivelesCompletos(List<Bioma> biomas, Set<String> completados) {
  final niveles = {for (final b in biomas) b.nivel}.toList()..sort();
  final completos = <int>[];
  for (final n in niveles) {
    final obras = [for (final b in lugaresDelNivel(biomas, n)) ...b.cuadroIds];
    if (obras.isEmpty) continue;
    if (!obras.every(completados.contains)) break;
    completos.add(n);
  }
  return completos;
}

/// Niveles que pasan a estar completos al pasar de [antes] a [despues].
List<int> nivelesQueSeCompletan(List<Bioma> biomas, Set<String> antes, Set<String> despues) {
  final previos = nivelesCompletos(biomas, antes).toSet();
  return [
    for (final n in nivelesCompletos(biomas, despues))
      if (!previos.contains(n)) n,
  ];
}

/// Lugares que se ven a color en la portada: los de los niveles completos
/// que tienen obras (los mismos que ya se colorearon en el mapa).
List<Bioma> lugaresRecuperados(List<Bioma> biomas, Set<String> completados) {
  final niveles = nivelesCompletos(biomas, completados).toSet();
  return [
    for (final b in biomas)
      if (niveles.contains(b.nivel) && b.cuadroIds.isNotEmpty) b,
  ];
}
