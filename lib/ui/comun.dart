/// Colores del juego y acceso al catálogo y al progreso desde los widgets.
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../datos/catalogo.dart';
import '../datos/textos.dart';
import '../estado/musica.dart';
import '../estado/progreso.dart';

abstract final class Tema {
  static const morado = Color(0xFF3D2C5E);
  static const crema = Color(0xFFFFF8EC);
  static const fondoLienzo = Color(0xFFF4F1EA);
  static const verde = Color(0xFF38761D);
  static const gris = Color(0xFF777777);

  /// Lilas del título "Gramonia… Color" (degradado de arriba hacia abajo) y
  /// su contorno oscuro, para que se lea sobre el mapa en gris.
  static const lilaClaro = Color(0xFFC8A2C8);
  static const lilaOscuro = Color(0xFF9B6FBF);
  static const contornoTitulo = Color(0xFF2E1F47);

  /// Tipografía del canon para títulos y logo (un solo peso: sin negrita).
  static const fuenteTitulos = 'LuckiestGuy';

  // ---- Botones: redondos, en lilas, celestes y verde agua ----

  /// Botón principal (relleno): lila con texto blanco.
  static const lila = Color(0xFF8A5CB5);
  static const lilaSuave = Color(0xFFE9DDF7);

  /// Botón secundario (con borde): celeste.
  static const celeste = Color(0xFF6CC4EE);
  static const celesteSuave = Color(0xFFE0F4FD);

  /// Herramientas y botones de texto: verde agua.
  static const aqua = Color(0xFF3FC9B4);
  static const aquaSuave = Color(0xFFD6F5EF);

  static const _relleno = EdgeInsets.symmetric(horizontal: 22, vertical: 12);

  /// La tipografía va explícita: el estilo del botón reemplaza al del tema.
  static const _textoBoton = TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w700);

  /// Verde agua (herramientas, "Encuadrar"): se usa con `FilledButton.tonal`.
  static ButtonStyle get botonAqua => FilledButton.styleFrom(
    backgroundColor: aquaSuave,
    foregroundColor: morado,
    shape: const StadiumBorder(),
    side: const BorderSide(color: aqua, width: 2),
  );

  static ThemeData get datos => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: lila, primary: lila),
    scaffoldBackgroundColor: crema,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: lila,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        padding: _relleno,
        textStyle: _textoBoton,
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: celesteSuave,
        foregroundColor: morado,
        side: const BorderSide(color: celeste, width: 2),
        shape: const StadiumBorder(),
        padding: _relleno,
        textStyle: _textoBoton,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        backgroundColor: aquaSuave,
        foregroundColor: morado,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: _textoBoton,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        backgroundColor: aquaSuave,
        foregroundColor: morado,
        shape: const CircleBorder(),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      indicatorColor: lilaSuave,
      indicatorShape: StadiumBorder(),
    ),
  );
}

/// Flecha en espiral (para "Repetir" y "Rehacer": volver a empezar).
class IconoEspiral extends StatelessWidget {
  const IconoEspiral({super.key, this.tamano = 20, this.color});
  final double tamano;

  /// Por defecto, el color de los íconos del botón donde está.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? IconTheme.of(context).color ?? Tema.morado;
    return CustomPaint(size: Size.square(tamano), painter: _PintorEspiral(color));
  }
}

class _PintorEspiral extends CustomPainter {
  _PintorEspiral(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    // Espiral de Arquímedes: de adentro hacia afuera, una vuelta y media larga.
    const vueltas = 1.75;
    const pasos = 60;
    final camino = Path();
    Offset punto(double t) {
      final ang = -math.pi / 2 + t * vueltas * 2 * math.pi;
      final radio = r * (0.12 + 0.68 * t);
      return c + Offset(math.cos(ang), math.sin(ang)) * radio;
    }

    for (var i = 0; i <= pasos; i++) {
      final p = punto(i / pasos);
      i == 0 ? camino.moveTo(p.dx, p.dy) : camino.lineTo(p.dx, p.dy);
    }
    final trazo = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.17
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(camino, trazo);
    // Punta de flecha al final, en la dirección del trazo.
    final fin = punto(1);
    final antes = punto(0.97);
    final dir = (fin - antes) / (fin - antes).distance;
    final normal = Offset(-dir.dy, dir.dx);
    final largo = r * 0.42;
    final punta = Path()
      ..moveTo(fin.dx + dir.dx * largo * 0.6, fin.dy + dir.dy * largo * 0.6)
      ..lineTo(fin.dx + normal.dx * largo * 0.55, fin.dy + normal.dy * largo * 0.55)
      ..lineTo(fin.dx - normal.dx * largo * 0.55, fin.dy - normal.dy * largo * 0.55)
      ..close();
    canvas.drawPath(punta, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PintorEspiral old) => old.color != color;
}

/// Catálogo, progreso y música disponibles para toda la app.
class Dependencias extends InheritedWidget {
  const Dependencias({
    super.key,
    required this.catalogo,
    required this.progreso,
    this.musica,
    required super.child,
  });

