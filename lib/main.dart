/// Gramonia Color: juego de pintar por números para Android.
library;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'datos/catalogo.dart';
import 'estado/musica.dart';
import 'estado/progreso.dart';
import 'ui/comun.dart';
import 'ui/pantallas/inicio.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final catalogo = await Catalogo.cargar(rootBundle);
  final progreso = await Progreso.cargar(AlmacenPreferencias());
  final manifiesto = await AssetManifest.loadFromAssetBundle(rootBundle);
  final musica = Musica(
    temas: manifiesto.listAssets().where((a) => a.startsWith('assets/musica/')).toList(),
    reproductor: ReproductorAudioplayers(),
    efectos: ReproductorAudioplayers(volumen: 1),
    progreso: progreso,
  );
  runApp(App(catalogo: catalogo, progreso: progreso, musica: musica));
}

class App extends StatelessWidget {
  const App({super.key, required this.catalogo, required this.progreso, this.musica});

  final Catalogo catalogo;
  final Progreso progreso;
  final Musica? musica;

  @override
  Widget build(BuildContext context) {
    return Dependencias(
      catalogo: catalogo,
      progreso: progreso,
      musica: musica,
      child: MaterialApp(
        title: 'Gramonia Color',
        debugShowCheckedModeBanner: false,
        theme: Tema.datos,
        home: const Inicio(),
      ),
    );
  }
}
