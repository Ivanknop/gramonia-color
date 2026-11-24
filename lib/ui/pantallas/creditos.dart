/// Créditos: quién hizo el juego. Se abre desde la portada y desde el menú.
library;

import 'package:material_ui/material_ui.dart';

import '../../datos/textos.dart';
import '../comun.dart';

class Creditos extends StatelessWidget {
  const Creditos({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Textos.creditos)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(child: AvatarGobi(tamano: 64)),
          const SizedBox(height: 12),
          const Text(
            'Gramonia Color',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Tema.morado),
          ),
          const SizedBox(height: 8),
          const Text(
            Textos.creditosIntro,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Tema.gris),
          ),
          const SizedBox(height: 24),
          for (final (rol, quienes) in Textos.realizadores) ...[
            Text(
              rol,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Tema.gris),
            ),
            const SizedBox(height: 2),
            Text(
              quienes,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Tema.morado),
            ),
            const SizedBox(height: 18),
          ],
          const SizedBox(height: 8),
          const Text(
            Textos.creditosCuentos,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Tema.gris),
          ),
          const SizedBox(height: 24),
          const Text(
            Textos.creditosGobi,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Tema.morado),
          ),
        ],
      ),
    );
  }
}
