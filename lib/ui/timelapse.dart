/// Timelapse: repite, acelerado, cómo se pintó un cuadro (cada región se
/// expande desde su número, en el orden en que se pintó). Se puede repetir
/// desde el principio o saltear.
library;

import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import '../datos/textos.dart';
import '../engine/motor.dart';
import '../engine/timelapse.dart';
import 'comun.dart';
import 'pintor_cuadro.dart';

class VistaTimelapse extends StatefulWidget {
  const VistaTimelapse({
    super.key,
    required this.cuadro,
    required this.orden,
    this.imagen,
    required this.alTerminar,
  });

  final Cuadro cuadro;

  /// Ids de las regiones en el orden en que se pintaron.
  final List<String> orden;
  final ui.Image? imagen;

  /// Al terminar la repetición o al saltearla.
  final VoidCallback alTerminar;

  @override
  State<VistaTimelapse> createState() => _VistaTimelapseState();
}

class _VistaTimelapseState extends State<VistaTimelapse> with SingleTickerProviderStateMixin {
  final _reloj = ValueNotifier<Duration>(Duration.zero);
  late final Ticker _ticker = createTicker(_alTic);
  late final List<String> _orden = sanearPintadas(widget.cuadro, widget.orden).toList();
  late final Map<String, RellenoAnimado> _animaciones = _programar();
  bool _terminado = false;

  Map<String, RellenoAnimado> _programar() {
    final n = _orden.length;
    final etiquetas = {for (final r in widget.cuadro.regiones) r.id: r.etiqueta};
    return {
      for (final (i, id) in _orden.indexed)
        id: RellenoAnimado(
          origen: etiquetas[id]!,
          inicio: Timelapse.inicio(i, n),
          duracion: Timelapse.relleno(n),
        ),
    };
  }

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  void _alTic(Duration transcurrido) {
    _reloj.value = transcurrido;
    if (transcurrido >= Timelapse.duracion(_orden.length)) _terminar();
  }

  /// Vuelve a empezar la repetición desde el cuadro en blanco.
  void _repetir() {
    if (_terminado) return;
    _ticker.stop();
    _reloj.value = Duration.zero;
    _ticker.start();
  }

  void _terminar() {
    if (_terminado) return;
    _terminado = true;
    _ticker.stop();
    widget.alTerminar();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _reloj.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cuadro = widget.cuadro;
    return ColoredBox(
      color: Tema.fondoLienzo,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              Textos.timelapse,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Tema.morado),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (context, caja) {
                  final factor = [
                    caja.maxWidth / cuadro.ancho,
                    caja.maxHeight / cuadro.alto,
                  ].reduce((a, b) => a < b ? a : b);
                  return Center(
                    child: CustomPaint(
                      key: const Key('timelapse'),
                      size: Size(cuadro.ancho * factor, cuadro.alto * factor),
                      painter: PintorCuadro(
                        cuadro: cuadro,
                        pintadas: _orden.toSet(),
                        factor: factor,
                        imagen: widget.imagen,
                        mostrarNumeros: false,
                        animaciones: _animaciones,
                        reloj: _reloj,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  key: const Key('repetir'),
                  onPressed: _repetir,
                  icon: const IconoEspiral(),
                  label: const Text(Textos.repetir),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  key: const Key('saltear'),
                  onPressed: _terminar,
                  icon: const Icon(Icons.skip_next),
                  label: const Text(Textos.saltear),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// El timelapse en una pantalla propia (desde "Mis obras" o el panel final).
class PantallaTimelapse extends StatelessWidget {
  const PantallaTimelapse({super.key, required this.cuadroId});
  final String cuadroId;

  @override
  Widget build(BuildContext context) {
    final dep = Dependencias.of(context);
    final progreso = dep.progreso.de(cuadroId);
    final cuadro = dep.catalogo.obtenerDeObra(cuadroId, dificultad: progreso?.dificultad);
    final orden = progreso?.pintadas ?? const [];
    return Scaffold(
      appBar: AppBar(title: Text(cuadro?.meta.titulo ?? '')),
      body: cuadro == null
          ? const SizedBox.shrink()
          : FutureBuilder<ui.Image?>(
              future: dep.catalogo.imagen(cuadroId),
              builder: (context, imagen) => imagen.connectionState != ConnectionState.done
                  ? const Center(child: CircularProgressIndicator())
                  : VistaTimelapse(
                      cuadro: cuadro,
                      orden: orden,
                      imagen: imagen.data,
                      // Al terminar (o saltear), vuelve a donde estaba.
                      alTerminar: () => Navigator.of(context).maybePop(),
                    ),
            ),
    );
  }
}