  final Catalogo catalogo;
  final Progreso progreso;

  /// Música de fondo (null = sin música, por ejemplo en algunos tests).
  final Musica? musica;

  static Dependencias of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Dependencias>()!;

  @override
  bool updateShouldNotify(Dependencias old) =>
      catalogo != old.catalogo || progreso != old.progreso || musica != old.musica;
}

/// Título con la tipografía del canon, relleno con el degradado de lilas y
/// contorno oscuro.
class TituloLila extends StatelessWidget {
  const TituloLila(this.texto, {super.key, this.tamano = 48});
  final String texto;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(fontFamily: Tema.fuenteTitulos, fontSize: tamano, height: 1.1);
    return Stack(
      children: [
        Text(
          texto,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = tamano / 7
              ..strokeJoin = StrokeJoin.round
              ..color = Tema.contornoTitulo,
          ),
        ),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (r) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Tema.lilaClaro, Tema.lilaOscuro],
          ).createShader(r),
          child: Text(texto, style: base.copyWith(color: Colors.white)),
        ),
      ],
    );
  }
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

/// Vuelve a la portada (la primera pantalla), cerrando todo lo de arriba.
void volverAPortada(BuildContext context) => Navigator.of(context).popUntil((ruta) => ruta.isFirst);

/// Barra de abajo con la flecha que vuelve a la portada (para las pantallas
/// que no tienen pestañas, como el modo libre).
class BarraPortada extends StatelessWidget {
  const BarraPortada({super.key});

  @override
  Widget build(BuildContext context) => BottomAppBar(
    height: 64,
    child: Row(
      children: [
        TextButton.icon(
          key: const Key('volver-a-portada'),
          onPressed: () => volverAPortada(context),
          icon: const Icon(Icons.arrow_back),
          label: const Text(Textos.portada),
        ),
      ],
    ),
  );
}

/// Íconos de las herramientas y de la tienda (de arte/, con
/// `scripts/convertir_arte.py iconos`).
const iconoLupa = 'assets/iconos/lupa.png';
const iconoBomba = 'assets/iconos/bomba.png';
const iconoTienda = 'assets/iconos/tienda.png';

/// Herramienta de la pantalla de pintar (lupa o bomba): solo el ícono, en un
/// círculo. Al tocarlo se enciende (brilla) y al tocarlo de nuevo se apaga.
/// Un globito muestra cuántas quedan.
class IconoHerramienta extends StatelessWidget {
  const IconoHerramienta({
    super.key,
    required this.imagen,
    required this.descripcion,
    required this.encendida,
    required this.alTocar,
    this.cantidad,
    this.habilitada = true,
  });

  final String imagen;

  /// Para lectores de pantalla (el ícono no lleva texto).
  final String descripcion;
  final bool encendida;
  final VoidCallback alTocar;

  /// Cuántas quedan (null = no mostrar el globito).
  final int? cantidad;

  /// En el tutorial, las que no corresponden al paso se ven apagadas.
  final bool habilitada;

  static const _lado = 52.0;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    toggled: encendida,
    enabled: habilitada,
    label: cantidad == null ? descripcion : '$descripcion, quedan $cantidad',
    excludeSemantics: true,
    child: Opacity(
      opacity: habilitada ? 1 : 0.35,
      child: GestureDetector(
        onTap: alTocar,
        child: SizedBox(
          width: _lado + 8,
          height: _lado + 4,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _lado,
                height: _lado,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: encendida ? const Color(0xFFFFF4C2) : Tema.aquaSuave,
                  border: Border.all(
                    color: encendida ? const Color(0xFFFFC83D) : Tema.aqua,
                    width: encendida ? 3 : 1.5,
                  ),
                  boxShadow: [
                    if (encendida) ...const [
                      BoxShadow(color: Color(0xCCFFD54F), blurRadius: 18, spreadRadius: 4),
                      BoxShadow(color: Color(0x88FFF59D), blurRadius: 30, spreadRadius: 8),
                    ],
                  ],
                ),
                child: AnimatedScale(
                  scale: encendida ? 1.12 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: Image.asset(imagen, cacheWidth: 144),
                ),
              ),
              if (cantidad case final n?)
                Positioned(
                  right: 0,
                  top: -2,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: n == 0 ? Tema.gris : Tema.lila,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      '$n',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
