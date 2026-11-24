/// Dibuja un cuadro con CustomPainter.
///
/// Con ilustración (cuadros de arte/):
///  - de fondo, la ilustración en blanco y negro aclarado: así se ve lo que
///    todavía no tiene color, con sus formas pero sin tapar los números;
///  - cada región pintada se rellena con la ilustración a color (luces,
///    sombras y brillos originales, no un color plano);
///  - las regiones pendientes del color elegido se marcan con un tinte.
/// Sin ilustración (cuadros hechos a mano): colores planos y grises.
///
/// Se dibuja en coordenadas del viewBox escaladas por [factor]; el zoom de
/// InteractiveViewer transforma el dibujo vectorial, así que se ve nítido.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../engine/motor.dart';

const _resalte = Color(0x803D2C5E); // tinte para el color elegido (con ilustración)
const _resaltePlano = Color(0xFF9A9A9A);
const _borde = Color(0xB3404040);
const _colorNumero = Color(0xFF222222);
const _destacado = Color(0xFFFFB300);

/// Blanco y negro aclarado: luminancia * 0.55 + 45% de blanco.
const _blancoYNegro = ColorFilter.matrix(<double>[
  0.2126 * 0.55, 0.7152 * 0.55, 0.0722 * 0.55, 0, 115, //
  0.2126 * 0.55, 0.7152 * 0.55, 0.0722 * 0.55, 0, 115,
  0.2126 * 0.55, 0.7152 * 0.55, 0.0722 * 0.55, 0, 115,
  0, 0, 0, 1, 0,
]);

class PintorCuadro extends CustomPainter {
  PintorCuadro({
    required this.cuadro,
    required this.pintadas,
    required this.factor,
    this.imagen,
    this.numeroElegido,
    this.mostrarNumeros = true,
    this.anchoBorde = 0.35,
    this.regionDestacada,
  });

  final Cuadro cuadro;
  final Set<String> pintadas;

  /// Puntos de pantalla por unidad del viewBox.
  final double factor;

  /// Ilustración original (null = colores planos).
  final ui.Image? imagen;
  final int? numeroElegido;
  final bool mostrarNumeros;

  /// Ancho del contorno en unidades del viewBox (~300 de lado mayor).
  final double anchoBorde;

  /// Región señalada por la lupa (se dibuja con un anillo).
  final String? regionDestacada;

  @override
  void paint(Canvas canvas, Size size) {
    final recursos = _Recursos.de(cuadro);
    canvas.save();
    canvas.scale(factor);
    final img = imagen;
    if (img != null) {
      _pintarConIlustracion(canvas, recursos, img);
    } else {
      _pintarPlano(canvas, recursos);
    }
    if (mostrarNumeros) _pintarNumeros(canvas);
    final destacada = regionDestacada;
    if (destacada != null) {
      final i = cuadro.regiones.indexWhere((r) => r.id == destacada);
      if (i >= 0) {
        canvas.drawPath(
          recursos.paths[i],
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = _destacado,
        );
      }
    }
    canvas.restore();
  }

  void _pintarConIlustracion(Canvas canvas, _Recursos recursos, ui.Image img) {
    final destino = Rect.fromLTWH(0, 0, cuadro.ancho, cuadro.alto);
    final origen = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
    canvas.drawImageRect(
      img,
      origen,
      destino,
      Paint()
        ..colorFilter = _blancoYNegro
        ..filterQuality = FilterQuality.medium,
    );

    final matriz = Float64List.fromList([
      cuadro.ancho / img.width, 0, 0, 0, //
      0, cuadro.alto / img.height, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 1,
    ]);
    final shader = ui.ImageShader(
      img,
      TileMode.clamp,
      TileMode.clamp,
      matriz,
      filterQuality: FilterQuality.medium,
    );
    final color = Paint()..shader = shader;
    // El mismo color como borde fino tapa las costuras entre regiones pintadas.
    final costura = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    final tinte = Paint()..color = _resalte;
    final contorno = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = anchoBorde
      ..color = _borde
      ..strokeJoin = StrokeJoin.round;

    for (var i = 0; i < cuadro.regiones.length; i++) {
      final r = cuadro.regiones[i];
      final path = recursos.paths[i];
      if (pintadas.contains(r.id)) {
        canvas.drawPath(path, color);
        canvas.drawPath(path, costura);
      } else {
        if (r.numero == numeroElegido) canvas.drawPath(path, tinte);
        canvas.drawPath(path, contorno);
      }
    }
  }

  void _pintarPlano(Canvas canvas, _Recursos recursos) {
    final relleno = Paint();
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
          ? _resaltePlano
          : recursos.grises[r.numero]!;
      contorno.color = pintada ? color : _borde;
      canvas.drawPath(recursos.paths[i], relleno);
      canvas.drawPath(recursos.paths[i], contorno);
    }
  }

  void _pintarNumeros(Canvas canvas) {
    for (final r in cuadro.regiones) {
      if (pintadas.contains(r.id)) continue;
      final tamano = tamanoNumero(r.radioEtiqueta);
      final halo = _Recursos.numero(r.numero, tamano, halo: true);
      final texto = _Recursos.numero(r.numero, tamano);
      final pos = Offset(r.etiqueta.x - texto.width / 2, r.etiqueta.y - texto.height / 2);
      halo.paint(canvas, pos);
      texto.paint(canvas, pos);
    }
  }

  @override
  bool shouldRepaint(PintorCuadro old) =>
      old.cuadro != cuadro ||
      old.pintadas != pintadas ||
      old.numeroElegido != numeroElegido ||
      old.factor != factor ||
      old.imagen != imagen ||
      old.regionDestacada != regionDestacada ||
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

  /// Textos de números ya medidos, por número, tamaño (décimas) y si es el halo.
  static final _numeros = <(int, int, bool), TextPainter>{};

  static TextPainter numero(int n, double tamano, {bool halo = false}) {
    final decimas = (tamano * 10).round();
    final fuente = decimas / 10;
    return _numeros[(n, decimas, halo)] ??= TextPainter(
      text: TextSpan(
        text: '$n',
        style: halo
            ? TextStyle(
                fontSize: fuente,
                height: 1,
                fontWeight: FontWeight.w600,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = fuente * 0.22
                  ..strokeJoin = StrokeJoin.round
                  ..color = const Color(0xE6FFFFFF),
              )
            : TextStyle(
                fontSize: fuente,
                height: 1,
                fontWeight: FontWeight.w600,
                color: _colorNumero,
              ),
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
