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

  // ---- Dificultades ----
  static String detalleDificultad(int colores, int regiones) =>
      '$colores colores · unas $regiones partes para pintar';

  // ---- Modo libre ----
  static const modoLibre = 'Modo libre';
  static const libreIntro =
      'Acá no hay historia ni mapa: elegí un dibujo y pintalo como quieras, '
      'tan fácil o tan difícil como te guste.';
  static const libreElegir = '¿Qué tan difícil lo querés?';
  static const libreTerminado = '¡Obra terminada! Quedó hermosa.';
  static const libreOtro = 'Elegir otro dibujo';
  static const libreVacio =
      'Todavía no hay dibujos para el modo libre. Recuperá lugares en la historia y aparecen acá.';
  static String etiquetaLibre(String dificultad) => 'Modo libre · $dificultad';

  // ---- Rehacer obra ----
  static const rehacer = 'Rehacer';
  static const rehacerElegir = '¿En qué dificultad la volvés a pintar?';
  static const rehacerAviso =
      'Se borra lo pintado y empezás de nuevo. Lo que destapaste en Gramonia queda destapado.';
  static String etiquetaRehecha(String dificultad) => 'Rehecha · $dificultad';

  // ---- Tienda y herramientas ----
  static const tienda = 'Tienda';
  static const tiendaLobo = 'El Lobo de la tienda';
  static const tiendaFrase = 'No explico mucho. Vendo.';
  static const tiendaComprar = 'Comprar';
  static const tiendaPlumas = 'Tus plumas';
  static const lupa = 'Lupa';
  static const bomba = 'Bomba de color';
  static const lupaDetalle = 'Te lleva a una parte que falta pintar.';
  static const bombaDetalle = 'Pinta un montón de partes de una vez.';
  static String tenes(int n) => 'Tenés $n';
  static String compraste(String que, int n) => '¡Listo! Ahora tenés $n ($que).';
  static const faltanPlumas = 'Te faltan plumas. Terminá cuadros para juntar más.';
  static const sinLupas = 'No te quedan lupas. Conseguí más en la Tienda.';
  static const sinBombas = 'No te quedan bombas. Conseguí más en la Tienda.';
  static String subisteDeNivel(int n) => '¡Llegaste al nivel $n!';

  // ---- Portada ----
  static const tituloGramonia = 'Gramonia...';
  static const tituloColor = 'Color';
  static const empezar = '¡Empezar!';
  static const continuar = 'Continuar pintando';
  static const galeria = 'Galería';
  static const mapa = 'Mapa de Gramonia';
  static const laHistoria = 'La historia';
  static String plumasDelDia(int n) => 'Gobi te trae $n plumas del Rocanón. ¡Buen día!';
}
