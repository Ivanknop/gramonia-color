/// Plumas del Rocanón: la moneda del juego. Se ganan al entrar cada día, al
/// terminar un cuadro (en cualquier modo) y al subir de nivel en la historia;
/// se gastan en la tienda, en lupas y bombas. Usar una herramienta gasta una
/// del inventario.
library;

abstract final class ReglasPlumas {
  /// Al entrar, una vez por día.
  static const porDia = 5;

  /// Por cada cuadro terminado (historia, modo libre u obra rehecha).
  static const porObra = 3;

  /// Por cada nivel de la historia que se sube.
  static const porNivel = 10;
}

/// Herramientas que se compran en la tienda.
enum Herramienta {
  lupa(precio: 5),
  bomba(precio: 10);

  const Herramienta({required this.precio});

  /// Precio en plumas.
  final int precio;
}

/// Plumas por terminar un cuadro, subiendo [nivelesSubidos] niveles.
int plumasPorTerminar({int nivelesSubidos = 0}) =>
    ReglasPlumas.porObra + ReglasPlumas.porNivel * nivelesSubidos;

/// Día calendario (aaaa-mm-dd, hora local) para la recompensa diaria.
String diaDe(DateTime momento) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${momento.year}-${dos(momento.month)}-${dos(momento.day)}';
}

/// ¿Corresponde la recompensa diaria? (Si nunca se dio, o se dio otro día.)
bool tocaRecompensaDiaria(String? ultimoDia, DateTime ahora) => ultimoDia != diaDe(ahora);

/// ¿Alcanza el saldo para comprar [h]?
bool puedeComprar(int saldo, Herramienta h) => saldo >= h.precio;
