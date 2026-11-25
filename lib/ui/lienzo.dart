/// Lienzo con zoom y paneo (InteractiveViewer): pellizcar para acercar,
/// arrastrar para mover y tocar para pintar.
///
/// - Arranca en "cobertura": el cuadro llena todo el espacio disponible (más
///   grande para el dedo); se puede alejar hasta verlo entero.
/// - El toque se convierte a coordenadas del viewBox y va con una tolerancia
///   de ~[toleranciaDedo] puntos de pantalla, para que el motor perdone un
///   dedo que cae un poco al costado de una región chica.
/// - [LienzoState.enfocar] acerca la vista a una región (lo usa la lupa).
/// - Cuando aparecen regiones nuevas en [Lienzo.pintadas], su color se expande
///   desde el último toque (con la bomba, en onda desde donde cayó).
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import '../engine/motor.dart';
import 'comun.dart';
import 'pintor_cuadro.dart';

/// Tolerancia del toque, en puntos de pantalla.
const toleranciaDedo = 14.0;

/// Cuánto tarda el color en llenar una región.
const duracionRelleno = Duration(milliseconds: 650);

/// Demora máxima de la onda de la bomba (las regiones más lejanas, al final).
const demoraOndaBomba = Duration(milliseconds: 450);

/// Con más regiones nuevas de golpe que esto no se anima (por ejemplo, al
/// cargar progreso guardado): se muestran pintadas directamente.
const maximoAnimadas = 80;

class Lienzo extends StatefulWidget {
  const Lienzo({
    super.key,
    required this.cuadro,
    required this.pintadas,
    required this.numeroElegido,
    required this.onToque,
    this.imagen,
    this.regionDestacada,
  });

  final Cuadro cuadro;
  final Set<String> pintadas;
  final int? numeroElegido;
  final ui.Image? imagen;
  final String? regionDestacada;

  /// Toque en coordenadas del viewBox y tolerancia (en las mismas unidades).
  final void Function(Punto punto, double tolerancia) onToque;

  @override
  State<Lienzo> createState() => LienzoState();
}

