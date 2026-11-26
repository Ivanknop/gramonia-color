/// Tutoriales: el de pintar (nivel 0), con pasos obligatorios y en orden, y el de la tienda, al
/// completar el nivel 1. Los dos se pueden saltear.
library;

import 'plumas.dart';

const idTutorial = 'tutorial-arbol-magico';

enum PasoTutorial {
  elegirColor,
  completarColor,
  lupa,
  bomba,

  /// No se marca: es el último, con todo permitido.
  terminar,
}

enum AccionPintar { elegirColor, pintar, lupa, bomba }

PasoTutorial pasoActual(Set<PasoTutorial> hechos) =>
    PasoTutorial.values.firstWhere((p) => !hechos.contains(p), orElse: () => PasoTutorial.terminar);

/// Pasos hechos después de cumplir [paso]: solo cuenta si es el que tocaba
/// (los pasos van en orden; adelantarse no vale).
Set<PasoTutorial> cumplirPaso(Set<PasoTutorial> hechos, PasoTutorial paso) =>
    paso == pasoActual(hechos) && paso != PasoTutorial.terminar ? {...hechos, paso} : hechos;

bool accionPermitida(PasoTutorial paso, AccionPintar accion) => switch (paso) {
  PasoTutorial.elegirColor => accion == AccionPintar.elegirColor,
  PasoTutorial.completarColor =>
    accion == AccionPintar.elegirColor || accion == AccionPintar.pintar,
  // La lupa se usa tocando un color con la lupa encendida.
  PasoTutorial.lupa => accion == AccionPintar.lupa || accion == AccionPintar.elegirColor,
  PasoTutorial.bomba => accion == AccionPintar.bomba,
  PasoTutorial.terminar => true,
};

enum EstadoTutorialTienda { todaviaNo, pendiente, hecho }

int get plumasTutorialTienda => Herramienta.lupa.precio;

EstadoTutorialTienda estadoTutorialTienda({
  required bool hecho,
  required List<int> nivelesCompletos,
}) {
  if (hecho) return EstadoTutorialTienda.hecho;
  return nivelesCompletos.contains(1)
      ? EstadoTutorialTienda.pendiente
      : EstadoTutorialTienda.todaviaNo;
}
