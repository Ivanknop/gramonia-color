/// Colores de Gramonia: juego de pintar por números para Android.
library;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'datos/catalogo.dart';
import 'estado/progreso.dart';
import 'ui/comun.dart';
import 'ui/pantallas/inicio.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final catalogo = await Catalogo.cargar(rootBundle);
  final progreso = await Progreso.cargar(AlmacenPreferencias());
  runApp(App(catalogo: catalogo, progreso: progreso));
}

class App extends StatelessWidget {
  const App({super.key, required this.catalogo, required this.progreso});

  final Catalogo catalogo;
  final Progreso progreso;

  @override
  Widget build(BuildContext context) {
    return Dependencias(
      catalogo: catalogo,
      progreso: progreso,
      child: MaterialApp(
        title: 'Colores de Gramonia',
        debugShowCheckedModeBanner: false,
        theme: Tema.datos,
        home: const Inicio(),
      ),
    );
  }
}
