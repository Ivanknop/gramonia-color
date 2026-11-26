import 'package:material_ui/material_ui.dart';

import '../datos/textos.dart';
import '../engine/motor.dart';

class Paleta extends StatelessWidget {
  const Paleta({
    super.key,
    required this.paleta,
    required this.elegido,
    required this.completos,
    required this.onElegir,
  });

  final List<ColorPaleta> paleta;
  final int? elegido;
  final Set<int> completos;
  final ValueChanged<int> onElegir;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: paleta.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final c = paleta[i];
          final completo = completos.contains(c.numero);
          final esElegido = elegido == c.numero;
          return Semantics(
            button: true,
            selected: esElegido,
            label: Textos.colorDePaleta(c.numero, c.nombre, completo: completo),
            excludeSemantics: true,
            child: GestureDetector(
              key: Key('color-${c.numero}'),
              onTap: () => onElegir(c.numero),
              child: Opacity(
                opacity: completo ? 0.45 : 1,
                child: AnimatedScale(
                  scale: esElegido ? 1.1 : 1,
                  duration: const Duration(milliseconds: 120),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Color(argbDeHex(c.hex)),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: esElegido ? const Color(0xFF222222) : const Color(0x22000000),
                        width: esElegido ? 4 : 2,
                      ),
                    ),
                    child: Text(
                      completo ? '✓' : '${c.numero}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(textoSobre(c.hex)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
