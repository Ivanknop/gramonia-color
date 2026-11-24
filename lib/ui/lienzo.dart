/// Lienzo con zoom y paneo (InteractiveViewer): pellizcar para acercar,
/// arrastrar para mover y tocar para pintar.
///
/// - Arranca en "cobertura": el cuadro llena todo el espacio disponible (más
///   grande para el dedo); se puede alejar hasta verlo entero.
/// - El toque se convierte a coordenadas del viewBox y va con una tolerancia
///   de ~[toleranciaDedo] puntos de pantalla, para que el motor perdone un
///   dedo que cae un poco al costado de una región chica.
/// - [LienzoState.enfocar] acerca la vista a una región (lo usa la lupa).
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../engine/motor.dart';
import 'comun.dart';
import 'pintor_cuadro.dart';

/// Tolerancia del toque, en puntos de pantalla.
const toleranciaDedo = 14.0;

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

class LienzoState extends State<Lienzo> with SingleTickerProviderStateMixin {
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
    _transformacion.dispose();
    _animacion.dispose();
    super.dispose();
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
                      onTapUp: (d) => widget.onToque(
                        Punto(d.localPosition.dx / _factor, d.localPosition.dy / _factor),
                        toleranciaDedo / (_factor * _escala),
                      ),
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
                  child: FilledButton.tonal(onPressed: encuadrar, child: const Text('Encuadrar')),
                ),
            ],
          );
        },
      ),
    );
  }
}
