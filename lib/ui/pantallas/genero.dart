/// Gobi pregunta cómo quiere que le hablen quien juega (chico, chica o
/// "prefiero no decir"). Se muestra una vez, después de la introducción.
library;

import 'package:material_ui/material_ui.dart';

import '../../datos/textos.dart';
import '../../engine/genero.dart';
import '../comun.dart';

class PantallaGenero extends StatelessWidget {
  const PantallaGenero({super.key});

  @override
  Widget build(BuildContext context) {
    final progreso = Dependencias.of(context).progreso;
    void elegir(Genero g) {
      progreso.elegirGenero(g);
      Navigator.of(context).pop();
    }

    Widget opcion(String texto, Genero g) => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        width: 240,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: Tema.morado,
            side: const BorderSide(color: Tema.morado, width: 2),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () => elegir(g),
          child: Text(texto, style: const TextStyle(fontSize: 18)),
        ),
      ),
    );

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AvatarGobi(tamano: 72),
                  const SizedBox(height: 16),
                  const Text(
                    Textos.generoPregunta,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Tema.morado),
                  ),
                  const SizedBox(height: 12),
                  opcion(Textos.generoChico, Genero.chico),
                  opcion(Textos.generoChica, Genero.chica),
                  opcion(Textos.generoNeutro, Genero.neutro),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
