/// Lector mínimo del SVG de los cuadros (docs/formato-cuadros.md): solo lee los `<path>`.
library;

import 'geometria.dart';

class PathCrudo {
  const PathCrudo({
    required this.id,
    required this.numero,
    required this.d,
    this.etiqueta,
    this.radio,
  });

  final String id;
  final int numero;
  final String d;
  final Punto? etiqueta;

  /// Espacio libre alrededor de la etiqueta (opcional, lo escribe el conversor).
  /// Con etiqueta y radio, el motor no recalcula nada al cargar.
  final double? radio;
}

class SvgCrudo {
  const SvgCrudo(this.ancho, this.alto, this.paths);
  final double ancho;
  final double alto;
  final List<PathCrudo> paths;
}

final _reAtributo = RegExp(r'([\w:-]+)\s*=\s*"([^"]*)"');
final _reSeparador = RegExp(r'[\s,]+');

Map<String, String> _atributos(String tag) => {
  for (final m in _reAtributo.allMatches(tag)) m.group(1)!: m.group(2)!,
};

SvgCrudo leerSvg(String texto) {
  final svgTag = RegExp(r'<svg\b[^>]*>').firstMatch(texto);
  if (svgTag == null) throw const FormatException('No se encontró la etiqueta <svg>');
  final viewBox = _atributos(svgTag.group(0)!)['viewBox'];
  if (viewBox == null) throw const FormatException('El <svg> necesita un atributo viewBox');
  final vb = viewBox.trim().split(_reSeparador).map(double.parse).toList();

  final paths = <PathCrudo>[];
  final ids = <String>{};
  for (final m in RegExp(r'<path\b[^>]*>').allMatches(texto)) {
    final a = _atributos(m.group(0)!);
    final id = a['id'];
    if (id == null) throw FormatException('Path sin id: ${m.group(0)}');
    if (!ids.add(id)) throw FormatException('Id repetido: "$id"');
    final numero = int.tryParse(a['data-numero'] ?? '');
    if (numero == null || numero < 1) {
      throw FormatException('El path "$id" necesita data-numero entero >= 1');
    }
    final d = a['d'];
    if (d == null) throw FormatException('El path "$id" no tiene atributo d');
    Punto? etiqueta;
    final e = a['data-etiqueta'];
    if (e != null) {
      final xy = e.trim().split(_reSeparador).map(double.parse).toList();
      etiqueta = Punto(xy[0], xy[1]);
    }
    final r = a['data-radio'];
    paths.add(
      PathCrudo(
        id: id,
        numero: numero,
        d: d,
        etiqueta: etiqueta,
        radio: r == null ? null : double.parse(r),
      ),
    );
  }
  return SvgCrudo(vb[2], vb[3], paths);
}
