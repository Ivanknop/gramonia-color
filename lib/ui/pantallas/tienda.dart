/// Tienda: se cambian plumas del Rocanón por lupas y bombas de color. La
/// atiende el Lobo de la tienda (de pocas palabras, como todos los Lobos).
library;

import 'package:material_ui/material_ui.dart';

import '../../datos/textos.dart';
import '../../engine/motor.dart';
import '../comun.dart';

/// La obra de la tienda, de fondo.
const fondoTienda = 'assets/cuadros/la-tienda.webp';

/// El Lobo de la tienda (del canon: `canon/assets/personajes/lobo.webp`).
const imagenLobo = 'assets/personajes/lobo.webp';

class Tienda extends StatelessWidget {
  const Tienda({super.key});

  @override
  Widget build(BuildContext context) {
    final progreso = Dependencias.of(context).progreso;
    return ListenableBuilder(
      listenable: progreso,
      builder: (context, _) => Stack(
        fit: StackFit.expand,
        children: [
          // De fondo, la tienda (la obra), con un velo para que se lea todo.
          Image.asset(fondoTienda, fit: BoxFit.cover, cacheWidth: 720),
          const ColoredBox(color: Color(0x99FFF8EC)),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Image.asset(
                    imagenLobo,
                    key: const Key('lobo-tienda'),
                    width: 150,
                    height: 150,
                    cacheWidth: 400,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 40),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Tema.celeste, width: 2),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Textos.tiendaLobo,
                            style: TextStyle(fontWeight: FontWeight.w800, color: Tema.morado),
                          ),
                          Text(
                            '«${Textos.tiendaFrase}»',
                            style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          Textos.tiendaPlumas,
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const IconoPluma(tamano: 22),
                      const SizedBox(width: 6),
                      Text(
                        '${progreso.plumas}',
                        key: const Key('saldo-tienda'),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Sin const: se reconstruyen cuando cambian las plumas o el inventario.
              _Articulo(
                herramienta: Herramienta.lupa,
                icono: Icons.search,
                nombre: Textos.lupa,
                detalle: Textos.lupaDetalle,
              ),
              _Articulo(
                herramienta: Herramienta.bomba,
                icono: Icons.auto_awesome,
                nombre: Textos.bomba,
                detalle: Textos.bombaDetalle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Articulo extends StatelessWidget {
  const _Articulo({
    required this.herramienta,
    required this.icono,
    required this.nombre,
    required this.detalle,
  });

  final Herramienta herramienta;
  final IconData icono;
  final String nombre;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    final progreso = Dependencias.of(context).progreso;
    final alcanza = puedeComprar(progreso.plumas, herramienta);
    void comprar() {
      final mensajero = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
      if (!progreso.comprar(herramienta)) {
        mensajero.showSnackBar(const SnackBar(content: Text(Textos.faltanPlumas)));
        return;
      }
      mensajero.showSnackBar(
        SnackBar(
          content: Text(Textos.compraste(nombre.toLowerCase(), progreso.cantidad(herramienta))),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFF3E9D2),
              foregroundColor: Tema.morado,
              child: Icon(icono),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Tema.morado,
                    ),
                  ),
                  Text(detalle, style: const TextStyle(fontSize: 13, color: Tema.gris)),
                  const SizedBox(height: 4),
                  Text(
                    Textos.tenes(progreso.cantidad(herramienta)),
                    key: Key('tenes-${herramienta.name}'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              key: Key('comprar-${herramienta.name}'),
              style: FilledButton.styleFrom(
                backgroundColor: alcanza ? null : Tema.gris,
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              onPressed: comprar,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const IconoPluma(tamano: 14, color: Colors.white),
                  Text(' ${herramienta.precio}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
