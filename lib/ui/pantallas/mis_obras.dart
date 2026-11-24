/// Mis obras: cuadros empezados (para retomarlos) y terminados (colección).
library;

import 'package:material_ui/material_ui.dart';

import '../../datos/textos.dart';
import '../../engine/dificultad.dart';
import '../../engine/motor.dart';
import '../../estado/obras.dart';
import '../comun.dart';
import '../miniatura.dart';
import '../timelapse.dart';
import 'pintar.dart';

class MisObras extends StatelessWidget {
  const MisObras({super.key, required this.onIrAGaleria});

  final VoidCallback onIrAGaleria;

  @override
  Widget build(BuildContext context) {
    final dep = Dependencias.of(context);
    return ListenableBuilder(
      listenable: dep.progreso,
      builder: (context, _) {
        final obras = clasificarObras(dep.progreso.cuadros, dep.catalogo.ids);
        if (obras.enProgreso.isEmpty && obras.terminadas.isEmpty) {
          return _Vacio(onIrAGaleria: onIrAGaleria);
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (obras.enProgreso.isNotEmpty) ...[
              _Seccion('En progreso (${obras.enProgreso.length})'),
              for (final o in obras.enProgreso) _TarjetaObra(obra: o),
            ],
            if (obras.terminadas.isNotEmpty) ...[
              _Seccion('Terminadas (${obras.terminadas.length})'),
              for (final o in obras.terminadas) _TarjetaObra(obra: o),
            ],
          ],
        );
      },
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion(this.titulo);
  final String titulo;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 8),
    child: Text(
      titulo,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Tema.morado),
    ),
  );
}

class _TarjetaObra extends StatelessWidget {
  const _TarjetaObra({required this.obra});
  final Obra obra;

  @override
  Widget build(BuildContext context) {
    final catalogo = Dependencias.of(context).catalogo;
    // Las variantes del modo libre se leen recién al mostrarlas.
    final enMemoria = catalogo.obtener(obra.cuadroId);
    if (enMemoria != null) return _Tarjeta(obra: obra, cuadro: enMemoria);
    return FutureBuilder<Cuadro?>(
      future: catalogo.cuadroDeClave(obra.cuadroId),
      builder: (context, c) =>
          c.data == null ? const SizedBox.shrink() : _Tarjeta(obra: obra, cuadro: c.data!),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.obra, required this.cuadro});
  final Obra obra;
  final Cuadro cuadro;

  @override
  Widget build(BuildContext context) {
    final dificultad = Dependencias.of(context).catalogo
        .dificultad(dificultadDe(obra.cuadroId) ?? '');
    final pintadas = sanearPintadas(cuadro, obra.progreso.pintadas);
    final terminada = obra.progreso.terminado;
    final pct = porcentajeCompletado(cuadro, pintadas);
    final detalle = terminada
        ? 'Terminada el ${fechaCorta(obra.progreso.completadoEn)}'
        : 'Última pincelada: ${fechaCorta(obra.progreso.actualizadoEn)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Semantics(
              button: true,
              label: '${cuadro.meta.titulo}, ${terminada ? 'terminada' : '$pct%'}',
              excludeSemantics: true,
              child: InkWell(
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => Pintar(cuadroId: obra.cuadroId))),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Miniatura(cuadro: cuadro, pintadas: pintadas),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cuadro.meta.titulo,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Tema.morado,
                              ),
                            ),
                            if (dificultad != null)
                              Text(
                                Textos.etiquetaLibre(dificultad.nombre),
                                style: const TextStyle(fontSize: 12, color: Color(0xFF8E7CC3)),
                              ),
                            const SizedBox(height: 4),
                            Text(detalle, style: const TextStyle(fontSize: 13, color: Tema.gris)),
                            if (!terminada) ...[
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: pct / 100,
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(3),
                                color: const Color(0xFF8E7CC3),
                                backgroundColor: const Color(0xFFEEEEEE),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        terminada ? '¡Con color!' : '$pct%',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: terminada ? Tema.verde : const Color(0xFF999999),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (terminada) _Acciones(cuadroId: obra.cuadroId),
          ],
        ),
      ),
    );
  }
}

/// Lo que se puede hacer con una obra terminada.
class _Acciones extends StatelessWidget {
  const _Acciones({required this.cuadroId});
  final String cuadroId;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: Tema.morado),
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => PantallaTimelapse(cuadroId: cuadroId))),
          icon: const Icon(Icons.slow_motion_video, size: 18),
          label: const Text(Textos.verComoLoPinte),
        ),
      ],
    ),
  );
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.onIrAGaleria});
  final VoidCallback onIrAGaleria;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Todavía no hay obras',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Tema.morado),
          ),
          const SizedBox(height: 12),
          const Text(
            'Elegí un cuadro en la Galería y empezá a devolverle sus colores.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Tema.morado),
            onPressed: onIrAGaleria,
            child: const Text('Ir a la Galería'),
          ),
        ],
      ),
    ),
  );
}
