/// Tutoriales del modo historia:
///
/// - **Pintar** (nivel 0): un Árbol Mágico sencillo, de 5 colores y unas 20
///   partes. Los pasos son obligatorios y van en orden: elegir un color,
///   pintar hasta completar uno, usar la lupa, tirar la bomba y terminar. En
///   cada paso solo se puede hacer lo que pide (lo demás no responde). Se
///   juega una vez al empezar la historia; se puede saltear (sin premio) y
///   volver a hacer.
/// - **Tienda**: al completar el nivel 1, el juego lleva a la Tienda, regala
///   las plumas justas y pide comprar una lupa. También se puede saltear.
library;

import 'plumas.dart';

/// Cuadro del tutorial (scripts/catalogo-arte.json, sección "tutorial").
const idTutorial = 'tutorial-arbol-magico';

enum PasoTutorial {
  /// Tocar un color de la paleta.
  elegirColor,

  /// Pintar hasta completar todas las partes de un color.
  completarColor,

  /// Usar la lupa (encenderla y tocar un color).
  lupa,

  /// Tirar la bomba de color.
  bomba,

  /// Terminar el dibujo (no se marca: es el último, con todo permitido).
  terminar,
}

/// Lo que quien juega intenta hacer en la pantalla de pintar.
enum AccionPintar {
  /// Tocar un color de la paleta.
  elegirColor,

  /// Tocar el dibujo para pintar una parte.
  pintar,

  /// Encender o apagar la lupa.
  lupa,

  /// Encender o apagar la bomba (y tirarla).
  bomba,
}

/// Paso que toca: el primero que falta, en orden.
PasoTutorial pasoActual(Set<PasoTutorial> hechos) =>
    PasoTutorial.values.firstWhere((p) => !hechos.contains(p), orElse: () => PasoTutorial.terminar);

/// Pasos hechos después de cumplir [paso]: solo cuenta si es el que tocaba
/// (los pasos van en orden; adelantarse no vale).
Set<PasoTutorial> cumplirPaso(Set<PasoTutorial> hechos, PasoTutorial paso) =>
    paso == pasoActual(hechos) && paso != PasoTutorial.terminar ? {...hechos, paso} : hechos;

/// ¿Se puede hacer [accion] durante [paso]?
bool accionPermitida(PasoTutorial paso, AccionPintar accion) => switch (paso) {
  PasoTutorial.elegirColor => accion == AccionPintar.elegirColor,
  PasoTutorial.completarColor =>
    accion == AccionPintar.elegirColor || accion == AccionPintar.pintar,
  // La lupa se usa tocando un color con la lupa encendida.
  PasoTutorial.lupa => accion == AccionPintar.lupa || accion == AccionPintar.elegirColor,
  PasoTutorial.bomba => accion == AccionPintar.bomba,
  PasoTutorial.terminar => true,
};

/// Estado del tutorial de la tienda.
enum EstadoTutorialTienda {
  /// Todavía no se completó el nivel 1.
  todaviaNo,

  /// Toca hacerlo: el juego lleva a la Tienda.
  pendiente,

  /// Se hizo (se compró la lupa) o se salteó.
  hecho,
}

/// Plumas que regala el tutorial de la tienda: las justas para una lupa.
int get plumasTutorialTienda => Herramienta.lupa.precio;

/// En qué está el tutorial de la tienda, según si ya se [hecho] y los
/// niveles completos de la historia.
EstadoTutorialTienda estadoTutorialTienda({
  required bool hecho,
  required List<int> nivelesCompletos,
}) {
  if (hecho) return EstadoTutorialTienda.hecho;
  return nivelesCompletos.contains(1)
      ? EstadoTutorialTienda.pendiente
      : EstadoTutorialTienda.todaviaNo;
}
