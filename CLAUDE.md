# Colores de Gramonia

Juego de **pintar por números** para **teléfonos Android** (nombre provisorio).
Mututu le robó los colores a un montón de cuadros (paisajes, animales, objetos,
personas, arte); el jugador se los devuelve pintando cada región según su
número. Cada cuadro completado destapa una pieza del mapa de un bioma de
Gramonia; con todas sus piezas destapadas, el bioma se desbloquea entero.

Diseño: [docs/GDD.md](docs/GDD.md). Formato de cuadros:
[docs/formato-cuadros.md](docs/formato-cuadros.md).

## Idioma

Todo en **español**: comentarios, docs, nombres de dominio (cuadro, región,
paleta, bioma, pieza…), textos de la UI y commits. La UI usa voseo rioplatense
("Pintalos", "devolvéselos").

## Plataforma y stack

- **Solo Android.** No hay iOS, web ni escritorio: no agregarlos.
- **Flutter 3.50 / Dart 3.14** (el devcontainer lo trae en /opt/flutter).
  Material viene del paquete **`material_ui`**
  (`import 'package:material_ui/material_ui.dart';`), no de
  `package:flutter/material.dart`.
- Dibujo: `CustomPainter` (`lib/ui/pintor_cuadro.dart`) con `dart:ui` Path
  armado desde los comandos SVG (curvas reales → nítido con zoom).
- Zoom/paneo: `InteractiveViewer`; el toque se resuelve con la geometría del
  motor (`regionEnPunto`), no con hit-testing de widgets.
- Progreso: `shared_preferences` (JSON). Es la única dependencia externa:
  antes de sumar otra, justificar el peso (objetivo: APK liviano).
- Tests: `flutter_test`. Conversor de imágenes: Python 3 + Pillow/numpy/scipy.
- Hasta el tag `react-native-final` el proyecto fue Expo/React Native; se migró
  a Flutter para achicar la app (el APK de RN pesaba ~100 MB con 4 ABIs).

## Estructura

```
lib/main.dart            Arranque: carga catálogo y progreso, App
lib/engine/              Motor puro (sin widgets), con tests: geometría de paths
                         SVG, lectura del SVG, ubicación de números, reglas de
                         pintar, colores, progresión de biomas, zoom máximo
lib/datos/catalogo.dart  Carga assets/cuadros (AssetManifest) y arma cuadros
lib/datos/biomas.dart    Biomas, piezas y qué cuadro destapa cada pieza
lib/estado/              Progreso persistido (ChangeNotifier) y "Mis obras"
lib/ui/                  Pintor del cuadro, lienzo con zoom, paleta, miniatura
lib/ui/pantallas/        inicio (portada), principal (pestañas: galería,
                         mis obras, mapa), pintar
assets/cuadros/          <id>.json + <id>.svg de cada cuadro
arte/                    Ilustraciones originales (fuente de los cuadros)
scripts/                 imagen_a_cuadro.py, convertir_arte.py,
                         catalogo-arte.json (títulos y parámetros de arte/)
test/                    Tests del motor, estado, datos y pantallas
android/                 Proyecto Android (applicationId com.coloresdegramonia.app)
docs/                    GDD y formato de cuadros
```

## Comandos

```bash
flutter test                         # todos los tests
flutter analyze                      # análisis estático (debe dar 0 issues)
dart format lib test                 # formato (ancho 100, ver analysis_options.yaml)
flutter build apk --release --target-platform android-arm64
                                     # → build/app/outputs/flutter-apk/app-release.apk
flutter run                          # con un teléfono conectado por adb
python3 scripts/convertir_arte.py [id...]   # arte/ → assets/cuadros (según el catálogo)
python3 scripts/imagen_a_cuadro.py foto.jpg --id mi-cuadro --titulo "Mi cuadro"
python3 -m unittest discover -s scripts -p "test_*.py"   # tests del conversor
```

El usuario instala el APK directo en el teléfono (no usa tiendas ni Expo Go).
La variante release se firma con la clave de debug (`~/.android/debug.keystore`;
el devcontainer la restaura desde `.devcontainer/android-keys/` si existe).

## Reglas del proyecto

- La lógica de juego va en `lib/engine/` como funciones puras con tests; las
  pantallas solo orquestan.
- El progreso guarda lo mínimo (regiones pintadas y fechas); lo derivado
  (porcentaje, piezas, biomas) se calcula con el motor.
- Cada cuadro destapa exactamente una pieza (lo valida `test/datos_test.dart`,
  que también verifica que cada número caiga dentro de su región).
- Los cuadros de `arte/` se generan: no editar su SVG a mano; cambiar
  `scripts/catalogo-arte.json` y volver a convertir.
- Antes de dar algo por terminado: `flutter analyze` sin issues y `flutter test`
  en verde (y los tests de Python si se tocó el conversor).
