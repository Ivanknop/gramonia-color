/// Pantalla de pintar: lienzo grande con zoom, paleta, lupa y bomba.
///
/// - Arranca con el color 1 elegido.
/// - Lupa: lleva la vista a la próxima región pendiente del color elegido
///   (cada toque, la siguiente).
/// - Bomba: se arma con el botón y el próximo toque pinta todas las regiones
///   cercanas, cada una con su color correcto.
/// - Al terminar: festejo (confeti, sonido y vibración), plumas por la obra y,
///   si se completa un bioma, plumas extra y el capítulo de la historia que
///   cuenta Gobi (después del festejo y del timelapse, que se puede saltear).
/// - Música: un tema al azar en cada dibujo, con botones para cambiarla y
///   silenciarla; se pausa si la app pasa a segundo plano.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../datos/biomas.dart';
import '../../datos/historia.dart';
import '../../datos/textos.dart';
import '../../engine/motor.dart';
import '../../estado/musica.dart';
import '../comun.dart';
import '../festejo.dart';
import '../timelapse.dart';
import '../lienzo.dart';
import '../paleta.dart';
import 'historia.dart';
import 'principal.dart';

/// Radio de la bomba, como fracción del lado mayor del cuadro.
const fraccionRadioBomba = 0.1;

class Pintar extends StatefulWidget {
  const Pintar({super.key, required this.cuadroId});
  final String cuadroId;

  @override
  State<Pintar> createState() => _PintarState();
}

class _PintarState extends State<Pintar> with WidgetsBindingObserver {
  final _lienzo = GlobalKey<LienzoState>();
  Cuadro? _cuadro;
  ui.Image? _imagen;
  bool _cargandoImagen = true;
  int? _elegido;
  bool _bombaArmada = false;
  String? _destacada;
  int _indiceLupa = 0;
  Timer? _apagarDestacada;

  /// Plumas ganadas al terminar (para el panel final).
  int _plumasGanadas = 0;

  /// Confeti en pantalla (al terminar el cuadro).
  bool _festejando = false;

  /// Repetición acelerada de cómo se pintó (después del festejo).
  bool _repitiendo = false;

