/// Confeti del festejo: papelitos que salen disparados desde abajo, frenan con
/// el aire y caen girando. Todo en fracciones de la pantalla (0..1), así el
/// dibujo no depende del tamaño. Con la misma semilla, siempre igual.
library;

import 'dart:math' as math;

class Papelito {
  const Papelito({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.giro,
    required this.color,
    required this.tamano,
    required this.demora,
  });

  /// Posición de salida y velocidad inicial (fracciones de pantalla por segundo).
  final double x, y, vx, vy;

  /// Vueltas por segundo (con signo).
  final double giro;

  /// Índice en la lista de colores del confeti.
  final int color;

  /// Lado, en fracción del ancho de la pantalla.
  final double tamano;

  /// Segundos que tarda en salir (dos tandas).
  final double demora;
}

/// Dónde está un papelito a los [t] segundos del festejo.
typedef EstadoPapelito = ({double x, double y, double angulo, bool visible});

abstract final class Confeti {
  static const gravedad = 1.4;

  /// Freno del aire (por segundo).
  static const freno = 1.6;

  /// Duración total del festejo, en segundos.
  static const duracion = 3.2;

  static const colores = <int>[
    0xFFE53935, 0xFFFB8C00, 0xFFFDD835, 0xFF43A047, 0xFF1E88E5, 0xFF3949AB, 0xFF8E24AA, // arcoíris
    0xFFF48FB1,
  ];

  /// Dos tandas de papelitos desde las esquinas de abajo, hacia el centro.
  static List<Papelito> lanzar({int cantidad = 120, int semilla = 0}) {
    final azar = math.Random(semilla);
    return [
      for (var i = 0; i < cantidad; i++)
        () {
          final izquierda = i.isEven;
          final tanda = (i ~/ 2).isEven ? 0.0 : 0.35;
          final angulo = (55 + azar.nextDouble() * 30) * math.pi / 180;
          final rapidez = 1.6 + azar.nextDouble() * 1.1;
          return Papelito(
            x: izquierda ? 0.0 : 1.0,
            y: 1.0,
            vx: (izquierda ? 1 : -1) * math.cos(angulo) * rapidez,
            vy: -math.sin(angulo) * rapidez,
            giro: (azar.nextDouble() * 2 - 1) * 3,
            color: azar.nextInt(colores.length),
            tamano: 0.014 + azar.nextDouble() * 0.014,
            demora: tanda + azar.nextDouble() * 0.15,
          );
        }(),
    ];
  }

  /// Movimiento con freno lineal del aire: la velocidad decae como e^(-freno·t)
  /// y la gravedad la empuja hacia abajo hasta una velocidad límite.
  static EstadoPapelito en(Papelito p, double t) {
    final s = t - p.demora;
    if (s < 0) return (x: p.x, y: p.y, angulo: 0, visible: false);
    final decae = (1 - math.exp(-freno * s)) / freno;
    final limite = gravedad / freno;
    final x = p.x + p.vx * decae;
    // y crece hacia abajo: la gravedad suma.
    final y = p.y + p.vy * decae + limite * (s - decae);
    return (x: x, y: y, angulo: p.giro * 2 * math.pi * s, visible: y < 1.1 && s < duracion);
  }
}
