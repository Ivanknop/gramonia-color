import 'package:material_ui/material_ui.dart';

import '../../datos/biomas.dart';
import '../../datos/textos.dart';
import '../../engine/motor.dart';
import '../../engine/niveles.dart';
import '../comun.dart';
import 'pintar.dart';

const _blancoYNegro = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 20, //
  0.2126, 0.7152, 0.0722, 0, 20,
  0.2126, 0.7152, 0.0722, 0, 20,
  0, 0, 0, 1, 0,
]);

class Galeria extends StatelessWidget {
  const Galeria({super.key});

  @override
  Widget build(BuildContext context) {
    final dep = Dependencias.of(context);
    return ListenableBuilder(
      listenable: dep.progreso,
      builder: (context, _) {
        final completados = dep.progreso.completados;
        final estados = estadoBiomas(biomas, completados);
        final nivel = nivelActual(biomas, completados, tutorialPasado: dep.progreso.tutorialPasado);
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            _Nivel(nivel),
            const _TituloNivel(nivelTutorial),
            const _SeccionTutorial(),
            for (final (i, e) in estados.indexed) ...[
              if (i == 0 || estados[i - 1].bioma.nivel != e.bioma.nivel)
                _TituloNivel(e.bioma.nivel),
              _SeccionBioma(estado: e),
            ],
          ],
        );
      },
    );
  }
}

class _TituloNivel extends StatelessWidget {
  const _TituloNivel(this.nivel);
  final int nivel;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
    child: Text(
      Textos.tituloNivel(nivel),
      style: const TextStyle(
        fontSize: 13,
        letterSpacing: 1,
        fontWeight: FontWeight.w800,
        color: Tema.gris,
      ),
    ),
  );
}

class _SeccionTutorial extends StatelessWidget {
  const _SeccionTutorial();

  @override
  Widget build(BuildContext context) {
    final progreso = Dependencias.of(context).progreso;
    final terminado = progreso.de(idTutorial)?.terminado ?? false;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const IlustracionCuadro(idTutorial, ancho: 64, alto: 82, cacheWidth: 160),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(Textos.tutorialDetalle, style: TextStyle(color: Tema.morado)),
                if (!progreso.tutorialPremiado)
                  Text(
                    Textos.tutorialPremio(ReglasPlumas.porTutorial),
                    style: const TextStyle(fontSize: 12, color: Tema.marronPluma),
                  ),
                const SizedBox(height: 4),
                OutlinedButton(
                  key: const Key('tutorial'),
                  onPressed: () {
                    if (terminado) progreso.reiniciarTutorial();
                    abrir<void>(context, const Pintar(cuadroId: idTutorial));
                  },
                  child: Text(terminado ? Textos.tutorialVolverAHacer : Textos.tutorialHacer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Nivel extends StatelessWidget {
  const _Nivel(this.estado);
  final EstadoNivel estado;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Tema.morado, borderRadius: BorderRadius.circular(20)),
            child: Text(
              Textos.nivel(estado.nivel),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  estado.hechas >= estado.necesarias
                      ? Textos.nivelCompleto(estado.nivel)
                      : Textos.paraElNivel(estado.hechas, estado.necesarias, estado.nivel + 1),
                  style: const TextStyle(fontSize: 13, color: Tema.gris),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: estado.necesarias == 0 ? 1 : estado.hechas / estado.necesarias,
                  color: Tema.morado,
                  backgroundColor: const Color(0x223D2C5E),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SeccionBioma extends StatelessWidget {
  const _SeccionBioma({required this.estado});
  final EstadoBioma estado;

  @override
  Widget build(BuildContext context) {
    final b = estado.bioma;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  estado.accesible ? Icons.landscape_outlined : Icons.lock_outline,
                  color: estado.accesible ? Color(b.color) : Tema.gris,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    b.nombre,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: estado.accesible ? Tema.morado : Tema.gris,
                    ),
                  ),
                ),
                Text(
                  '${estado.reveladas.length}/${estado.total}',
                  style: const TextStyle(color: Tema.gris, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          if (!estado.accesible)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 2, 16, 0),
              child: Text(
                Textos.bloqueadoPorNivel,
                style: TextStyle(fontSize: 13, color: Tema.gris),
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            height: 214,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: b.piezas.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final p = b.piezas[i];
                final id = p.cuadroId;
                return id == null
                    ? const _Proximamente()
                    : _TarjetaObra(cuadroId: id, habilitada: estado.accesible);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaObra extends StatelessWidget {
  const _TarjetaObra({required this.cuadroId, required this.habilitada});
  final String cuadroId;
  final bool habilitada;

  @override
  Widget build(BuildContext context) {
    final dep = Dependencias.of(context);
    final meta = dep.catalogo.meta(cuadroId);
    if (meta == null) return const SizedBox.shrink();
    final p = dep.progreso.de(cuadroId);
    final total = dep.catalogo.cantidadRegiones[cuadroId] ?? 0;
    final hechas = (p?.pintadas.length ?? 0).clamp(0, total);
    // Terminada alguna vez (una obra rehecha sigue contando como recuperada).
    final terminado = dep.progreso.completados.contains(cuadroId);
    final miniatura = IlustracionCuadro(cuadroId, ancho: 108, alto: 140, cacheWidth: 240);

    return Semantics(
      button: true,
      enabled: habilitada,
      label:
          '${meta.titulo}, $total regiones, ${terminado ? 'terminada' : '${porcentaje(hechas, total)}%'}',
      excludeSemantics: true,
      child: Opacity(
        opacity: habilitada ? 1 : 0.5,
        child: GestureDetector(
          onTap: habilitada ? () => abrir<void>(context, Pintar(cuadroId: cuadroId)) : null,
          child: SizedBox(
            width: 108,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      terminado
                          ? miniatura
                          : ColorFiltered(colorFilter: _blancoYNegro, child: miniatura),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: terminado ? Tema.verde : const Color(0xCC000000),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            terminado ? '✓' : '${porcentaje(hechas, total)}%',
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  meta.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Tema.morado,
                  ),
                ),
                Text('$total regiones', style: const TextStyle(fontSize: 11, color: Tema.gris)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Proximamente extends StatelessWidget {
  const _Proximamente();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 108,
        height: 140,
        decoration: BoxDecoration(
          color: const Color(0xFFEDE7DA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD5CBB6)),
        ),
        child: const Icon(Icons.hourglass_empty, color: Color(0xFFB0A48A)),
      ),
      const SizedBox(height: 4),
      const Text(Textos.proximamente, style: TextStyle(fontSize: 12, color: Tema.gris)),
    ],
  );
}
