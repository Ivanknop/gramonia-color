/// En el tutorial, los pasos son obligatorios y en orden: lo que no corresponde al paso no
/// responde, y la lupa y la bomba no se gastan.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../datos/biomas.dart';
import '../../datos/historia.dart';
import '../../datos/textos.dart';
import '../../engine/dificultad.dart';
import '../../engine/motor.dart';
import '../../engine/niveles.dart';
import '../../estado/musica.dart';
import '../comun.dart';
import '../festejo.dart';
import '../timelapse.dart';
import '../lienzo.dart';
import '../paleta.dart';
import 'historia.dart';
import 'principal.dart';
import 'tienda.dart';

/// Radio de la bomba, como fracción del lado mayor del cuadro.
const fraccionRadioBomba = 0.1;

class Pintar extends StatefulWidget {
  const Pintar({super.key, required this.cuadroId});

  /// Clave del progreso: el id de un cuadro de la historia o el de una
  /// variante de dificultad (`<cuadro>--<dificultad>`, modo libre).
  final String cuadroId;

  @override
  State<Pintar> createState() => _PintarState();
}

class _PintarState extends State<Pintar> with WidgetsBindingObserver {
  final _lienzo = GlobalKey<LienzoState>();
  Cuadro? _cuadro;
  ui.Image? _imagen;
  bool _cargandoImagen = true;
  bool _cargandoCuadro = false;
  String get _clave => widget.cuadroId;

  /// Modo libre: sin historia, piezas, plumas ni capítulos.
  bool get _libre => dificultadDe(_clave) != null;

  bool get _tutorial => _clave == idTutorial;

  Set<PasoTutorial> _pasos = {};
  int? _elegido;
  bool _bombaArmada = false;
  bool _lupaArmada = false;
  String? _destacada;
  int _indiceLupa = 0;
  Timer? _apagarDestacada;

  int _plumasGanadas = 0;
  int? _nivelNuevo;
  bool _destapo = false;

  /// Mensaje del panel final (historia): uno al azar, elegido una sola vez.
  String? _mensajeObra;

  String _mensajeDeObra() {
    final lugar = piezaDeCuadro(biomas, _clave)?.bioma;
    if (lugar == null) return '';
    return _mensajeObra ??= mensajeDeObra(
      lugar,
      Dependencias.of(context).progreso.completados,
      Textos.mensajesObra,
      math.Random(),
    );
  }

  bool _festejando = false;
  bool _repitiendo = false;

  /// Se cuentan después del festejo y el timelapse.
  final List<(String, List<Escena>)> _capitulosPendientes = [];

  void _sumarCapitulos(List<int> niveles) {
    for (final n in niveles) {
      if (capitulosDeNivel[n] case final escenas?) {
        _capitulosPendientes.add((idCapituloDeNivel(n), escenas));
      }
    }
  }

  Musica? _musica;

