/// Colores del juego y acceso al catálogo y al progreso desde los widgets.
library;

import 'package:material_ui/material_ui.dart';

import '../datos/catalogo.dart';
import '../estado/progreso.dart';

abstract final class Tema {
  static const morado = Color(0xFF3D2C5E);
  static const crema = Color(0xFFFFF8EC);
  static const fondoLienzo = Color(0xFFF4F1EA);
  static const verde = Color(0xFF38761D);
  static const gris = Color(0xFF777777);

  static ThemeData get datos => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: morado),
    scaffoldBackgroundColor: crema,
  );
}

/// Catálogo y progreso disponibles para toda la app.
class Dependencias extends InheritedWidget {
  const Dependencias({
    super.key,
    required this.catalogo,
    required this.progreso,
    required super.child,
  });

  final Catalogo catalogo;
  final Progreso progreso;

  static Dependencias of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Dependencias>()!;

  @override
  bool updateShouldNotify(Dependencias old) => catalogo != old.catalogo || progreso != old.progreso;
}

/// Formato de fecha corto (dd/mm/aaaa) sin depender de paquetes de i18n.
String fechaCorta(int? ms) {
  if (ms == null) return '';
  final f = DateTime.fromMillisecondsSinceEpoch(ms);
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(f.day)}/${dos(f.month)}/${f.year}';
}

/// Pluma del Rocanón (moneda del juego), dibujada a mano: no depende de que
/// el teléfono tenga el emoji de pluma.
class IconoPluma extends StatelessWidget {
  const IconoPluma({super.key, this.tamano = 20, this.color = const Color(0xFFE8A33D)});
  final double tamano;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(tamano), painter: _PintorPluma(color));
}

class _PintorPluma extends CustomPainter {
  _PintorPluma(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final vane = Path()
      ..moveTo(w * 0.18, h * 0.92)
      ..cubicTo(w * 0.10, h * 0.45, w * 0.45, h * 0.08, w * 0.88, h * 0.06)
      ..cubicTo(w * 0.86, h * 0.50, w * 0.55, h * 0.85, w * 0.18, h * 0.92)
      ..close();
    canvas.drawPath(vane, Paint()..color = color);
    canvas.drawLine(
      Offset(w * 0.08, h * 0.98),
      Offset(w * 0.80, h * 0.16),
      Paint()
        ..color = const Color(0xFF8A5A1E)
        ..strokeWidth = w * 0.07
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_PintorPluma old) => old.color != color;
}

/// Saldo de plumas (se actualiza solo).
class ContadorPlumas extends StatelessWidget {
  const ContadorPlumas({super.key});

  @override
  Widget build(BuildContext context) {
    final progreso = Dependencias.of(context).progreso;
    return ListenableBuilder(
      listenable: progreso,
      builder: (context, _) => Semantics(
        label: '${progreso.plumas} plumas',
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3D6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const IconoPluma(tamano: 18),
              const SizedBox(width: 4),
              Text(
                '${progreso.plumas}',
                style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF8A5A1E)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Avatar provisorio de Gobi (hasta tener su ilustración): un círculo carmesí,
/// como el huevo del que nació, con una huellita.
class AvatarGobi extends StatelessWidget {
  const AvatarGobi({super.key, this.tamano = 56});
  final double tamano;

  @override
  Widget build(BuildContext context) => Container(
    width: tamano,
    height: tamano,
    decoration: BoxDecoration(
      color: const Color(0xFFB71C1C),
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0xFF2E7D32), width: 3),
    ),
    child: Icon(Icons.pets, color: Colors.white, size: tamano * 0.55),
  );
}