  /// Capítulos de la historia que se cuentan después del festejo y el timelapse.
  final List<Bioma> _capitulosPendientes = [];
  Musica? _musica;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_cuadro != null) return;
    final catalogo = Dependencias.of(context).catalogo;
    _musica = Dependencias.of(context).musica;
    unawaited(_musica?.empezar());
    WidgetsBinding.instance.addObserver(this);
    _cuadro = catalogo.obtener(widget.cuadroId);
    _elegido = _cuadro?.paleta.first.numero;
    catalogo.imagen(widget.cuadroId).then((img) {
      if (mounted) {
        setState(() {
          _imagen = img;
          _cargandoImagen = false;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_musica?.detener());
    _apagarDestacada?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    switch (estado) {
      case AppLifecycleState.paused || AppLifecycleState.hidden:
        unawaited(_musica?.pausarPorSegundoPlano());
      case AppLifecycleState.resumed:
        unawaited(_musica?.reanudarDesdeSegundoPlano());
      default:
        break;
    }
  }

  Set<String> _pintadas(Cuadro c) =>
      sanearPintadas(c, Dependencias.of(context).progreso.de(c.id)?.pintadas ?? const []);

  void _avisar(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto), duration: const Duration(seconds: 2)));
  }

  void _alTocar(Punto p, double tolerancia) {
    final cuadro = _cuadro, elegido = _elegido;
    if (cuadro == null) return;
    final pintadas = _pintadas(cuadro);
    if (_bombaArmada) {
      _tirarBomba(cuadro, pintadas, p);
      return;
    }
    if (elegido == null) return;
    final r = intentarPintar(cuadro, pintadas, p, elegido, tolerancia: tolerancia);
    switch (r) {
      case Correcto():
        HapticFeedback.selectionClick();
        _registrar(cuadro, pintadas, [r.regionId]);
      case Incorrecto():
        HapticFeedback.lightImpact();
      case YaPintada() || Fuera():
        break;
    }
  }

  void _tirarBomba(Cuadro cuadro, Set<String> pintadas, Punto p) {
    final progreso = Dependencias.of(context).progreso;
    final radio = fraccionRadioBomba * math.max(cuadro.ancho, cuadro.alto);
    final alcanzadas = regionesDeBomba(cuadro, pintadas, p, radio);
    setState(() => _bombaArmada = false);
    if (alcanzadas.isEmpty) return;
    if (!progreso.gastarPlumas(ReglasPlumas.costoBomba)) {
      _avisar('Te faltan plumas para la bomba.');
      return;
    }
    HapticFeedback.heavyImpact();
    _registrar(cuadro, pintadas, [for (final r in alcanzadas) r.id]);
  }

  /// Guarda lo pintado y resuelve el avance de color, obra y bioma.
  void _registrar(Cuadro cuadro, Set<String> antes, List<String> nuevas) {
    final progreso = Dependencias.of(context).progreso;
    final completadosAntes = progreso.completados;
    progreso.pintarRegiones(cuadro.id, nuevas);
    final despues = {...antes, ...nuevas};

    if (estaCompleto(cuadro, despues)) {
      if (!progreso.marcarCompletado(cuadro.id)) return;
      var ganadas = ReglasPlumas.porObra;
      final completos = biomasQueSeCompletan(biomas, completadosAntes, cuadro.id);
      ganadas += ReglasPlumas.porBioma * completos.length;
      progreso.sumarPlumas(ganadas);
      _festejar();
      setState(() => _plumasGanadas = ganadas);
      _capitulosPendientes.addAll(completos);
      return;
    }
    // Si se terminó el color elegido, pasar al siguiente que tenga pendientes.
    final elegido = _elegido;
    if (elegido != null && faltantesDeColor(cuadro, despues, elegido) == 0) {
      final siguiente = cuadro.paleta
          .where((c) => faltantesDeColor(cuadro, despues, c.numero) > 0)
          .firstOrNull;
      if (siguiente != null) setState(() => _elegido = siguiente.numero);
    }
  }

  /// Confeti, sonido y vibración: tres golpes que se van suavizando.
  void _festejar() {
    setState(() => _festejando = true);
    unawaited(_musica?.festejar());
    HapticFeedback.heavyImpact();
    Future<void>.delayed(const Duration(milliseconds: 180), HapticFeedback.mediumImpact);
    Future<void>.delayed(const Duration(milliseconds: 360), HapticFeedback.lightImpact);
  }

  void _alTerminarFestejo() {
    if (!mounted) return;
    setState(() {
      _festejando = false;
      _repitiendo = true;
    });
  }

  void _alTerminarTimelapse() {
    if (!mounted) return;
    setState(() => _repitiendo = false);
    for (final b in _capitulosPendientes) {
      _contarCapitulo(b);
    }
    _capitulosPendientes.clear();
  }

  void _contarCapitulo(Bioma bioma) {
    final escena = capitulos[bioma.id];
    final progreso = Dependencias.of(context).progreso;
    if (escena == null || progreso.capitulosVistos.contains(bioma.id)) return;
    progreso.marcarCapituloVisto(bioma.id);
    final escenas = [escena, if (bioma.id == 'isla-morada') ...finalIslas];
    // Después del festejo, Gobi cuenta el capítulo.
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaHistoria(escenas: escenas, textoFinal: 'Seguir'),
      ),
    );
  }

  void _usarLupa(Cuadro cuadro) {
    final progreso = Dependencias.of(context).progreso;
    final lista = pendientesParaLupa(cuadro, _pintadas(cuadro), _elegido);
    if (lista.isEmpty) return;
    if (!progreso.gastarPlumas(ReglasPlumas.costoLupa)) {
      _avisar('Te faltan plumas para la lupa.');
      return;
    }
    final region = lista[_indiceLupa % lista.length];
    _indiceLupa++;
    _lienzo.currentState?.enfocar(region);
    setState(() => _destacada = region.id);
    _apagarDestacada?.cancel();
    _apagarDestacada = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _destacada = null);
    });
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
    return ListenableBuilder(
      listenable: progreso,
      builder: (context, _) {
        final pintadas = _pintadas(cuadro);
        final terminado = progreso.de(cuadro.id)?.terminado ?? false;
        final completos = {
          for (final c in cuadro.paleta)
            if (faltantesDeColor(cuadro, pintadas, c.numero) == 0) c.numero,
        };
        final pct = porcentajeCompletado(cuadro, pintadas);
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 48,
            title: Text(
              cuadro.meta.titulo,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18),
            ),
            actions: [
              if (_musica case final musica?) _BotonesMusica(musica: musica),
              const ContadorPlumas(),
              const SizedBox(width: 12),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    if (_cargandoImagen)
                      const Center(child: CircularProgressIndicator())
                    else
                      Lienzo(
                        key: _lienzo,
                        cuadro: cuadro,
                        imagen: _imagen,
                        pintadas: pintadas,
                        numeroElegido: terminado || _bombaArmada ? null : _elegido,
                        regionDestacada: _destacada,
                        onToque: _alTocar,
                      ),
                    if (_repitiendo)
                      Positioned.fill(
                        child: VistaTimelapse(
                          cuadro: cuadro,
                          orden: progreso.de(cuadro.id)?.pintadas ?? const [],
                          imagen: _imagen,
                          alTerminar: _alTerminarTimelapse,
                        ),
                      ),
                    if (_festejando)
                      Positioned.fill(child: Festejo(alTerminar: _alTerminarFestejo)),
                    if (_bombaArmada)
                      const Positioned(
                        left: 12,
                        right: 12,
                        top: 8,
                        child: _Aviso('Tocá el cuadro donde quieras tirar la bomba de color'),
                      ),
                  ],
                ),
              ),
              if (terminado)
                _PanelFinal(cuadro: cuadro, plumasGanadas: _plumasGanadas)
              else
                SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _BarraHerramientas(
                        porcentaje: pct,
                        bombaArmada: _bombaArmada,
                        alUsarLupa: () => _usarLupa(cuadro),
                        alArmarBomba: () => setState(() => _bombaArmada = !_bombaArmada),
                      ),
                      Paleta(
                        paleta: cuadro.paleta,
                        elegido: _elegido,
                        completos: completos,
                        onElegir: (n) => setState(() {
                          _elegido = n;
                          _bombaArmada = false;
                          _indiceLupa = 0;
                        }),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// "Cambiar música" y "Silenciar" / "Activar sonido".
class _BotonesMusica extends StatelessWidget {
  const _BotonesMusica({required this.musica});
  final Musica musica;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: musica,
    builder: (context, _) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: const Key('cambiar-musica'),
          tooltip: 'Cambiar música',
          icon: const Icon(Icons.queue_music),
          onPressed: () {
            unawaited(musica.cambiar());
            final tema = musica.actual;
            if (tema != null && !musica.silenciada) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text('Sonando: ${nombreDeTema(tema)}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
            }
          },
        ),
        IconButton(
          key: const Key('silenciar'),
          tooltip: musica.silenciada ? 'Activar sonido' : 'Silenciar',
          icon: Icon(musica.silenciada ? Icons.volume_off : Icons.volume_up),
          onPressed: () => unawaited(musica.alternarSilencio()),
        ),
      ],
    ),
  );
}

