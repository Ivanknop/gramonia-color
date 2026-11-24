/// Progresión: cada cuadro terminado destapa una pieza de un bioma; con todas
/// las celdas de su grilla destapadas, el bioma se desbloquea entero.
library;

/// Una pieza del mapa de un bioma, ubicada en su grilla.
class Pieza {
  const Pieza({
    required this.id,
    required this.cuadroId,
    required this.fila,
    required this.columna,
  });
  final String id;

  /// Cuadro que hay que completar para destaparla.
  final String cuadroId;
  final int fila;
  final int columna;
}

class Bioma {
  const Bioma({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.color,
    required this.filas,
    required this.columnas,
    required this.piezas,
  });

  final String id;
  final String nombre;
  final String descripcion;

  /// Color dominante (ARGB), para la vista provisoria del mapa.
  final int color;
  final int filas;
  final int columnas;
  final List<Pieza> piezas;
}

class EstadoBioma {
  const EstadoBioma(this.bioma, this.reveladas, this.total, this.desbloqueado);
  final Bioma bioma;
  final Set<String> reveladas;
  final int total;
  final bool desbloqueado;
}

EstadoBioma estadoBioma(Bioma bioma, Set<String> completados) {
  final reveladas = {
    for (final p in bioma.piezas)
      if (completados.contains(p.cuadroId)) p.id,
  };
  // El total son las celdas de la grilla: si faltan piezas por asignar,
  // el bioma no puede desbloquearse todavía.
  final total = bioma.filas * bioma.columnas;
  return EstadoBioma(bioma, reveladas, total, total > 0 && reveladas.length == total);
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

/// Revisa que los datos de biomas sean consistentes. Devuelve los problemas
/// encontrados (vacío si está todo bien). Lo usan los tests de datos.
List<String> validarBiomas(List<Bioma> biomas, Iterable<String> cuadroIds) {
  final problemas = <String>[];
  final existentes = cuadroIds.toSet();
  final cuadrosUsados = <String, String>{};
  final idsBioma = <String>{};
  for (final b in biomas) {
    if (!idsBioma.add(b.id)) problemas.add('Bioma repetido: ${b.id}');
    final celdas = <String>{};
    final idsPieza = <String>{};
    for (final p in b.piezas) {
      final donde = '${b.id}/${p.id}';
      if (!idsPieza.add(p.id)) problemas.add('Pieza repetida: $donde');
      if (!existentes.contains(p.cuadroId)) {
        problemas.add('$donde usa un cuadro inexistente: ${p.cuadroId}');
      }
      final previo = cuadrosUsados[p.cuadroId];
      if (previo != null) {
        problemas.add('El cuadro ${p.cuadroId} destapa dos piezas: $previo y $donde');
      }
      cuadrosUsados[p.cuadroId] = donde;
      if (p.fila < 0 || p.fila >= b.filas || p.columna < 0 || p.columna >= b.columnas) {
        problemas.add('$donde está fuera de la grilla ${b.filas}x${b.columnas}');
      }
      if (!celdas.add('${p.fila},${p.columna}')) {
        problemas.add('$donde ocupa una celda ya usada (${p.fila},${p.columna})');
      }
    }
  }
  return problemas;
}