class LienzoState extends State<Lienzo> with TickerProviderStateMixin {
  final _transformacion = TransformationController();
  late final _animacion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );
  Animation<Matrix4>? _destinoAnimado;
  Size? _area;
  double _factor = 1;
  double _maximo = 4;
  bool _alejado = false;
  bool _ajustandoEnBuild = false;

  // Relleno animado: un ticker que corre solo mientras haya regiones llenándose.
  late final Ticker _ticker = createTicker(_alTic);
  final _reloj = ValueNotifier<Duration>(Duration.zero);
  final _animaciones = <String, RellenoAnimado>{};
  Punto? _ultimoToque;

  @override
  void initState() {
    super.initState();
    _transformacion.addListener(_alTransformar);
    _animacion.addListener(() {
      final d = _destinoAnimado;
      if (d != null) _transformacion.value = d.value;
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _reloj.dispose();
    _transformacion.dispose();
    _animacion.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(Lienzo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cuadro != widget.cuadro) return;
    final nuevas = widget.pintadas.difference(oldWidget.pintadas);
    if (nuevas.isEmpty || nuevas.length > maximoAnimadas) return;
    _animar(nuevas);
  }

  void _animar(Set<String> nuevas) {
    if (!_ticker.isActive) {
      _reloj.value = Duration.zero;
      _ticker.start();
    }
    final ahora = _reloj.value;
    final toque = _ultimoToque;
    final regiones = [
      for (final r in widget.cuadro.regiones)
        if (nuevas.contains(r.id)) r,
    ];
    final esOnda = regiones.length > 1 && toque != null;
    final alcance = esOnda
        ? regiones
              .map((r) => _distancia(r.etiqueta, toque))
              .reduce(math.max)
              .clamp(1e-6, double.infinity)
        : 1.0;
    for (final r in regiones) {
      // Desde el dedo si tocó dentro (o cerca) de la región; si no, desde el número.
      final Punto origen;
      if (esOnda) {
        origen = toque;
      } else if (toque != null && _cerca(r, toque)) {
        origen = toque;
      } else {
        origen = r.etiqueta;
      }
      final demora = esOnda
          ? demoraOndaBomba * (_distancia(r.etiqueta, toque) / alcance)
          : Duration.zero;
      _animaciones[r.id] = RellenoAnimado(
        origen: origen,
        inicio: ahora + demora,
        duracion: duracionRelleno,
      );
    }
  }

  static double _distancia(Punto a, Punto b) =>
      math.sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y));

  static bool _cerca(Region r, Punto p) {
    final c = r.caja;
    final m = math.max(c.maxX - c.minX, c.maxY - c.minY) * 0.25;
    return p.x >= c.minX - m && p.x <= c.maxX + m && p.y >= c.minY - m && p.y <= c.maxY + m;
  }

  void _alTic(Duration transcurrido) {
    _reloj.value = transcurrido;
    _animaciones.removeWhere((_, a) => transcurrido >= a.inicio + a.duracion);
    if (_animaciones.isEmpty) {
      _ticker.stop();
      // Un último dibujado ya sin animaciones (contornos finales).
      setState(() {});
    }
  }

  double get _escala => _transformacion.value.getMaxScaleOnAxis();

  /// Escala que hace que el cuadro llene el área (recortando lo que sobre).
  double _escalaCobertura(Size area) {
    final c = widget.cuadro;
    final ajuste = math.min(area.width / c.ancho, area.height / c.alto);
    return math.max(area.width / c.ancho, area.height / c.alto) / ajuste;
  }

  Matrix4 _matrizCentrada(Size area, double escala, Offset centroContenido) {
    // Lleva el punto `centroContenido` (coordenadas del hijo) al centro del área.
    final tx = area.width / 2 - centroContenido.dx * escala;
    final ty = area.height / 2 - centroContenido.dy * escala;
    return Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1)
      ..scaleByDouble(escala, escala, 1, 1);
  }

  void _alTransformar() {
    final area = _area;
    if (area == null || _ajustandoEnBuild) return;
    final alejado = (_escala - _escalaCobertura(area)).abs() > 0.02;
    if (alejado != _alejado) setState(() => _alejado = alejado);
  }

  void _animarA(Matrix4 destino) {
    _destinoAnimado = Matrix4Tween(
      begin: _transformacion.value,
      end: destino,
    ).animate(CurvedAnimation(parent: _animacion, curve: Curves.easeInOut));
    _animacion.forward(from: 0);
  }

  /// Vuelve a la vista inicial (cuadro llenando el área).
  void encuadrar() {
    final area = _area;
    if (area == null) return;
    _animarA(_matrizCentrada(area, _escalaCobertura(area), area.center(Offset.zero)));
  }

  /// Acerca la vista para mostrar bien una región (lupa).
  void enfocar(Region region) {
    final area = _area;
    if (area == null) return;
    final c = region.caja;
    final ancho = math.max(c.maxX - c.minX, 8.0) * _factor;
    final alto = math.max(c.maxY - c.minY, 8.0) * _factor;
    // Que la región ocupe ~35% del área, sin pasarse del zoom máximo.
    final escala = math
        .min(area.width * 0.35 / ancho, area.height * 0.35 / alto)
        .clamp(_escalaCobertura(area), _maximo);
    final centro =
        _origenContenido(area) + Offset(region.etiqueta.x * _factor, region.etiqueta.y * _factor);
    _animarA(_matrizCentrada(area, escala, centro));
  }

  /// Esquina superior izquierda del cuadro dentro del hijo del InteractiveViewer.
  Offset _origenContenido(Size area) => Offset(
    (area.width - widget.cuadro.ancho * _factor) / 2,
    (area.height - widget.cuadro.alto * _factor) / 2,
  );

  @override
  Widget build(BuildContext context) {
    final cuadro = widget.cuadro;
    return ColoredBox(
      color: Tema.fondoLienzo,
      child: LayoutBuilder(
        builder: (context, limites) {
          final area = Size(limites.maxWidth, limites.maxHeight);
          _factor = math.min(area.width / cuadro.ancho, area.height / cuadro.alto);
          final maximo = _maximo =
              escalaMaxima(cuadro.regiones.map((r) => r.radioEtiqueta), _factor) *
              _escalaCobertura(area);
          if (_area != area) {
            // Primera vez (o cambió el tamaño): vista inicial en cobertura.
            _area = area;
            _alejado = false;
            _ajustandoEnBuild = true; // sin setState: ya estamos en build
            _transformacion.value = _matrizCentrada(
              area,
              _escalaCobertura(area),
              area.center(Offset.zero),
            );
            _ajustandoEnBuild = false;
          }
          return Stack(
            children: [
              InteractiveViewer(
                transformationController: _transformacion,
                minScale: 1,
                maxScale: maximo,
                child: SizedBox(
                  width: area.width,
                  height: area.height,
                  child: Center(
                    child: GestureDetector(
                      onTapUp: (d) {
                        final p = Punto(d.localPosition.dx / _factor, d.localPosition.dy / _factor);
                        _ultimoToque = p;
                        widget.onToque(p, toleranciaDedo / (_factor * _escala));
                      },
                      child: RepaintBoundary(
                        child: CustomPaint(
                          key: const Key('lienzo'),
                          size: Size(cuadro.ancho * _factor, cuadro.alto * _factor),
                          painter: PintorCuadro(
                            cuadro: cuadro,
                            pintadas: widget.pintadas,
                            numeroElegido: widget.numeroElegido,
                            factor: _factor,
                            imagen: widget.imagen,
                            regionDestacada: widget.regionDestacada,
                            animaciones: _animaciones,
                            reloj: _reloj,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_alejado)
                Positioned(
                  top: 8,
                  right: 8,
                  child: FilledButton.tonal(
                    style: Tema.botonAqua,
                    onPressed: encuadrar,
                    child: const Text('Encuadrar'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
