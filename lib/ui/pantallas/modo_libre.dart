/// Modo libre: pintar dibujos sin la historia de Mututu ni el revelado de
/// lugares. Entran los cuadros de lugares desbloqueados en la historia y los
/// que no son de la historia. Cada uno se pinta en la dificultad que se elija.
library;

import 'package:material_ui/material_ui.dart';

import '../../datos/biomas.dart';
import '../../datos/catalogo.dart';
import '../../datos/textos.dart';
import '../../engine/dificultad.dart';
import '../../engine/motor.dart';
import '../comun.dart';
import '../selector_dificultad.dart';
import 'pintar.dart';

class ModoLibre extends StatelessWidget {
  const ModoLibre({super.key});

  @override
  Widget build(BuildContext context) {
    final dep = Dependencias.of(context);
    final ids = cuadrosLibres(
      biomas,
      dep.progreso.completados,
      dep.catalogo.metas.map((m) => m.id),
    );
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: const Text(Textos.modoLibre)),
      bottomNavigationBar: const BarraPortada(),
      body: ids.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(Textos.libreVacio, textAlign: TextAlign.center),
              ),
            )
          : CustomScrollView(
              slivers: [
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      Textos.libreIntro,
                      style: TextStyle(fontSize: 15, color: Tema.gris),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 180,
                      childAspectRatio: 0.62,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: ids.length,
                    itemBuilder: (context, i) => _Tarjeta(cuadroId: ids[i]),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Elige la dificultad y abre la variante para pintar.
Future<void> pintarLibre(BuildContext context, String cuadroId, {String? actual}) async {
  final catalogo = Dependencias.of(context).catalogo;
  final navegador = Navigator.of(context);
  final d = await elegirDificultad(
    context,
    titulo: Textos.libreElegir,
    actual: actual,
    conPlumas: true,
  );
  if (d == null) return;
  await catalogo.cargarVariante(cuadroId, d.id);
  await navegador.push(
    MaterialPageRoute<void>(builder: (_) => Pintar(cuadroId: idVariante(cuadroId, d.id))),
  );
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.cuadroId});
  final String cuadroId;

  @override
  Widget build(BuildContext context) {
    final catalogo = Dependencias.of(context).catalogo;
    final meta = catalogo.meta(cuadroId)!;
    return Semantics(
      button: true,
      label: meta.titulo,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => pintarLibre(context, cuadroId),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: catalogo.tieneImagen(cuadroId)
                    ? Image.asset(
                        '${Catalogo.carpeta}$cuadroId.webp',
                        fit: BoxFit.cover,
                        cacheWidth: 360,
                        width: double.infinity,
                      )
                    : const ColoredBox(color: Color(0xFFDDDDDD), child: SizedBox.expand()),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              meta.titulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, color: Tema.morado),
            ),
          ],
        ),
      ),
    );
  }
}
