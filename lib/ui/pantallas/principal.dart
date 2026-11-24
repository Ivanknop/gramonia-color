/// Pestañas: Galería, Mis obras y Mapa.
library;

import 'package:material_ui/material_ui.dart';

import 'galeria.dart';
import 'mapa.dart';
import 'mis_obras.dart';

class Principal extends StatefulWidget {
  const Principal({super.key, this.pestanaInicial = galeria});

  static const galeria = 0;
  static const misObras = 1;
  static const mapa = 2;

  final int pestanaInicial;

  @override
  State<Principal> createState() => _PrincipalState();
}

class _PrincipalState extends State<Principal> {
  late int _pestana = widget.pestanaInicial;

  static const _titulos = ['Galería', 'Mis obras', 'Mapa de Gramonia'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titulos[_pestana])),
      body: IndexedStack(
        index: _pestana,
        children: [
          const Galeria(),
          MisObras(onIrAGaleria: () => setState(() => _pestana = Principal.galeria)),
          const Mapa(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pestana,
        onDestinationSelected: (i) => setState(() => _pestana = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.photo_library_outlined), label: 'Galería'),
          NavigationDestination(icon: Icon(Icons.palette_outlined), label: 'Mis obras'),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Mapa'),
        ],
      ),
    );
  }
}
