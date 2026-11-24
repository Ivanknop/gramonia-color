/// Vista chica de un cuadro tal como lo dejó el jugador (sin números): lo
/// pintado a color y el resto en blanco y negro.
library;

import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../engine/motor.dart';
import 'comun.dart';
import 'pintor_cuadro.dart';

class Miniatura extends StatelessWidget {
  const Miniatura({super.key, required this.cuadro, required this.pintadas, this.tamano = 72});

  final Cuadro cuadro;
  final Set<String> pintadas;

  /// Lado mayor en puntos.
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final factor = tamano / (cuadro.ancho > cuadro.alto ? cuadro.ancho : cuadro.alto);
    return SizedBox(
      width: tamano,
      height: tamano,
      child: Center(
        child: FutureBuilder<ui.Image?>(
          future: Dependencias.of(context).catalogo.imagen(cuadro.id),
          builder: (context, imagen) => CustomPaint(
            size: Size(cuadro.ancho * factor, cuadro.alto * factor),
            painter: PintorCuadro(
              cuadro: cuadro,
              pintadas: pintadas,
              factor: factor,
              imagen: imagen.data,
              mostrarNumeros: false,
              // Medio punto de pantalla, en unidades del viewBox.
              anchoBorde: 0.5 / factor,
            ),
          ),
        ),
      ),
    );
  }
}
