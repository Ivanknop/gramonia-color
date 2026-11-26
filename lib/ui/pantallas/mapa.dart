import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../../datos/biomas.dart';
import '../../datos/mapa.dart';
import '../../datos/textos.dart';
import '../../engine/motor.dart';
import '../comun.dart';

const assetMapa = 'assets/mapa/gramonia.webp';

class Mapa extends StatelessWidget {
  const Mapa({super.key});

  @override
  Widget build(BuildContext context) {
    final dep = Dependencias.of(context);
    return ListenableBuilder(
      listenable: dep.progreso,
      builder: (context, _) {
        final estados = estadoBiomas(biomas, dep.progreso.completados);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: anchoMapa / altoMapa,
                child: FutureBuilder<ui.Image?>(
                  future: dep.catalogo.imagenAsset(assetMapa),
                  builder: (context, foto) => CustomPaint(
                    painter: PintorMapa(imagen: foto.data, estados: estados),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (final e in estados) _FilaBioma(estado: e),
          ],
        );
      },
    );
  }
}

class PintorMapa extends CustomPainter {
  PintorMapa({required this.imagen, required this.estados});

  final ui.Image? imagen;
  final List<EstadoBioma> estados;

  static const _gris = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 10, //
    0.2126, 0.7152, 0.0722, 0, 10,
    0.2126, 0.7152, 0.0722, 0, 10,
    0, 0, 0, 1, 0,
  ]);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / anchoMapa, size.height / altoMapa);
    final img = imagen;
    final todo = const Rect.fromLTWH(0, 0, anchoMapa, altoMapa);
    final Paint color;
    if (img != null) {
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        todo,
        Paint()
          ..colorFilter = _gris
          ..filterQuality = FilterQuality.medium,
      );
      color = Paint()
        ..shader = ui.ImageShader(
          img,
          TileMode.clamp,
          TileMode.clamp,
          Float64List.fromList([
            anchoMapa / img.width, 0, 0, 0, //
            0, altoMapa / img.height, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1,
          ]),
        );
    } else {
      canvas.drawRect(todo, Paint()..color = const Color(0xFFBDBDBD));
      color = Paint()..color = const Color(0xFF9CCC65);
    }

    for (final e in estados) {
      final zona = zonasMapa[e.bioma.id];
      if (zona == null) continue;
      final path = _pathDe(zona);
      final esIsla = e.bioma.tipo == TipoBioma.isla;
      if (e.completo) {
        // Bioma entero recuperado (las islas, con su propio color).
        canvas.drawPath(path, esIsla ? (Paint()..color = Color(e.bioma.color)) : color);
      } else if (e.reveladas.isNotEmpty) {
        canvas.save();
        canvas.clipPath(path);
        final manchas = manchasDeZona(zona, e.total);
        final radio = radioDeMancha(zona, e.total);
        final pinta = esIsla ? (Paint()..color = Color(e.bioma.color)) : color;
        for (var i = 0; i < e.bioma.piezas.length; i++) {
          if (!e.reveladas.contains(e.bioma.piezas[i].id)) continue;
          canvas.drawCircle(Offset(manchas[i].x, manchas[i].y), radio, pinta);
        }
        canvas.restore();
      }
      if (esIsla && !e.completo) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Color(e.bioma.color).withValues(alpha: 0.6),
        );
      }
      if (e.accesible && !e.completoDisponible) {
        // "Estás acá": el lugar que toca recuperar ahora.
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..color = const Color(0xCCFFB300),
        );
      }
    }
    canvas.restore();
  }

  static ui.Path _pathDe(ZonaMapa zona) => pathDeZona(zona);

  @override
  bool shouldRepaint(PintorMapa old) => old.imagen != imagen || old.estados != estados;
}

class _FilaBioma extends StatelessWidget {
  const _FilaBioma({required this.estado});
  final EstadoBioma estado;

