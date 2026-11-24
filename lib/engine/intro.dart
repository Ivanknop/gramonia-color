/// Intro de la portada: el mapa de Gramonia arranca a todo color, se apaga
/// hasta el blanco y negro (Mututu robando los colores) y aparece el título
/// "Gramonia… Color" en dos tiempos; después, el botón. Todo en segundos desde
/// que arranca, para poder testearlo sin widgets.
library;

abstract final class Intro {
  /// El mapa a color, quieto, antes de empezar a apagarse.
  static const quieto = 0.4;

  /// Lo que tarda el color en apagarse (unos 2-3 segundos).
  static const apagado = 2.5;

  /// Lo que tarda en aparecer cada parte del título y los botones.
  static const aparicion = 0.6;

  /// Pausa entre "Gramonia…" y "Color".
  static const pausa = 0.5;

  static const finApagado = quieto + apagado;
  static const inicioGramonia = finApagado + 0.1;
  static const inicioColor = inicioGramonia + aparicion + pausa;
  static const inicioBotones = inicioColor + aparicion + 0.2;
  static const duracion = inicioBotones + aparicion;

  /// Qué se ve a los [t] segundos: saturación del mapa (1 = color, 0 = gris)
  /// y opacidad (0..1) de cada parte.
  static ({double saturacion, double gramonia, double color, double botones}) en(double t) {
    double entre(double desde, double largo) => ((t - desde) / largo).clamp(0.0, 1.0);
    return (
      saturacion: 1 - entre(quieto, apagado),
      gramonia: entre(inicioGramonia, aparicion),
      color: entre(inicioColor, aparicion),
      botones: entre(inicioBotones, aparicion),
    );
  }
}

/// Matriz de color 4x5 (para `ColorFilter.matrix`) que deja la imagen con
/// [saturacion] (1 = original, 0 = blanco y negro), con los pesos de
/// luminancia de Rec. 709.
List<double> matrizSaturacion(double saturacion) {
  const r = 0.2126, g = 0.7152, b = 0.0722;
  final s = saturacion.clamp(0.0, 1.0);
  final i = 1 - s;
  return [
    r * i + s, g * i, b * i, 0, 0, //
    r * i, g * i + s, b * i, 0, 0,
    r * i, g * i, b * i + s, 0, 0,
    0, 0, 0, 1, 0,
  ];
}
