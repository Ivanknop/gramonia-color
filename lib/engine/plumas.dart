/// Plumas del Rocanón: la moneda del juego. Se ganan al entrar cada día, al
/// terminar un cuadro (en el modo libre, según la dificultad), al subir de nivel en la historia y
/// al terminar el tutorial por primera vez;
/// se gastan en la tienda, en lupas y bombas. Usar una herramienta gasta una
/// del inventario.
library;

abstract final class ReglasPlumas {
  /// Al entrar, una vez por día.
  static const porDia = 5;

  /// Por cada cuadro terminado de la historia (también una obra rehecha). En el
  /// modo libre, en cambio, las da la dificultad (`Dificultad.plumas`, de 1 en
  /// Súper fácil a 100 en Divino).
  static const porObra = 3;

  /// Por cada nivel de la historia que se sube.
  static const porNivel = 10;

  /// Al terminar el tutorial por primera vez (aunque antes se haya salteado).
  static const porTutorial = 20;
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

/// Lupas y bombas que se regalan al llegar al nivel 1 (una sola vez).
const herramientasIniciales = {Herramienta.lupa: 3, Herramienta.bomba: 3};
