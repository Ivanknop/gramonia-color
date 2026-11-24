/// Portada del juego, con su intro: el mapa de Gramonia arranca a todo color y
/// se va apagando hasta el blanco y negro (Mututu robando los colores); ya en
/// gris aparece el título "Gramonia… Color" en lilas y, debajo, el botón:
///
/// - Primera vez: "¡Empezar!" cuenta la historia de Gobi, pregunta cómo hablarle
///   a quien juega y abre la galería.
/// - Con progreso: "Continuar pintando" abre la obra empezada más recientemente
///   (o la galería, si no hay ninguna a medio pintar).
///
/// Tocar la pantalla durante la animación la saltea. Cada día, al entrar, el
/// Rocanón regala plumas.
library;

import 'package:material_ui/material_ui.dart';

import '../../datos/historia.dart';
import '../../datos/textos.dart';
import '../../engine/intro.dart';
import '../../estado/obras.dart';
import '../comun.dart';
import 'creditos.dart';
import 'genero.dart';
import 'historia.dart';
import 'modo_libre.dart';
import 'pintar.dart';
import 'principal.dart';

class Inicio extends StatefulWidget {
  const Inicio({super.key});

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> with SingleTickerProviderStateMixin {
  late final _animacion = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (Intro.duracion * 1000).round()),
  )..forward();
  bool _revisado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_revisado) return;
    _revisado = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _plumasDelDia());
  }

  @override
  void dispose() {
    _animacion.dispose();
    super.dispose();
  }

  void _plumasDelDia() {
    if (!mounted) return;
    final ganadas = Dependencias.of(context).progreso.reclamarRecompensaDiaria();
    if (ganadas == 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const IconoPluma(),
            const SizedBox(width: 8),
            Expanded(child: Text(Textos.plumasDelDia(ganadas))),
          ],
        ),
      ),
    );
  }

  /// Tocar durante la animación la saltea.
  void _saltear() {
    if (_animacion.isAnimating) _animacion.value = 1;
  }

  Future<void> _abrir(Widget pantalla) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => pantalla));

  /// También para quien ya jugaba antes de que existiera la pregunta.
  Future<void> _preguntarGenero() async {
    if (Dependencias.of(context).progreso.genero == null) await _abrir(const PantallaGenero());
  }

  Future<void> _empezar() async {
    final progreso = Dependencias.of(context).progreso;
    await _abrir(const PantallaHistoria(escenas: introduccion, textoFinal: Textos.empezar));
    progreso.marcarIntroVista();
    if (!mounted) return;
    await _preguntarGenero();
    if (!mounted) return;
    await _abrir(const Principal(pestanaInicial: Principal.galeria));
  }

  Future<void> _continuar() async {
    final dep = Dependencias.of(context);
    await _preguntarGenero();
    if (!mounted) return;
    final obra = obraParaContinuar(dep.progreso.cuadros, dep.catalogo.ids);
    await _abrir(
      obra == null ? const Principal(pestanaInicial: Principal.galeria) : Pintar(cuadroId: obra),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progreso = Dependencias.of(context).progreso;
    final primeraVez = !progreso.introVista && progreso.cuadros.isEmpty;
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _saltear,
        child: AnimatedBuilder(
          animation: _animacion,
          builder: (context, _) {
            final e = Intro.en(_animacion.value * Intro.duracion);
            // Mientras corre la animación, los botones no reciben toques.
            final listos = !_animacion.isAnimating;
            return Stack(
              fit: StackFit.expand,
              children: [
                ColorFiltered(
                  colorFilter: ColorFilter.matrix(matrizSaturacion(e.saturacion)),
                  child: Image.asset(imagenProvisoria, fit: BoxFit.cover),
                ),
                // Un velo suave para que se lean el título y los botones.
                ColoredBox(color: Color.fromRGBO(255, 255, 255, 0.25 * (1 - e.saturacion))),
                SafeArea(
                  child: IgnorePointer(
                    ignoring: !listos,
                    child: Opacity(
                      opacity: e.botones,
                      child: Stack(
                        children: [
                          const Positioned(top: 12, right: 16, child: ContadorPlumas()),
                          Positioned(
                            top: 0,
                            left: 4,
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: Tema.morado,
                                backgroundColor: const Color(0xCCFFFFFF),
                              ),
                              onPressed: () => _abrir(const Creditos()),
                              icon: const Icon(Icons.info_outline, size: 18),
                              label: const Text(Textos.creditos),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Opacity(
                          opacity: e.gramonia,
                          child: Transform.scale(
                            scale: 0.85 + 0.15 * e.gramonia,
                            child: const TituloLila(Textos.tituloGramonia, tamano: 44),
                          ),
                        ),
                        Opacity(
                          opacity: e.color,
                          child: Transform.scale(
                            scale: 0.6 + 0.4 * Curves.easeOutBack.transform(e.color),
                            child: const TituloLila(Textos.tituloColor, tamano: 64),
                          ),
                        ),
                        const SizedBox(height: 28),
                        IgnorePointer(
                          ignoring: !listos,
                          child: Opacity(
                            opacity: e.botones,
                            child: primeraVez
                                ? _Boton(texto: Textos.empezar, principal: true, alTocar: _empezar)
                                : Column(
                                    children: [
                                      _Boton(
                                        texto: Textos.continuar,
                                        principal: true,
                                        alTocar: _continuar,
                                      ),
                                      const SizedBox(height: 12),
                                      _Boton(
                                        texto: Textos.galeria,
                                        alTocar: () => _abrir(
                                          const Principal(pestanaInicial: Principal.galeria),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      _Boton(
                                        texto: Textos.modoLibre,
                                        alTocar: () => _abrir(const ModoLibre()),
                                      ),
                                      const SizedBox(height: 10),
                                      _Boton(
                                        texto: Textos.mapa,
                                        alTocar: () =>
                                            _abrir(const Principal(pestanaInicial: Principal.mapa)),
                                      ),
                                      const SizedBox(height: 10),
                                      _Boton(
                                        texto: Textos.laHistoria,
                                        alTocar: () => _abrir(const IndiceHistoria()),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Boton extends StatelessWidget {
  const _Boton({required this.texto, required this.alTocar, this.principal = false});
  final String texto;
  final VoidCallback alTocar;
  final bool principal;

  @override
  Widget build(BuildContext context) {
    final contenido = Text(texto, style: const TextStyle(fontSize: 18));
    const relleno = EdgeInsets.symmetric(vertical: 14);
    return SizedBox(
      width: 250,
      child: principal
          ? FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Tema.morado, padding: relleno),
              onPressed: alTocar,
              child: contenido,
            )
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Tema.morado,
                backgroundColor: const Color(0xE6FFFFFF),
                side: const BorderSide(color: Tema.morado, width: 2),
                padding: relleno,
              ),
              onPressed: alTocar,
              child: contenido,
            ),
    );
  }
}
