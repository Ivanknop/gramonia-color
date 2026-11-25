/// Tienda: se cambian plumas del Rocanón por lupas y bombas de color. La
/// atiende el Lobo de la tienda (de pocas palabras, como todos los Lobos).
///
/// Cada compra se confirma y, al hacerla, aparece un cartelito. Con el
/// tutorial de la tienda pendiente (al completar el nivel 1), el Lobo regala
/// las plumas justas y pide comprar una lupa; se puede saltear.
library;

import 'package:material_ui/material_ui.dart';

import '../../datos/biomas.dart';
import '../../datos/textos.dart';
import '../../engine/motor.dart';
import '../../engine/niveles.dart';
import '../comun.dart';

/// ¿Toca el tutorial de la tienda? (Nivel 1 completo y todavía sin hacer.)
bool tutorialTiendaPendiente(BuildContext context) {
  final progreso = Dependencias.of(context).progreso;
  return estadoTutorialTienda(
        hecho: progreso.tutorialTiendaHecho,
        nivelesCompletos: nivelesCompletos(biomas, progreso.completados),
      ) ==
      EstadoTutorialTienda.pendiente;
}

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
      builder: (context, _) {
        final tutorial = tutorialTiendaPendiente(context);
        return Stack(
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              Textos.tiendaLobo,
                              style: TextStyle(fontWeight: FontWeight.w800, color: Tema.morado),
                            ),
                            Text(
                              '«${tutorial ? Textos.tiendaFraseTutorial : Textos.tiendaFrase}»',
                              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (tutorial) ...[
                  const SizedBox(height: 12),
                  _AvisoTutorial(alSaltar: progreso.terminarTutorialTienda),
                ],
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
                  icono: iconoLupa,
                  nombre: Textos.lupa,
                  detalle: Textos.lupaDetalle,
                  destacado: tutorial,
                  alComprar: tutorial ? progreso.terminarTutorialTienda : null,
                ),
                _Articulo(
                  herramienta: Herramienta.bomba,
                  icono: iconoBomba,
                  nombre: Textos.bomba,
                  detalle: Textos.bombaDetalle,
                  // En el tutorial se compra la lupa: la bomba espera.
                  habilitado: !tutorial,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Aviso del tutorial de la tienda, con "Saltar".
class _AvisoTutorial extends StatelessWidget {
  const _AvisoTutorial({required this.alSaltar});
  final VoidCallback alSaltar;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('tutorial-tienda'),
    padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
    decoration: BoxDecoration(
      color: const Color(0xEE3D2C5E),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            Textos.tutorialTienda(plumasTutorialTienda),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        TextButton(
          key: const Key('saltar-tutorial-tienda'),
          style: TextButton.styleFrom(foregroundColor: Tema.aquaSuave),
          onPressed: alSaltar,
          child: const Text(Textos.tutorialSaltar),
        ),
      ],
    ),
  );
}

class _Articulo extends StatelessWidget {
  const _Articulo({
    required this.herramienta,
    required this.icono,
    required this.nombre,
    required this.detalle,
    this.destacado = false,
    this.habilitado = true,
    this.alComprar,
  });

  final Herramienta herramienta;

  /// Imagen del ícono (assets/iconos).
  final String icono;
  final String nombre;
  final String detalle;

  /// Brilla (el tutorial pide comprarla).
  final bool destacado;

  /// Se ve apagado y no se puede comprar.
  final bool habilitado;

  /// Además de comprar (el tutorial termina con la compra).
  final VoidCallback? alComprar;

  @override
  Widget build(BuildContext context) {
    final progreso = Dependencias.of(context).progreso;
    final alcanza = puedeComprar(progreso.plumas, herramienta);
    Future<void> comprar() async {
      final mensajero = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
      if (!alcanza) {
        mensajero.showSnackBar(const SnackBar(content: Text(Textos.faltanPlumas)));
        return;
      }
      // Primero se pregunta: ¿seguro?
      final si = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: Image.asset(icono, width: 56, height: 56, cacheWidth: 144),
          title: Text(Textos.confirmarCompra(nombre.toLowerCase(), herramienta.precio)),
          actions: [
            TextButton(
              key: const Key('cancelar-compra'),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(Textos.compraNo),
            ),
            FilledButton(
              key: const Key('confirmar-compra'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(Textos.compraSi),
            ),
          ],
        ),
      );
      if (si != true || !progreso.comprar(herramienta)) return;
      alComprar?.call();
      mensajero.showSnackBar(
        SnackBar(
          key: const Key('cartel-compra'),
          content: Text(Textos.compraste(nombre.toLowerCase(), progreso.cantidad(herramienta))),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    return Opacity(
      opacity: habilitado ? 1 : 0.45,
      child: Card(
        color: Colors.white,
        shape: destacado
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFFFC83D), width: 3),
              )
            : null,
        shadowColor: destacado ? const Color(0xFFFFD54F) : null,
        elevation: destacado ? 8 : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFF3E9D2),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(icono, cacheWidth: 144),
                ),
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
                onPressed: habilitado ? comprar : null,
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
      ),
    );
  }
}
