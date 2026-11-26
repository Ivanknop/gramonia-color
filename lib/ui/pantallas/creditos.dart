import 'package:material_ui/material_ui.dart';

import '../../datos/textos.dart';
import '../comun.dart';
import '../enlaces.dart';

class Creditos extends StatelessWidget {
  const Creditos({super.key});

  Future<void> _abrirCuentos(BuildContext context) async {
    final mensajero = ScaffoldMessenger.of(context);
    if (!await abrirEnlace(urlCuentos)) {
      mensajero.showSnackBar(const SnackBar(content: Text(Textos.creditosSinNavegador)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Tema.crema,
      appBar: AppBar(title: const Text(Textos.creditos), backgroundColor: Colors.transparent),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Opacity(
            key: Key('fondo-creditos'),
            opacity: 0.28,
            child: Image(image: AssetImage('assets/mapa/gramonia.webp'), fit: BoxFit.cover),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: TituloLila(Textos.creditosTitulo, tamano: 36),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      Textos.creditosIntro,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Tema.morado),
                    ),
                    const SizedBox(height: 28),
                    for (final (rol, quienes) in Textos.realizadores) ...[
                      Text(
                        rol,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w700,
                          color: Tema.lilaOscuro,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        quienes,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Tema.morado,
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    const SizedBox(height: 8),
                    const Text(
                      Textos.creditosCuentosAntes,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Tema.morado),
                    ),
                    Semantics(
                      link: true,
                      child: GestureDetector(
                        key: const Key('enlace-cuentos'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _abrirCuentos(context),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          child: Text(
                            Textos.creditosCuentosEnlace,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Tema.lila,
                              decoration: TextDecoration.underline,
                              decorationColor: Tema.lila,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      Textos.creditosGobi,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Tema.morado,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
