/// Galería de cuadros con su avance.
library;

import 'package:material_ui/material_ui.dart';

import '../../engine/motor.dart';
import '../comun.dart';
import 'pintar.dart';

class Galeria extends StatelessWidget {
  const Galeria({super.key});

  @override
  Widget build(BuildContext context) {
    final dep = Dependencias.of(context);
    return ListenableBuilder(
      listenable: dep.progreso,
      builder: (context, _) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: dep.catalogo.metas.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final m = dep.catalogo.metas[i];
          final p = dep.progreso.de(m.id);
          final total = dep.catalogo.cantidadRegiones[m.id] ?? 0;
          final hechas = (p?.pintadas.length ?? 0).clamp(0, total);
          final terminado = p?.terminado ?? false;
          return Card(
            color: Colors.white,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              title: Text(
                m.titulo,
                style: const TextStyle(fontWeight: FontWeight.w700, color: Tema.morado),
              ),
              subtitle: Text('${m.categoria.name} · dificultad ${m.dificultad} · $total regiones'),
              trailing: Text(
                terminado ? '¡Con color!' : '${porcentaje(hechas, total)}%',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: terminado ? Tema.verde : const Color(0xFF999999),
                ),
              ),
              onTap: () =>
                  Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => Pintar(cuadroId: m.id))),
            ),
          );
        },
      ),
    );
  }
}
