/// Portada del juego, con su intro: el mapa de Gramonia arranca a todo color y
/// se va apagando hasta el blanco y negro (Mututu robando los colores), menos
/// los lugares de los niveles ya completos, que se quedan con su color; ya en
/// gris aparece el título "Gramonia… Color" en lilas y, debajo, los dos modos:
///
/// - "Modo historia": la primera vez cuenta la historia de Gobi, pregunta cómo
///   hablarle a quien juega y arranca el tutorial (nivel 0, se puede saltear);
///   después abre las pestañas (galería, mis obras, mapa y tienda).
/// - "Modo libre": los dibujos para pintar sin historia.
///
/// Abajo, el link a los créditos. Desde los dos modos, la flecha de la barra de
/// abajo vuelve acá.
///
/// Tocar la pantalla durante la animación la saltea. Cada día, al entrar, el
/// Rocanón regala plumas.
library;

import 'package:material_ui/material_ui.dart';

import '../../datos/biomas.dart';
import '../../datos/historia.dart';
import '../../datos/textos.dart';
import '../../engine/intro.dart';
import '../../engine/motor.dart';
import '../../engine/niveles.dart';
import '../comun.dart';
import 'creditos.dart';
import 'perfil.dart';
import 'historia.dart';
import 'mapa.dart';
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

  /// Nombre y género. También para quien ya jugaba antes de que existiera la pregunta.
  Future<void> _preguntarPerfil() async {
    if (!Dependencias.of(context).progreso.perfilCompleto) await _abrir(const PantallaPerfil());
  }

  Future<void> _modoHistoria() async {
    final progreso = Dependencias.of(context).progreso;
    if (!progreso.introVista) {
      await _abrir(
        const PantallaHistoria(
          escenas: introduccion,
          textoFinal: Textos.empezar,
          colores: ColoresDeEscenas.seApagan,
        ),
      );
      progreso.marcarIntroVista();
      if (!mounted) return;
    }
    await _preguntarPerfil();
    if (!mounted) return;
    // El tutorial, al terminarlo o saltearlo, sigue a la galería.
    await _abrir(
      progreso.tutorialPasado
          ? const Principal(pestanaInicial: Principal.galeria)
          : const Pintar(cuadroId: idTutorial),
    );
  }

  Future<void> _modoLibre() async {
    await _preguntarPerfil();
    if (!mounted) return;
    await _abrir(const ModoLibre());
  }

  @override
  Widget build(BuildContext context) {
    final progreso = Dependencias.of(context).progreso;
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
                // Lo recuperado no pierde el color.
                ListenableBuilder(
                  listenable: progreso,
                  builder: (context, _) =>
                      MapaRecuperado(lugares: lugaresRecuperados(biomas, progreso.completados)),
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
                          // Para corregir el nombre o cómo hablarle.
                          Positioned(
                            top: 6,
                            left: 12,
                            child: IconButton(
                              key: const Key('editar-perfil'),
                              tooltip: Textos.perfil,
                              icon: const Icon(Icons.person_outline),
                              onPressed: () => _abrir(const PantallaPerfil(editar: true)),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Solo texto, como un enlace (sin botón marcado).
                                Semantics(
                                  link: true,
                                  child: GestureDetector(
                                    key: const Key('enlace-creditos'),
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => _abrir(const Creditos()),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                                      child: Text(
                                        Textos.creditos,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Tema.morado,
                                          decoration: TextDecoration.underline,
                                          decorationColor: Tema.morado,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const Text('·', style: TextStyle(fontSize: 13, color: Tema.morado)),
                                const SizedBox(width: 6),
                                const Text(
                                  Textos.version,
                                  key: Key('version'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Tema.morado,
                                  ),
                                ),
                              ],
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _Boton(
                                  texto: Textos.modoHistoria,
                                  principal: true,
                                  alTocar: _modoHistoria,
                                ),
                                const SizedBox(width: 10),
                                _Boton(texto: Textos.modoLibre, alTocar: _modoLibre),
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
    final contenido = Text(texto, style: const TextStyle(fontSize: 15));
    const relleno = EdgeInsets.symmetric(vertical: 14);
    return SizedBox(
      width: 150,
      child: principal
          ? FilledButton(
              style: FilledButton.styleFrom(padding: relleno),
              onPressed: alTocar,
              child: contenido,
            )
          : OutlinedButton(
              style: OutlinedButton.styleFrom(padding: relleno),
              onPressed: alTocar,
              child: contenido,
            ),
    );
  }
}
