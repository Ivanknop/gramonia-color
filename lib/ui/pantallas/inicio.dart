/// Portada del juego. La primera vez muestra la introducción de Gobi y pregunta
/// cómo quiere que le hablen; cada
/// día, al entrar, el Rocanón regala plumas.
library;

import 'package:material_ui/material_ui.dart';

import '../../datos/historia.dart';
import '../../datos/textos.dart';
import '../comun.dart';
import 'creditos.dart';
import 'genero.dart';
import 'historia.dart';
import 'principal.dart';

class Inicio extends StatefulWidget {
  const Inicio({super.key});

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  bool _revisado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_revisado) return;
    _revisado = true;
    // Después del primer frame: introducción (una vez) y plumas del día.
    WidgetsBinding.instance.addPostFrameCallback((_) => _alEntrar());
  }

  Future<void> _alEntrar() async {
    final progreso = Dependencias.of(context).progreso;
    if (!progreso.introVista) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const PantallaHistoria(escenas: introduccion, textoFinal: '¡Empezar!'),
        ),
      );
      progreso.marcarIntroVista();
    }
    // También para quien ya jugaba antes de que existiera la pregunta.
    if (mounted && progreso.genero == null) {
      await Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const PantallaGenero()));
    }
    if (!mounted) return;
    final ganadas = progreso.reclamarRecompensaDiaria();
    if (ganadas > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const IconoPluma(),
              const SizedBox(width: 8),
              Expanded(child: Text('Gobi te trae $ganadas plumas del Rocanón. ¡Buen día!')),
            ],
          ),
        ),
      );
    }
  }

  void _abrir(Widget pantalla) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => pantalla));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned(top: 12, right: 16, child: ContadorPlumas()),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AvatarGobi(tamano: 72),
                    const SizedBox(height: 16),
                    const Text(
                      'Gramonia Color',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Tema.morado,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Mututu se llevó los colores de Gramonia. '
                      'Ayudá a Gobi a devolvérselos, cuadro por cuadro.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Color(0xFF555555)),
                    ),
                    const SizedBox(height: 32),
                    _Boton(
                      texto: 'Pintar',
                      principal: true,
                      alTocar: () => _abrir(const Principal(pestanaInicial: Principal.galeria)),
                    ),
                    const SizedBox(height: 12),
                    _Boton(
                      texto: 'Mapa de Gramonia',
                      alTocar: () => _abrir(const Principal(pestanaInicial: Principal.mapa)),
                    ),
                    const SizedBox(height: 12),
                    _Boton(texto: 'La historia', alTocar: () => _abrir(const IndiceHistoria())),
                    const SizedBox(height: 4),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: Tema.morado),
                      onPressed: () => _abrir(const Creditos()),
                      child: const Text(Textos.creditos),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
      width: 240,
      child: principal
          ? FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Tema.morado, padding: relleno),
              onPressed: alTocar,
              child: contenido,
            )
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Tema.morado,
                side: const BorderSide(color: Tema.morado, width: 2),
                padding: relleno,
              ),
              onPressed: alTocar,
              child: contenido,
            ),
    );
  }
}
