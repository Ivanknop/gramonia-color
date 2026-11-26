/// Plumas del Rocanón: la moneda del juego, que se gasta en la tienda.
library;

abstract final class ReglasPlumas {
  static const porDia = 5;

  /// Por cuadro de la historia terminado (también rehecho). En el modo libre
  /// las da la dificultad (`Dificultad.plumas`).
  static const porObra = 3;
  static const porNivel = 10;

  /// Al terminar el tutorial por primera vez (aunque antes se haya salteado).
  static const porTutorial = 20;
}

enum Herramienta {
  lupa(precio: 5),
  bomba(precio: 10);

  const Herramienta({required this.precio});

  final int precio;
}

int plumasPorTerminar({int nivelesSubidos = 0}) =>
    ReglasPlumas.porObra + ReglasPlumas.porNivel * nivelesSubidos;

String diaDe(DateTime momento) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${momento.year}-${dos(momento.month)}-${dos(momento.day)}';
}

bool tocaRecompensaDiaria(String? ultimoDia, DateTime ahora) => ultimoDia != diaDe(ahora);

bool puedeComprar(int saldo, Herramienta h) => saldo >= h.precio;

const herramientasIniciales = {Herramienta.lupa: 3, Herramienta.bomba: 3};
