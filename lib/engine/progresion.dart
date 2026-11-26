/// Cada obra terminada destapa una pieza de su bioma. Las piezas sin obra ("próximamente") no
/// traban el avance.
library;

import 'dart:math' as math;

import 'tutorial.dart';

enum TipoBioma { region, isla }

/// Una pieza de un bioma. [cuadroId] null = "próximamente" (falta la obra).
class Pieza {
  const Pieza({required this.id, this.cuadroId});
  final String id;
  final String? cuadroId;
}

class Bioma {
  const Bioma({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.color,
    required this.piezas,
    this.nivel = 1,
    this.tipo = TipoBioma.region,
    this.femenino = false,
  });

  final String id;
  final String nombre;
  final String descripcion;

  /// Color representativo (ARGB): fichas, islas del mapa, etc.
  final int color;
  final List<Pieza> piezas;
  final int nivel;
  final TipoBioma tipo;

  /// El nombre va con "la" (la Montaña Dragón); si no, con "el". Los que ya
  /// traen artículo ("La Ciudad") no lo necesitan.
  final bool femenino;

  String get conArticulo {
    for (final a in const ['El ', 'La ']) {
      if (nombre.startsWith(a)) return '${a.toLowerCase()}${nombre.substring(a.length)}';
    }
    return '${femenino ? 'la' : 'el'} $nombre';
  }

  Iterable<String> get cuadroIds => piezas.map((p) => p.cuadroId).whereType<String>();
}

class EstadoBioma {
  const EstadoBioma({required this.bioma, required this.reveladas, required this.accesible});

  final Bioma bioma;
  final Set<String> reveladas;
  final bool accesible;
  int get total => bioma.piezas.length;

  /// Todas las piezas destapadas (requiere que todas tengan obra).
  bool get completo => total > 0 && reveladas.length == total;

  /// Todas las obras que existen hoy están terminadas.
  bool get completoDisponible =>
      bioma.piezas.every((p) => p.cuadroId == null || reveladas.contains(p.id));
}

List<EstadoBioma> estadoBiomas(List<Bioma> biomas, Set<String> completados) {
  final estados = [
    for (final b in biomas)
      EstadoBioma(
        bioma: b,
        reveladas: {
          for (final p in b.piezas)
            if (p.cuadroId != null && completados.contains(p.cuadroId)) p.id,
        },
        accesible: false,
      ),
  ];
  final pendientes = [
    for (final e in estados)
      if (!e.completoDisponible) e.bioma.nivel,
  ];
  // Se abre hasta el primer nivel con algo sin terminar (todo, si no queda nada).
  final tope = pendientes.isEmpty ? null : pendientes.reduce(math.min);
  return [
    for (final e in estados)
      EstadoBioma(
        bioma: e.bioma,
        reveladas: e.reveladas,
        accesible: tope == null || e.bioma.nivel <= tope,
      ),
  ];
}

/// Cuadros del modo libre, en el orden de [todos]: los que no son de la
/// historia (solo modo libre) y los de la historia que ya se colorearon ahí
/// (menos el tutorial, que se juega desde la historia).
List<String> cuadrosLibres(List<Bioma> biomas, Set<String> completados, Iterable<String> todos) {
  final enLaHistoria = {for (final b in biomas) ...b.cuadroIds};
  return [
    for (final id in todos)
      if (id != idTutorial && (completados.contains(id) || !enLaHistoria.contains(id))) id,
  ];
}

({Bioma bioma, Pieza pieza})? piezaDeCuadro(List<Bioma> biomas, String cuadroId) {
  for (final b in biomas) {
    for (final p in b.piezas) {
      if (p.cuadroId == cuadroId) return (bioma: b, pieza: p);
    }
  }
  return null;
}

List<String> validarBiomas(List<Bioma> biomas, Iterable<String> cuadroIds) {
  final problemas = <String>[];
  final existentes = cuadroIds.toSet();
  final cuadrosUsados = <String, String>{};
  final idsBioma = <String>{};
  for (final b in biomas) {
    if (!idsBioma.add(b.id)) problemas.add('Bioma repetido: ${b.id}');
    if (b.piezas.isEmpty) problemas.add('${b.id} no tiene piezas');
    final idsPieza = <String>{};
    for (final p in b.piezas) {
      final donde = '${b.id}/${p.id}';
      if (!idsPieza.add(p.id)) problemas.add('Pieza repetida: $donde');
      final c = p.cuadroId;
      if (c == null) continue;
      if (!existentes.contains(c)) problemas.add('$donde usa un cuadro inexistente: $c');
      final previo = cuadrosUsados[c];
      if (previo != null) problemas.add('El cuadro $c destapa dos piezas: $previo y $donde');
      cuadrosUsados[c] = donde;
    }
  }
  return problemas;
}