  bool _iniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    final catalogo = Dependencias.of(context).catalogo;
    _musica = Dependencias.of(context).musica;
    unawaited(_musica?.empezar());
    WidgetsBinding.instance.addObserver(this);
    // Obra rehecha: se pinta la variante de su dificultad.
    final rehecha = Dependencias.of(context).progreso.de(_clave)?.dificultad;
    _cuadro = catalogo.obtenerDeObra(_clave, dificultad: rehecha);
    // En el tutorial, elegir el color es el primer paso.
    _elegido = _tutorial ? null : _cuadro?.paleta.first.numero;
    if (_cuadro == null && (rehecha != null || _libre)) {
      _cargandoCuadro = true;
      catalogo.cuadroDeObra(_clave, dificultad: rehecha).then((c) {
        if (!mounted) return;
        setState(() {
          _cuadro = c;
          _elegido = c?.paleta.first.numero;
          _cargandoCuadro = false;
        });
      });
    }
    catalogo.imagen(_clave).then((img) {
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
      sanearPintadas(c, Dependencias.of(context).progreso.de(_clave)?.pintadas ?? const []);

  bool _permitido(AccionPintar accion) => !_tutorial || accionPermitida(pasoActual(_pasos), accion);

  void _alTocar(Punto p, double tolerancia) {
    final cuadro = _cuadro, elegido = _elegido;
    if (cuadro == null) return;
    final pintadas = _pintadas(cuadro);
    if (_bombaArmada) {
      _tirarBomba(cuadro, pintadas, p);
      return;
    }
    if (elegido == null || _lupaArmada || !_permitido(AccionPintar.pintar)) return;
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
    if (!_tutorial && !progreso.usar(Herramienta.bomba)) {
      avisar(context, Textos.sinBombas);
      return;
    }
    HapticFeedback.heavyImpact();
    _marcarPaso(PasoTutorial.bomba);
    _registrar(cuadro, pintadas, [for (final r in alcanzadas) r.id]);
  }

  /// Guarda lo pintado y resuelve el avance de color, obra y bioma.
  void _registrar(Cuadro cuadro, Set<String> antes, List<String> nuevas) {
    final progreso = Dependencias.of(context).progreso;
    final completadosAntes = progreso.completados;
    progreso.pintarRegiones(_clave, nuevas);
    final despues = {...antes, ...nuevas};

    // Algún color quedó completo con esta pintada (también con la bomba).
    if (cuadro.paleta.any(
      (c) =>
          faltantesDeColor(cuadro, antes, c.numero) > 0 &&
          faltantesDeColor(cuadro, despues, c.numero) == 0,
    )) {
      _marcarPaso(PasoTutorial.completarColor);
    }

    if (estaCompleto(cuadro, despues)) {
      if (!progreso.marcarCompletado(_clave)) return;
      _festejar();
      if (_tutorial) {
        final yaPasado = progreso.tutorialPasado;
        final ganadas = progreso.terminarTutorial();
        setState(() {
          _plumasGanadas = ganadas;
          _nivelNuevo = yaPasado ? null : 1;
        });
        // La primera vez, Gobi cuenta que empieza la historia.
        if (!yaPasado) _sumarCapitulos(const [nivelTutorial]);
        return;
      }
      // Plumas en cualquier modo; los niveles, solo con obras nuevas de la historia.
      final subidos = nivelesSubidos(biomas, completadosAntes, progreso.completados);
      final libre = Dependencias.of(context).catalogo.dificultadDeObra(_clave);
      final ganadas = libre?.plumas ?? plumasPorTerminar(nivelesSubidos: subidos);
      progreso.sumarPlumas(ganadas);
      // Modo libre u obra rehecha (ya desbloqueada): sin pieza ni capítulo.
      final nueva = !_libre && !completadosAntes.contains(_clave);
      setState(() {
        _plumasGanadas = ganadas;
        _nivelNuevo = subidos > 0
            ? nivelActual(biomas, progreso.completados, tutorialPasado: true).nivel
            : null;
        _destapo = nueva;
      });
      if (nueva) {
        _sumarCapitulos(nivelesQueSeCompletan(biomas, completadosAntes, progreso.completados));
      }
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
    // Gobi cuenta, de una, los capítulos que todavía no se contaron.
    final progreso = Dependencias.of(context).progreso;
    final escenas = <Escena>[
      for (final (id, deCapitulo) in _capitulosPendientes)
        if (!progreso.capitulosVistos.contains(id)) ...deCapitulo,
    ];
    for (final (id, _) in _capitulosPendientes) {
      progreso.marcarCapituloVisto(id);
    }
    _capitulosPendientes.clear();
    if (escenas.isEmpty) return;
    abrir<void>(context, PantallaHistoria(escenas: escenas, textoFinal: Textos.seguir));
  }

  void _marcarPaso(PasoTutorial paso) {
    if (_tutorial) setState(() => _pasos = cumplirPaso(_pasos, paso));
  }

  /// "Saltar" el tutorial: la primera vez sigue a la galería (nivel 1, con el
  /// premio pendiente); si ya se había pasado, solo vuelve.
  void _saltarTutorial() {
    final progreso = Dependencias.of(context).progreso;
    if (progreso.tutorialPasado) {
      Navigator.of(context).maybePop();
      return;
    }
    progreso.saltarTutorial();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const Principal(pestanaInicial: Principal.galeria)),
    );
  }

  String _textoDelPaso(PasoTutorial paso) => switch (paso) {
    PasoTutorial.elegirColor => Textos.tutorialElegirColor,
    PasoTutorial.completarColor => Textos.tutorialCompletarColor,
    PasoTutorial.lupa => Textos.tutorialLupa,
    PasoTutorial.bomba => Textos.tutorialBomba,
    PasoTutorial.terminar => Textos.tutorialTerminar,
  };

  /// La enciende (si quedan) o la apaga. Solo una puede estar encendida.
  void _alternar(Herramienta h) {
    final esLupa = h == Herramienta.lupa;
    if (!_permitido(esLupa ? AccionPintar.lupa : AccionPintar.bomba)) return;
    final encendida = esLupa ? _lupaArmada : _bombaArmada;
    if (!encendida && !_tutorial && Dependencias.of(context).progreso.cantidad(h) == 0) {
      avisar(context, esLupa ? Textos.sinLupas : Textos.sinBombas);
      return;
    }
    setState(() {
      _lupaArmada = esLupa && !encendida;
      _bombaArmada = !esLupa && !encendida;
    });
  }

  /// Tocar un color de la paleta (con la lupa encendida, además, la usa).
  void _alElegirColor(Cuadro cuadro, int numero) {
    if (!_permitido(AccionPintar.elegirColor)) return;
    if (_lupaArmada) {
      // La lupa solo sirve con colores que todavía tienen partes sin pintar.
      if (faltantesDeColor(cuadro, _pintadas(cuadro), numero) == 0) {
        avisar(context, Textos.lupaColorCompleto);
        return;
      }
      setState(() {
        _elegido = numero;
        _indiceLupa = 0;
      });
      _usarLupa(cuadro);
      return;
    }
    _marcarPaso(PasoTutorial.elegirColor);
    setState(() {
      _elegido = numero;
      _bombaArmada = false;
      _indiceLupa = 0;
    });
  }

  void _usarLupa(Cuadro cuadro) {
    final progreso = Dependencias.of(context).progreso;
    final lista = pendientesParaLupa(cuadro, _pintadas(cuadro), _elegido);
    if (lista.isEmpty) return;
    if (!_tutorial && !progreso.usar(Herramienta.lupa)) {
      setState(() => _lupaArmada = false);
      avisar(context, Textos.sinLupas);
      return;
    }
    setState(() => _lupaArmada = false);
    _marcarPaso(PasoTutorial.lupa);
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
    if (_cargandoCuadro) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (cuadro == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text(Textos.cuadroNoEncontrado)),
      );
    }
    final progreso = Dependencias.of(context).progreso;
    return ListenableBuilder(
      listenable: progreso,
      builder: (context, _) {
        final pintadas = _pintadas(cuadro);
        final obra = progreso.de(_clave);
        final terminado = obra?.terminado ?? false;
        final dificultad = Dependencias.of(context).catalogo
            .dificultadDeObra(_clave, rehecha: obra?.dificultad);
        final completos = {
          for (final c in cuadro.paleta)
            if (faltantesDeColor(cuadro, pintadas, c.numero) == 0) c.numero,
        };
        final pct = porcentajeCompletado(cuadro, pintadas);
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 48,
            title: Text(
              dificultad == null
                  ? cuadro.meta.titulo
                  : '${cuadro.meta.titulo} · ${dificultad.nombre}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18),
            ),
            actions: [
              if (_tutorial && !terminado)
                TextButton(
                  key: const Key('saltar-tutorial'),
                  onPressed: _saltarTutorial,
                  child: const Text(Textos.tutorialSaltar),
                ),
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
                          orden: progreso.de(_clave)?.pintadas ?? const [],
                          imagen: _imagen,
                          alTerminar: _alTerminarTimelapse,
                        ),
                      ),
                    if (_festejando)
                      Positioned.fill(child: Festejo(alTerminar: _alTerminarFestejo)),
                    if (_bombaArmada || _lupaArmada)
                      Positioned(
                        left: 12,
                        right: 12,
                        top: 8,
                        child: _Aviso(_bombaArmada ? Textos.bombaArmada : Textos.lupaArmada),
                      )
                    else if (_tutorial && !terminado && !_festejando)
                      Positioned(
                        left: 12,
                        right: 12,
                        top: 8,
                        child: _Aviso(_textoDelPaso(pasoActual(_pasos))),
                      ),
                  ],
                ),
              ),
              if (terminado)
                _PanelFinal(
                  mensaje: _tutorial || _libre ? '' : _mensajeDeObra(),
                  clave: _clave,
                  libre: _libre,
                  tutorial: _tutorial,
                  destapo: _destapo,
                  nivelNuevo: _nivelNuevo,
                  plumasGanadas: _plumasGanadas,
                )
              else
                SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _BarraHerramientas(
                        porcentaje: pct,
                        lupaArmada: _lupaArmada,
                        bombaArmada: _bombaArmada,
                        // En el tutorial son gratis: no se muestra cuántas quedan.
                        lupas: _tutorial ? null : progreso.cantidad(Herramienta.lupa),
                        bombas: _tutorial ? null : progreso.cantidad(Herramienta.bomba),
                        lupaHabilitada: _permitido(AccionPintar.lupa),
                        bombaHabilitada: _permitido(AccionPintar.bomba),
                        alTocar: _alternar,
                      ),
                      Opacity(
                        opacity: _permitido(AccionPintar.elegirColor) ? 1 : 0.4,
                        child: Paleta(
                          paleta: cuadro.paleta,
                          elegido: _elegido,
                          completos: completos,
                          onElegir: (n) => _alElegirColor(cuadro, n),
                        ),
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
          tooltip: Textos.cambiarMusica,
          icon: const Icon(Icons.queue_music),
          onPressed: () {
            unawaited(musica.cambiar());
            final tema = musica.actual;
            if (tema != null && !musica.silenciada) {
              avisar(context, Textos.sonando(nombreDeTema(tema)));
            }
          },
        ),
        IconButton(
          key: const Key('silenciar'),
          tooltip: musica.silenciada ? Textos.activarSonido : Textos.silenciar,
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
  Widget build(BuildContext context) => IgnorePointer(
    child: Material(
      color: Tema.fondoAviso,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    ),
  );
}

