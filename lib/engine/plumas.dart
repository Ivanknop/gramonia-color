/// Plumas del Rocanón: la moneda del juego. Se ganan una vez por día al
/// entrar, al terminar una obra y al completar un bioma; se gastan en la lupa
/// y la bomba. Por ahora las herramientas son gratis ([herramientasGratis]).
library;

abstract final class ReglasPlumas {
  /// Mientras sea true, la lupa y la bomba no cobran plumas.
  static const herramientasGratis = true;

  static const porDia = 5;
  static const porObra = 10;
  static const porBioma = 30;

  static const costoLupa = 1;
  static const costoBomba = 5;
}

/// Día calendario (aaaa-mm-dd, hora local) para la recompensa diaria.
String diaDe(DateTime momento) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${momento.year}-${dos(momento.month)}-${dos(momento.day)}';
}

/// ¿Corresponde la recompensa diaria? (Si nunca se dio, o se dio otro día.)
bool tocaRecompensaDiaria(String? ultimoDia, DateTime ahora) => ultimoDia != diaDe(ahora);

/// ¿Alcanza el saldo para usar una herramienta?
bool puedePagar(int saldo, int costo) => ReglasPlumas.herramientasGratis || saldo >= costo;
