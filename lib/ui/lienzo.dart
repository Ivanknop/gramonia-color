/// Lienzo con zoom y paneo (InteractiveViewer): pellizcar para acercar,
/// arrastrar para mover y tocar para pintar. El toque se convierte a
/// coordenadas del viewBox y el motor (regionEnPunto) decide qué región es.
library;

import 'package:material_ui/material_ui.dart';

import '../engine/motor.dart';
import 'comun.dart';
import 'pintor_cuadro.dart';

class Lienzo extends StatefulWidget {
  const Lienzo({
    super.key,
    required this.cuadro,
    required this.pintadas,
    required this.numeroElegido,
    required this.onToque,
  });

  final Cuadro cuadro;
  final Set<String> pintadas;
  final int? numeroElegido;

  /// Toque en coordenadas del viewBox del cuadro.
  final ValueChanged<Punto> onToque;

  @override
  State<Lienzo> createState() => _LienzoState();
}

class _LienzoState extends State<Lienzo> with SingleTickerProviderStateMixin {
  final _transformacion = TransformationController();
  late final _animacion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  Animation<Matrix4>? _encuadre;
  bool _conZoom = false;

  @override
  void initState() {
    super.initState();
    _transformacion.addListener(_alTransformar);
    _animacion.addListener(() {
      if (_encuadre != null) _transformacion.value = _encuadre!.value;
    });
  }

  @override
  void dispose() {
    _transformacion.dispose();
    _animacion.dispose();
    super.dispose();
  }

  void _alTransformar() {
    final conZoom = _transformacion.value.getMaxScaleOnAxis() > 1.01;
    if (conZoom != _conZoom) setState(() => _conZoom = conZoom);
  }

  void _encuadrar() {
    _encuadre = Matrix4Tween(
      begin: _transformacion.value,
      end: Matrix4.identity(),
    ).animate(CurvedAnimation(parent: _animacion, curve: Curves.easeOut));
    _animacion.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final cuadro = widget.cuadro;
    return ColoredBox(
      color: Tema.fondoLienzo,
      child: LayoutBuilder(
        builder: (context, limites) {
          final factor = (limites.maxWidth / cuadro.ancho) < (limites.maxHeight / cuadro.alto)
              ? limites.maxWidth / cuadro.ancho
              : limites.maxHeight / cuadro.alto;
          final maximo = escalaMaxima(cuadro.regiones.map((r) => r.radioEtiqueta), factor);
          return Stack(
            children: [
              InteractiveViewer(
                transformationController: _transformacion,
                minScale: 1,
                maxScale: maximo,
                child: SizedBox(
                  width: limites.maxWidth,
                  height: limites.maxHeight,
                  child: Center(
                    child: GestureDetector(
                      onTapUp: (d) => widget.onToque(
                        Punto(d.localPosition.dx / factor, d.localPosition.dy / factor),
                      ),
                      child: RepaintBoundary(
                        child: CustomPaint(
                          key: const Key('lienzo'),
                          size: Size(cuadro.ancho * factor, cuadro.alto * factor),
                          painter: PintorCuadro(
                            cuadro: cuadro,
                            pintadas: widget.pintadas,
                            numeroElegido: widget.numeroElegido,
                            factor: factor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_conZoom)
                Positioned(
                  top: 12,
                  right: 12,
                  child: FilledButton.tonal(onPressed: _encuadrar, child: const Text('Encuadrar')),
                ),
            ],
          );
        },
      ),
    );
  }
}