class _BarraHerramientas extends StatelessWidget {
  const _BarraHerramientas({
    required this.porcentaje,
    required this.lupaArmada,
    required this.bombaArmada,
    required this.lupas,
    required this.bombas,
    required this.lupaHabilitada,
    required this.bombaHabilitada,
    required this.alTocar,
  });

  final int porcentaje;
  final bool lupaArmada, bombaArmada;

  /// Cuántas quedan de cada una (se compran en la tienda; null = no mostrar).
  final int? lupas, bombas;

  /// En el tutorial, solo se puede tocar la del paso actual.
  final bool lupaHabilitada, bombaHabilitada;
  final ValueChanged<Herramienta> alTocar;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
    child: Row(
      children: [
        IconoHerramienta(
          key: const Key('lupa'),
          herramienta: Herramienta.lupa,
          cantidad: lupas,
          encendida: lupaArmada,
          habilitada: lupaHabilitada,
          alTocar: () => alTocar(Herramienta.lupa),
        ),
        const SizedBox(width: 14),
        IconoHerramienta(
          key: const Key('bomba'),
          herramienta: Herramienta.bomba,
          cantidad: bombas,
          encendida: bombaArmada,
          habilitada: bombaHabilitada,
          alTocar: () => alTocar(Herramienta.bomba),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            Textos.conColor(porcentaje),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Tema.gris, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _PanelFinal extends StatelessWidget {
  const _PanelFinal({
    required this.mensaje,
    required this.clave,
    required this.libre,
    required this.tutorial,
    required this.destapo,
    required this.nivelNuevo,
    required this.plumasGanadas,
  });

  final String mensaje;
  final String clave;
  final bool libre;
  final bool tutorial;

  /// Esta vez se destapó una pieza (no al reabrir una terminada ni al rehacer).
  final bool destapo;
  final int? nivelNuevo;
  final int plumasGanadas;

  @override
  Widget build(BuildContext context) {
    final destapa = destapo ? piezaDeCuadro(biomas, clave) : null;
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
              tutorial
                  ? (nivelNuevo == null ? Textos.tutorialRepaso : Textos.tutorialListo)
                  : libre
                  ? Textos.libreTerminado
                  : mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Tema.morado),
            ),
            if (destapa != null) ...[
              const SizedBox(height: 8),
              Text(
                Textos.destapaste(destapa.bioma.conArticulo),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Tema.verde,
                ),
              ),
            ],
            if (nivelNuevo case final n?) ...[
              const SizedBox(height: 6),
              Text(
                Textos.subisteDeNivel(n),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Tema.morado,
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
                      Textos.plumasGanadas(plumasGanadas),
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Tema.marronPluma),
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
                  onPressed: () => abrir<void>(context, PantallaTimelapse(cuadroId: clave)),
                  child: const Text(Textos.verComoLoPinte),
                ),
                if (tutorial)
                  FilledButton(
                    onPressed: () => Principal.volver(context, pestana: Principal.galeria),
                    child: const Text(Textos.tutorialSeguir),
                  )
                else if (libre)
                  FilledButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text(Textos.libreOtro),
                  )
                else
                  FilledButton(
                    // Si toca el tutorial de la tienda, Principal abre la Tienda.
                    onPressed: () => Principal.volver(context, pestana: Principal.mapa),
                    child: Text(
                      tutorialTiendaPendiente(context) ? Textos.irALaTienda : Textos.verElMapa,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
