/// Dibuja un cuadro con CustomPainter: regiones pintadas con su color, el
/// resto en gris (con su número si [mostrarNumeros]). Las regiones del color
/// elegido que faltan se resaltan.
///
/// Se dibuja en coordenadas del viewBox escaladas por [factor]. El zoom de
/// InteractiveViewer transforma el dibujo vectorial, así que se ve nítido a
/// cualquier escala.
library;

import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../engine/motor.dart';

const _resalte = Color(0xFF9A9A9A);
const _borde = Color(0xFF555555);
const _colorNumero = Color(0xFF333333);

class PintorCuadro extends CustomPainter {
  PintorCuadro({
    required this.cuadro,
    required this.pintadas,
    required this.factor,
    this.numeroElegido,
    this.mostrarNumeros = true,
    this.anchoBorde = 0.4,
  });

  final Cuadro cuadro;
  final Set<String> pintadas;

  /// Puntos de pantalla por unidad del viewBox.
  final double factor;
  final int? numeroElegido;
  final bool mostrarNumeros;

  /// Ancho del contorno en unidades del viewBox (~300 de lado mayor).
  final double anchoBorde;

  @override
  void paint(Canvas canvas, Size size) {
    final recursos = _Recursos.de(cuadro);
    canvas.save();
    canvas.scale(factor);

    final relleno = Paint()..style = PaintingStyle.fill;
    final contorno = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = anchoBorde
      ..strokeJoin = StrokeJoin.round;

    for (var i = 0; i < cuadro.regiones.length; i++) {
      final r = cuadro.regiones[i];
      final color = recursos.colores[r.numero]!;
      final pintada = pintadas.contains(r.id);
      relleno.color = pintada
          ? color
          : r.numero == numeroElegido
          ? _resalte
          : recursos.grises[r.numero]!;
      // Pintada: el borde toma su color y el cuadro terminado no queda cuadriculado.
      contorno.color = pintada ? color : _borde;
      canvas.drawPath(recursos.paths[i], relleno);
      canvas.drawPath(recursos.paths[i], contorno);
    }

    if (mostrarNumeros) {
      for (final r in cuadro.regiones) {
        if (pintadas.contains(r.id)) continue;
        final texto = _Recursos.numero(r.numero, tamanoNumero(r.radioEtiqueta));
        texto.paint(
          canvas,
          Offset(r.etiqueta.x - texto.width / 2, r.etiqueta.y - texto.height / 2),
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(PintorCuadro old) =>
      old.cuadro != cuadro ||
      old.pintadas != pintadas ||
      old.numeroElegido != numeroElegido ||
      old.factor != factor ||
      old.mostrarNumeros != mostrarNumeros;
}

/// Paths y colores de cada cuadro, armados una sola vez.
class _Recursos {
  _Recursos(Cuadro c)
    : paths = [for (final r in c.regiones) _pathDe(r.comandos)],
      colores = {for (final p in c.paleta) p.numero: Color(argbDeHex(p.hex))},
      grises = {for (final p in c.paleta) p.numero: Color(grisSinColor(p.hex))};

  final List<ui.Path> paths;
  final Map<int, Color> colores;
  final Map<int, Color> grises;

  static final _porCuadro = Expando<_Recursos>();
  static _Recursos de(Cuadro c) => _porCuadro[c] ??= _Recursos(c);

  /// Textos de números ya medidos, por número y tamaño (redondeado a 0.1).
  static final _numeros = <(int, int), TextPainter>{};

  static TextPainter numero(int n, double tamano) {
    final decimas = (tamano * 10).round();
    return _numeros[(n, decimas)] ??= TextPainter(
      text: TextSpan(
        text: '$n',
        style: TextStyle(fontSize: decimas / 10, color: _colorNumero, height: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  static ui.Path _pathDe(List<Comando> comandos) {
    final path = ui.Path()..fillType = ui.PathFillType.evenOdd;
    for (final c in comandos) {
      switch (c) {
        case MoverA(:final p):
          path.moveTo(p.x, p.y);
        case LineaA(:final p):
          path.lineTo(p.x, p.y);
        case CubicaA(:final c1, :final c2, :final p):
          path.cubicTo(c1.x, c1.y, c2.x, c2.y, p.x, p.y);
        case CuadraticaA(:final c, :final p):
          path.quadraticBezierTo(c.x, c.y, p.x, p.y);
        case Cerrar():
          path.close();
      }
    }
    return path;
  }
}
