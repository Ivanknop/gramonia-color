/// Portada del juego.
library;

import 'package:material_ui/material_ui.dart';

import '../comun.dart';
import 'principal.dart';

class Inicio extends StatelessWidget {
  const Inicio({super.key});

  void _abrir(BuildContext context, int pestana) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => Principal(pestanaInicial: pestana)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Colores de Gramonia',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Tema.morado),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Mututu se llevó los colores de un montón de cuadros. '
                  'Pintalos número por número y devolvéselos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Color(0xFF555555)),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 240,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Tema.morado,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _abrir(context, Principal.galeria),
                    child: const Text('Pintar', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 240,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Tema.morado,
                      side: const BorderSide(color: Tema.morado, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _abrir(context, Principal.mapa),
                    child: const Text('Mapa de biomas', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
