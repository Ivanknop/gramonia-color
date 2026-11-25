/// Tutorial (nivel 0): un Árbol Mágico sencillo, de 5 colores y unas 20
/// partes, que enseña a pintar paso a paso. Se juega una vez al empezar la
/// historia y se puede saltear; después se puede volver a hacer, sin premio.
///
/// Los pasos se marcan cuando quien juega hace cada cosa, en cualquier orden;
/// el que se muestra es el primero que falta.
library;

/// Cuadro del tutorial (scripts/catalogo-arte.json, sección "tutorial").
const idTutorial = 'tutorial-arbol-magico';

enum PasoTutorial {
  /// Tocar un color de la paleta.
  elegirColor,

  /// Pintar una parte con el número elegido.
  tocarParte,

  /// Terminar todas las partes de un color.
  completarColor,

  /// Usar la lupa.
  lupa,

  /// Tirar la bomba de color.
  bomba,

  /// Terminar el dibujo (no se marca: es el último).
  terminar,
}

/// Paso que toca mostrar, según los ya hechos.
PasoTutorial pasoActual(Set<PasoTutorial> hechos) =>
    PasoTutorial.values.firstWhere((p) => !hechos.contains(p), orElse: () => PasoTutorial.terminar);
