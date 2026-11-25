/// Dibuja un cuadro con CustomPainter.
///
/// Con ilustración (cuadros de arte/):
///  - lo que falta pintar es blanco con contornos negros y su número, como un
///    libro para colorear (blanco y negro puro, sin grises);
///  - cada región pintada se rellena con la ilustración a color (luces,
///    sombras y brillos originales, no un color plano);
///  - al pintar, el color se expande desde donde se tocó hasta llenar la
///    región ([animaciones], que avanzan con [reloj]);
///  - las regiones pendientes del color elegido se marcan con un tinte suave.
/// Sin ilustración: colores planos y grises.
///
/// Se dibuja en coordenadas del viewBox escaladas por [factor]; el zoom de
/// InteractiveViewer transforma el dibujo vectorial, así que se ve nítido.
library;

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../engine/motor.dart';

const _resalte = Color(0x333D2C5E); // tinte suave para el color elegido
const _resaltePlano = Color(0xFF9A9A9A);
const _borde = Color(0xFF000000);
const _bordePlano = Color(0xB3404040);
const _colorNumero = Color(0xFF222222);
const _destacado = Color(0xFFFFB300);

/// Relleno en curso de una región: el color crece desde [origen].
class RellenoAnimado {
  const RellenoAnimado({required this.origen, required this.inicio, required this.duracion});

  /// Punto (viewBox) desde donde se expande el color.
  final Punto origen;

  /// Momento de inicio, medido en el [PintorCuadro.reloj].
  final Duration inicio;
  final Duration duracion;
}

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
    this.animaciones = const {},
    this.reloj,
  }) : super(repaint: reloj);

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

  /// Regiones pintadas cuyo color todavía se está expandiendo.
  final Map<String, RellenoAnimado> animaciones;

  /// Tiempo de las animaciones; cada tic vuelve a dibujar.
  final ValueListenable<Duration>? reloj;

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
    canvas.drawRect(
      Rect.fromLTWH(0, 0, cuadro.ancho, cuadro.alto),
      Paint()..color = const Color(0xFFFFFFFF),
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
    final ahora = reloj?.value ?? Duration.zero;

    // 1) Color: regiones pintadas (las recién tocadas, a medio llenar).
    for (var i = 0; i < cuadro.regiones.length; i++) {
      final r = cuadro.regiones[i];
      if (!pintadas.contains(r.id)) continue;
      final path = recursos.paths[i];
      final anim = animaciones[r.id];
      final avance = anim == null ? 1.0 : avanceAnimacion(ahora, anim.inicio, anim.duracion);
      if (avance >= 1) {
        canvas.drawPath(path, color);
        canvas.drawPath(path, costura);
      } else if (avance > 0) {
        final o = anim!.origen;
        canvas.save();
        canvas.clipPath(path);
        canvas.drawCircle(Offset(o.x, o.y), radioParaCubrir(r.caja, o) * avance, color);
        canvas.restore();
      }
    }
    // 2) Pendientes: tinte del color elegido y contorno negro (también en las
    //    que se están llenando, hasta que terminan).
    for (var i = 0; i < cuadro.regiones.length; i++) {
      final r = cuadro.regiones[i];
      final pintada = pintadas.contains(r.id);
      final animando =
          pintada &&
          animaciones[r.id] != null &&
          avanceAnimacion(ahora, animaciones[r.id]!.inicio, animaciones[r.id]!.duracion) < 1;
      if (pintada && !animando) continue;
      if (!pintada && r.numero == numeroElegido) canvas.drawPath(recursos.paths[i], tinte);
      canvas.drawPath(recursos.paths[i], contorno);
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
      contorno.color = pintada ? color : _bordePlano;
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
      old.animaciones != animaciones ||
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
                fontFamily: 'Roboto', // la del sistema en Android
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
                fontFamily: 'Roboto',
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
