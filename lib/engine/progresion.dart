/// Progresión: Gramonia se recorre nivel por nivel, con dificultad creciente
/// (más obras, más regiones y más colores por obra). Cada nivel agrupa uno o
/// más lugares (ver `niveles.dart`). Cada obra terminada destapa una pieza de
/// su bioma; con todas las piezas destapadas, el bioma queda completo.
///
/// Los lugares de un nivel se abren todos juntos, cuando los de los niveles
/// anteriores están completos en todo lo que tienen disponible: las piezas
/// "próximamente" (sin obra asignada todavía) no traban el avance.
library;

import 'dart:math' as math;

import 'tutorial.dart';

enum TipoBioma { region, isla }

/// Una pieza de un bioma. [cuadroId] null = "próximamente" (falta la obra).
class Pieza {
  const Pieza({required this.id, this.cuadroId});
  final String id;

  /// Obra que hay que completar para destaparla.
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

  /// Nivel de la historia al que pertenece (desde 1; ver `niveles.dart`).
  final int nivel;
  final TipoBioma tipo;

  /// El nombre va con "la" (la Montaña Dragón); si no, con "el". Los que ya
  /// traen artículo ("La Ciudad") no lo necesitan.
  final bool femenino;

  /// Nombre con artículo en minúscula, para usar dentro de una frase:
  /// "el Árbol Mágico", "la Montaña Dragón", "la Ciudad".
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

  /// Ids de piezas destapadas.
  final Set<String> reveladas;

  /// Se puede jugar (los niveles anteriores están completos en lo disponible).
  final bool accesible;

  int get total => bioma.piezas.length;

  /// Todas las piezas destapadas (requiere que todas tengan obra).
  bool get completo => total > 0 && reveladas.length == total;

  /// Todas las obras que existen hoy están terminadas.
  bool get completoDisponible =>
      bioma.piezas.every((p) => p.cuadroId == null || reveladas.contains(p.id));
}

/// Estado de todos los biomas, en orden de progresión. Un bioma es accesible
/// si todos los de niveles anteriores están completos en lo disponible.
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

/// Obras de la historia en el orden del recorrido (bioma por bioma).
List<String> cuadrosDelRecorrido(List<Bioma> biomas) => [for (final b in biomas) ...b.cuadroIds];

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

/// Qué pieza destapa un cuadro (o null si no destapa ninguna).
({Bioma bioma, Pieza pieza})? piezaDeCuadro(List<Bioma> biomas, String cuadroId) {
  for (final b in biomas) {
    for (final p in b.piezas) {
      if (p.cuadroId == cuadroId) return (bioma: b, pieza: p);
    }
  }
  return null;
}

/// Biomas que pasan a estar completos (todas sus obras disponibles
/// terminadas) al sumar [cuadroId] a los completados.
List<Bioma> biomasQueSeCompletan(List<Bioma> biomas, Set<String> antes, String cuadroId) {
  final previos = estadoBiomas(biomas, antes);
  final nuevos = estadoBiomas(biomas, {...antes, cuadroId});
  return [
    for (var i = 0; i < biomas.length; i++)
      if (!previos[i].completoDisponible &&
          nuevos[i].completoDisponible &&
          biomas[i].cuadroIds.isNotEmpty)
        biomas[i],
  ];
}

/// Revisa que los datos de biomas sean consistentes. Devuelve los problemas
/// encontrados (vacío si está todo bien). Lo usan los tests de datos.
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