class _Aviso extends StatelessWidget {
  const _Aviso(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xEE3D2C5E),
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white),
      ),
    ),
  );
}

class _BarraHerramientas extends StatelessWidget {
  const _BarraHerramientas({
    required this.porcentaje,
    required this.bombaArmada,
    required this.alUsarLupa,
    required this.alArmarBomba,
  });

  final int porcentaje;
  final bool bombaArmada;
  final VoidCallback alUsarLupa;
  final VoidCallback alArmarBomba;

  /// Mientras las herramientas sean gratis no se muestra el costo.
  int? _costo(int plumas) => ReglasPlumas.herramientasGratis ? null : plumas;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
    child: Row(
      children: [
        _Herramienta(
          clave: const Key('lupa'),
          icono: Icons.search,
          texto: 'Lupa',
          costo: _costo(ReglasPlumas.costoLupa),
          alTocar: alUsarLupa,
        ),
        const SizedBox(width: 8),
        _Herramienta(
          clave: const Key('bomba'),
          icono: Icons.auto_awesome,
          texto: bombaArmada ? 'Cancelar' : 'Bomba',
          costo: _costo(ReglasPlumas.costoBomba),
          activa: bombaArmada,
          alTocar: alArmarBomba,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$porcentaje% con color',
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Tema.gris, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _Herramienta extends StatelessWidget {
  const _Herramienta({
    required this.clave,
    required this.icono,
    required this.texto,
    required this.costo,
    required this.alTocar,
    this.activa = false,
  });

  final Key clave;
  final IconData icono;
  final String texto;
  final int? costo;
  final VoidCallback alTocar;
  final bool activa;

  @override
  Widget build(BuildContext context) => FilledButton.tonalIcon(
    key: clave,
    style: FilledButton.styleFrom(
      backgroundColor: activa ? const Color(0xFFE8A33D) : null,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      visualDensity: VisualDensity.compact,
    ),
    onPressed: alTocar,
    icon: Icon(icono, size: 18),
    label: costo == null
        ? Text(texto)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(texto),
              const SizedBox(width: 6),
              const IconoPluma(tamano: 12),
              Text(' $costo', style: const TextStyle(fontSize: 11)),
            ],
          ),
  );
}

class _PanelFinal extends StatelessWidget {
  const _PanelFinal({required this.cuadro, required this.plumasGanadas});
  final Cuadro cuadro;
  final int plumasGanadas;

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
                'Destapaste una parte de ${destapa.bioma.nombre}.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Tema.verde,
                ),
              ),
            ],
            if (plumasGanadas > 0) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const IconoPluma(tamano: 18),
                  Flexible(
                    child: Text(
                      ' +$plumasGanadas plumas del Rocanón',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF8A5A1E)),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: Tema.morado),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => PantallaTimelapse(cuadroId: cuadro.id)),
                  ),
                  child: const Text(Textos.verComoLoPinte),
                ),
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
          ],
        ),
      ),
    );
  }
}
