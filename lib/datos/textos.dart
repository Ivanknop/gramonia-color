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

  // ---- Créditos ----
  static const creditos = 'Créditos';
  static const creditosIntro =
      'Estas son las personas (y las ayudas mágicas) que hicieron Gramonia Color.';

  /// Quién hizo qué, en el orden en que se muestra.
  static const realizadores = <(String, String)>[
    ('Cuentos de Gramonia', 'Iván y Regi (Regina Knopoff)'),
    ('Idea y desarrollo', 'Iván'),
    ('Dibujos', 'Hechos con Gemini, a partir de los cuentos'),
    ('Música', 'Hecha con Gemini Lyria'),
    ('Programación', 'Con ayuda de Claude'),
  ];
  static const creditosCuentos = 'Los cuentos se leen en cuentosdegramonia.substack.com';
  static const creditosGobi = '¡Gracias por devolverle los colores a Gramonia!';

  // ---- Festejo ----
  static const festejo = '¡Terminaste!';

  // ---- Timelapse ----
  static const timelapse = 'Así lo pintaste';
  static const saltear = 'Saltear';
  static const verComoLoPinte = 'Ver cómo lo pinté';
}
