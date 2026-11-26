/// Modo historia: pestañas Galería, Mis obras, Mapa y Tienda. Con el tutorial de la tienda
/// pendiente, las otras pestañas no responden.
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

  /// Cierra todo hasta la portada y abre las pestañas en [pestana].
  static void volver(BuildContext context, {required int pestana}) => Navigator.of(context)
      .pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => Principal(pestanaInicial: pestana)),
        (ruta) => ruta.isFirst,
      );

  @override
  State<Principal> createState() => _PrincipalState();
}

class _PrincipalState extends State<Principal> {
  late int _pestana = widget.pestanaInicial;

  static const _titulos = [Textos.galeria, Textos.misObras, Textos.mapa, Textos.tienda];

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
              for (final (texto, pantalla) in const [
                (Textos.perfil, PantallaPerfil(editar: true)),
                (Textos.laHistoria, IndiceHistoria()),
                (Textos.creditos, Creditos()),
              ])
                PopupMenuItem(value: () => abrir<void>(context, pantalla), child: Text(texto)),
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
            if (i != Principal.tienda + 1) avisar(context, Textos.tutorialTiendaPrimero);
            return;
          }
          i == 0 ? volverAPortada(context) : setState(() => _pestana = i - 1);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.arrow_back), label: Textos.portada),
          NavigationDestination(icon: Icon(Icons.photo_library_outlined), label: Textos.galeria),
          NavigationDestination(icon: Icon(Icons.palette_outlined), label: Textos.misObras),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: Textos.mapaCorto),
          NavigationDestination(
            icon: ImageIcon(AssetImage(iconoTienda), key: Key('icono-tienda')),
            label: Textos.tienda,
          ),
        ],
      ),
    );
  }
}
