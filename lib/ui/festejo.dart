/// Festejo al terminar un cuadro: confeti de colores y un cartel que rebota.
/// No intercepta toques. Avisa con [alTerminar] cuando termina.
library;

import 'package:material_ui/material_ui.dart';

import '../datos/textos.dart';
import '../engine/confeti.dart';
import 'comun.dart';

class Festejo extends StatefulWidget {
  const Festejo({super.key, this.alTerminar, this.semilla = 0});
  final VoidCallback? alTerminar;
  final int semilla;

  @override
  State<Festejo> createState() => _FestejoState();
}

class _FestejoState extends State<Festejo> with SingleTickerProviderStateMixin {
  late final _papelitos = Confeti.lanzar(semilla: widget.semilla);
  late final _animacion =
      AnimationController(
          vsync: this,
          duration: Duration(milliseconds: (Confeti.duracion * 1000).round()),
        )
        ..addStatusListener((estado) {
          if (estado == AnimationStatus.completed) widget.alTerminar?.call();
        })
        ..forward();

  @override
  void dispose() {
    _animacion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _animacion,
        builder: (context, _) {
          final t = _animacion.value * Confeti.duracion;
          // Cartel: entra rebotando y se va desvaneciendo al final.
          final entrada = Curves.elasticOut.transform((t / 0.9).clamp(0, 1));
          final salida = 1 - ((t - Confeti.duracion + 0.6) / 0.6).clamp(0.0, 1.0);
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _PintorConfeti(_papelitos, t)),
              Center(
                child: Opacity(
                  opacity: salida,
                  child: Transform.scale(
                    scale: entrada,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [BoxShadow(blurRadius: 16, color: Color(0x55000000))],
                      ),
                      child: const Text(
                        Textos.festejo,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Tema.morado,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PintorConfeti extends CustomPainter {
  _PintorConfeti(this.papelitos, this.t);
  final List<Papelito> papelitos;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final pincel = Paint();
    for (final p in papelitos) {
      final e = Confeti.en(p, t);
      if (!e.visible) continue;
      final lado = p.tamano * size.width;
      pincel.color = Color(Confeti.colores[p.color]);
      canvas
        ..save()
        ..translate(e.x * size.width, e.y * size.height)
        ..rotate(e.angulo)
        // Rectángulo que "aletea": se achica en un eje al girar.
        ..drawRect(Rect.fromCenter(center: Offset.zero, width: lado, height: lado * 0.55), pincel)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_PintorConfeti old) => old.t != t;
}
