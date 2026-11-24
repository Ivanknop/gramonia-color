/// Mapa de biomas. Versión provisoria: cada bioma es una grilla de piezas; las
/// destapadas se ven con el color del bioma. El arte de cada pieza llega en la
/// etapa del mapa.
library;

import 'package:material_ui/material_ui.dart';

import '../../datos/biomas.dart';
import '../../engine/motor.dart';
import '../comun.dart';

class Mapa extends StatelessWidget {
  const Mapa({super.key});

  @override
  Widget build(BuildContext context) {
    final progreso = Dependencias.of(context).progreso;
    return ListenableBuilder(
      listenable: progreso,
      builder: (context, _) {
        final completados = progreso.completados;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [for (final b in biomas) _VistaBioma(estado: estadoBioma(b, completados))],
        );
      },
    );
  }
}

class _VistaBioma extends StatelessWidget {
  const _VistaBioma({required this.estado});
  final EstadoBioma estado;

  @override
  Widget build(BuildContext context) {
    final b = estado.bioma;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${b.nombre}${estado.desbloqueado ? ' ★' : ''}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Tema.morado),
          ),
          const SizedBox(height: 4),
          Text(
            estado.desbloqueado
                ? b.descripcion
                : '${estado.reveladas.length} de ${estado.total} piezas destapadas',
            style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GridView.count(
              crossAxisCount: b.columnas,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              children: [for (var i = 0; i < b.filas * b.columnas; i++) _celda(b, i)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _celda(Bioma b, int i) {
    final fila = i ~/ b.columnas, columna = i % b.columnas;
    final pieza = b.piezas.where((p) => p.fila == fila && p.columna == columna).firstOrNull;
    final revelada = pieza != null && estado.reveladas.contains(pieza.id);
    return ColoredBox(
      color: revelada ? Color(b.color) : const Color(0xFFD9D9D9),
      child: revelada
          ? null
          : const Center(
              child: Text(
                '?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF999999),
                ),
              ),
            ),
    );
  }
}
