/// Pantalla de pintar: lienzo con zoom/paneo, paleta y avance; panel simple al
/// completar. La animación de devolver el color, el sonido y la vibración
/// llegan en las etapas siguientes.
library;

import 'package:material_ui/material_ui.dart';

import '../../datos/biomas.dart';
import '../../engine/motor.dart';
import '../comun.dart';
import '../lienzo.dart';
import '../paleta.dart';
import 'principal.dart';

class Pintar extends StatefulWidget {
  const Pintar({super.key, required this.cuadroId});
  final String cuadroId;

  @override
  State<Pintar> createState() => _PintarState();
}

class _PintarState extends State<Pintar> {
  Cuadro? _cuadro;
  int? _elegido;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_cuadro == null) {
      _cuadro = Dependencias.of(context).catalogo.obtener(widget.cuadroId);
      _elegido = _cuadro?.paleta.first.numero;
    }
  }

  Set<String> _pintadas(Cuadro c) =>
      sanearPintadas(c, Dependencias.of(context).progreso.de(c.id)?.pintadas ?? const []);

  void _alTocar(Punto p) {
    final cuadro = _cuadro, elegido = _elegido;
    if (cuadro == null || elegido == null) return;
    final pintadas = _pintadas(cuadro);
    final r = intentarPintar(cuadro, pintadas, p, elegido);
    if (r is! Correcto) return; // TODO etapa 2: vibración/sonido suave al errar
    final progreso = Dependencias.of(context).progreso;
    progreso.pintarRegion(cuadro.id, r.regionId);
    if (r.cuadroCompleto) {
      progreso.marcarCompletado(cuadro.id);
    } else if (r.colorCompleto) {
      // Pasar al siguiente color que tenga regiones pendientes.
      final despues = {...pintadas, r.regionId};
      final siguiente = cuadro.paleta
          .where((c) => faltantesDeColor(cuadro, despues, c.numero) > 0)
          .firstOrNull;
      if (siguiente != null) setState(() => _elegido = siguiente.numero);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cuadro = _cuadro;
    if (cuadro == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No encontramos ese cuadro.')),
      );
    }
    final progreso = Dependencias.of(context).progreso;
    return Scaffold(
      appBar: AppBar(title: Text(cuadro.meta.titulo)),
      body: ListenableBuilder(
        listenable: progreso,
        builder: (context, _) {
          final pintadas = _pintadas(cuadro);
          final terminado = progreso.de(cuadro.id)?.terminado ?? false;
          final completos = {
            for (final c in cuadro.paleta)
              if (faltantesDeColor(cuadro, pintadas, c.numero) == 0) c.numero,
          };
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  '${porcentajeCompletado(cuadro, pintadas)}% con color',
                  style: const TextStyle(fontSize: 14, color: Tema.gris),
                ),
              ),
              Expanded(
                child: Lienzo(
                  cuadro: cuadro,
                  pintadas: pintadas,
                  numeroElegido: terminado ? null : _elegido,
                  onToque: _alTocar,
                ),
              ),
              if (terminado)
                _PanelFinal(cuadro: cuadro)
              else
                SafeArea(
                  top: false,
                  child: Paleta(
                    paleta: cuadro.paleta,
                    elegido: _elegido,
                    completos: completos,
                    onElegir: (n) => setState(() => _elegido = n),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PanelFinal extends StatelessWidget {
  const _PanelFinal({required this.cuadro});
  final Cuadro cuadro;

  @override
  Widget build(BuildContext context) {
    final destapa = piezaDeCuadro(biomas, cuadro.id);
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        color: Tema.crema,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              cuadro.meta.mensajeMututu,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Tema.morado),
            ),
            if (destapa != null) ...[
              const SizedBox(height: 8),
              Text(
                'Destapaste una pieza de ${destapa.bioma.nombre}.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Tema.verde,
                ),
              ),
            ],
            const SizedBox(height: 10),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Tema.morado),
              // Vuelve a las pestañas (sobre la portada) mostrando el mapa.
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(
                  builder: (_) => const Principal(pestanaInicial: Principal.mapa),
                ),
                (ruta) => ruta.isFirst,
              ),
              child: const Text('Ver el mapa'),
            ),
          ],
        ),
      ),
    );
  }
}
