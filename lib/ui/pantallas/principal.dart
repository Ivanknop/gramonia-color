/// Modo historia: pestañas Galería, Mis obras, Mapa y Tienda. En la barra de
/// abajo, la primera opción (flecha atrás) vuelve a la portada.
///
/// Con el tutorial de la tienda pendiente (nivel 1 completo), se queda en la
/// Tienda hasta comprar la lupa o saltearlo: las otras pestañas no responden.
library;

import 'package:material_ui/material_ui.dart';

import '../../datos/textos.dart';
import '../comun.dart';
import 'creditos.dart';
import 'galeria.dart';
import 'historia.dart';
import 'mapa.dart';
import 'mis_obras.dart';
import 'perfil.dart';
import 'tienda.dart';

class Principal extends StatefulWidget {
  const Principal({super.key, this.pestanaInicial = galeria});

  static const galeria = 0;
  static const misObras = 1;
  static const mapa = 2;
  static const tienda = 3;

  final int pestanaInicial;

  @override
  State<Principal> createState() => _PrincipalState();
}

class _PrincipalState extends State<Principal> {
  late int _pestana = widget.pestanaInicial;

  static const _titulos = ['Galería', 'Mis obras', 'Mapa de Gramonia', Textos.tienda];

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Dependencias.of(context).progreso,
    builder: (context, _) {
      final tutorialTienda = tutorialTiendaPendiente(context);
      if (tutorialTienda) {
        _pestana = Principal.tienda;
        // El Lobo regala las plumas para la lupa (una sola vez).
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Dependencias.of(context).progreso.empezarTutorialTienda();
        });
      }
      return PopScope(canPop: !tutorialTienda, child: _armar(context, tutorialTienda));
    },
  );

  void _avisarTutorialTienda() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text(Textos.tutorialTiendaPrimero), duration: Duration(seconds: 2)),
      );
  }

  Widget _armar(BuildContext context, bool tutorialTienda) {
    return Scaffold(
      appBar: AppBar(
        // Se vuelve a la portada con la flecha de la barra de abajo.
        automaticallyImplyLeading: false,
        title: Text(_titulos[_pestana]),
        actions: [
          const ContadorPlumas(),
          PopupMenuButton<VoidCallback>(
            key: const Key('menu'),
            onSelected: (accion) => accion(),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute<void>(builder: (_) => const PantallaPerfil(editar: true))),
                child: const Text(Textos.perfil),
              ),
              PopupMenuItem(
                value: () =>
                    Navigator.of(context)
                        .push(MaterialPageRoute<void>(builder: (_) => const IndiceHistoria())),
                child: const Text(Textos.laHistoria),
              ),
              PopupMenuItem(
                value: () =>
                    Navigator.of(context)
                        .push(MaterialPageRoute<void>(builder: (_) => const Creditos())),
                child: const Text(Textos.creditos),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _pestana,
        children: [
          const Galeria(),
          MisObras(onIrAGaleria: () => setState(() => _pestana = Principal.galeria)),
          const Mapa(),
          const Tienda(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        // La 0 es "Portada": no es una pestaña, vuelve a la portada.
        selectedIndex: _pestana + 1,
        onDestinationSelected: (i) {
          if (tutorialTienda) {
            if (i != Principal.tienda + 1) _avisarTutorialTienda();
            return;
          }
          i == 0 ? volverAPortada(context) : setState(() => _pestana = i - 1);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.arrow_back), label: Textos.portada),
          NavigationDestination(icon: Icon(Icons.photo_library_outlined), label: 'Galería'),
          NavigationDestination(icon: Icon(Icons.palette_outlined), label: 'Mis obras'),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Mapa'),
          NavigationDestination(
            icon: ImageIcon(AssetImage(iconoTienda), key: Key('icono-tienda')),
            label: Textos.tienda,
          ),
        ],
      ),
    );
  }
}
