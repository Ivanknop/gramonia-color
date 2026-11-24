/// Textos visibles del juego (los nuevos viven acá, no sueltos en los widgets).
///
/// Los que dependen del género de quien juega llevan tres variantes
/// `{chico|chica|neutro}`; se resuelven con `Progreso.texto` (ver
/// `lib/engine/genero.dart`). La neutra reformula: sin "o/a", "x" ni "e".
library;

abstract final class Textos {
  // ---- Elección de género (después de la introducción) ----
  static const generoPregunta = 'Antes de empezar: ¿cómo querés que te hable?';
  static const generoChico = 'Chico';
  static const generoChica = 'Chica';
  static const generoNeutro = 'Prefiero no decir';

  // ---- Niveles (modo historia) ----
  static String nivel(int n) => 'Nivel $n';
  static String paraElNivel(int hechas, int necesarias, int siguiente) =>
      '$hechas de $necesarias obras para llegar al nivel $siguiente';
}