  @override
  Widget build(BuildContext context) {
    final b = estado.bioma;
    final conObra = b.cuadroIds.length;
    final String detalle;
    if (!estado.accesible) {
      detalle = Textos.lugarBloqueado;
    } else if (estado.completo) {
      detalle = b.descripcion;
    } else {
      detalle = Textos.partesRecuperadas(
        estado.reveladas.length,
        estado.total,
        proximamente: estado.total - conObra,
      );
    }
    return Card(
      color: Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: estado.accesible ? Color(b.color) : const Color(0xFFD0D0D0),
          child: Icon(
            estado.completo
                ? Icons.star
                : estado.accesible
                ? Icons.palette_outlined
                : Icons.lock_outline,
            color: Colors.white,
          ),
        ),
        title: Text(
          b.nombre,
          style: const TextStyle(fontWeight: FontWeight.w700, color: Tema.morado),
        ),
        subtitle: Text(detalle),
      ),
    );
  }
}

ui.Path pathDeZona(ZonaMapa zona) {
  final path = ui.Path()..fillType = ui.PathFillType.evenOdd;
  for (final pol in zona.poligonos) {
    path.addPolygon([for (final p in pol) Offset(p.x, p.y)], true);
  }
  return path;
}

/// Lleva las coordenadas de la ilustración del mapa a una caja de [tamano]
/// donde se muestra con `BoxFit.cover` (centrada), como en la portada.
Matrix4 transformacionCover(Size tamano) {
  final escala = math.max(tamano.width / anchoMapa, tamano.height / altoMapa);
  return Matrix4.identity()
    ..translateByDouble(
      (tamano.width - anchoMapa * escala) / 2,
      (tamano.height - altoMapa * escala) / 2,
      0,
      1,
    )
    ..scaleByDouble(escala, escala, 1, 1);
}

/// Portada: el mapa a color, solo en los lugares ya recuperados (las islas,
/// con su propio color, como en el mapa). Va encima del mapa que se apaga:
/// esos lugares no pierden el color.
class MapaRecuperado extends StatelessWidget {
  const MapaRecuperado({super.key, required this.lugares});

  final List<Bioma> lugares;

  @override
  Widget build(BuildContext context) {
    final tierra = [
      for (final b in lugares)
        if (b.tipo != TipoBioma.isla && zonasMapa[b.id] != null) zonasMapa[b.id]!,
    ];
    final islas = [
      for (final b in lugares)
        if (b.tipo == TipoBioma.isla && zonasMapa[b.id] != null) (zonasMapa[b.id]!, b.color),
    ];
    return Stack(
      fit: StackFit.expand,
      children: [
        if (tierra.isNotEmpty)
          ClipPath(
            key: const Key('portada-recuperada'),
            clipper: _RecorteZonas(tierra),
            child: Image.asset(assetMapa, fit: BoxFit.cover),
          ),
        if (islas.isNotEmpty) CustomPaint(painter: _PintorIslas(islas)),
      ],
    );
  }
}

class _RecorteZonas extends CustomClipper<ui.Path> {
  _RecorteZonas(this.zonas);
  final List<ZonaMapa> zonas;

  @override
  ui.Path getClip(Size size) {
    final path = ui.Path();
    for (final z in zonas) {
      path.addPath(pathDeZona(z), Offset.zero);
    }
    return path.transform(transformacionCover(size).storage);
  }

  @override
  bool shouldReclip(_RecorteZonas old) => old.zonas.length != zonas.length;
}

class _PintorIslas extends CustomPainter {
  _PintorIslas(this.islas);
  final List<(ZonaMapa, int)> islas;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.transform(transformacionCover(size).storage);
    for (final (zona, color) in islas) {
      canvas.drawPath(pathDeZona(zona), Paint()..color = Color(color));
    }
  }

  @override
  bool shouldRepaint(_PintorIslas old) => old.islas.length != islas.length;
}
