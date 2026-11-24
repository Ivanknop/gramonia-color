# Gramonia Color

Juego de **pintar por números** para **teléfonos Android**.
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
  armado desde los comandos SVG. Con ilustración: lo pendiente es blanco con
  contorno negro (libro para colorear) y cada región pintada usa `ImageShader`
  de la ilustración a color (luces y sombras, no colores planos). El color se
  expande animado desde el toque (`RellenoAnimado`, ticker en `LienzoState`).
- Zoom/paneo: `InteractiveViewer`; el toque se resuelve con la geometría del
  motor (`regionEnPunto`), no con hit-testing de widgets.
- Progreso: `shared_preferences` (JSON). Música: `audioplayers` (reproductor
  nativo). Son las únicas dependencias externas: antes de sumar otra,
  justificar el peso (objetivo: APK liviano).
- Música de fondo (`lib/estado/musica.dart`): tema al azar en cada dibujo,
  botones "Cambiar música" y "Silenciar" (se recuerda); pausa en segundo plano.
- Tests: `flutter_test`. Conversor de imágenes: Python 3 + Pillow/numpy/scipy.
- Hasta el tag `react-native-final` el proyecto fue Expo/React Native; se migró
  a Flutter para achicar la app (el APK de RN pesaba ~100 MB con 4 ABIs).

## Estructura

```
lib/main.dart            Arranque: carga catálogo y progreso, App
lib/engine/              Motor puro (sin widgets), con tests: geometría de paths
                         SVG, lectura del SVG, ubicación de números, reglas de
                         pintar (toque tolerante, lupa, bomba), colores,
                         progresión secuencial de biomas, plumas, zoom máximo
lib/datos/catalogo.dart  Carga assets/cuadros (AssetManifest) y arma cuadros
lib/datos/biomas.dart    Lugares en orden (9 + 7 Islas Arcoíris), piezas y obras
lib/datos/mapa.dart      Zonas de cada lugar sobre el mapa provisorio
lib/datos/historia.dart  Historia narrada por Gobi (borrador editable)
lib/estado/              Progreso persistido (v2: + plumas, intro, capítulos) y
                         "Mis obras"
lib/ui/                  Pintor del cuadro, lienzo con zoom, paleta, miniatura
lib/ui/pantallas/        inicio (portada), principal (pestañas: galería,
                         mis obras, mapa), pintar, historia
assets/cuadros/          <id>.json + <id>.svg + <id>.webp de cada cuadro
assets/mapa/             gramonia.webp (mapa provisorio, de arte/fondo-caminatas)
assets/musica/           temas en AAC 80 kbps (de arte/musica/*.mp3)
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
python3 scripts/convertir_arte.py [id...]   # arte/ → assets (cuadros, mapa, musica)
python3 scripts/generar_icono.py            # arte/icono.jpeg → ícono de la app (android/res)
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
  que también verifica que cada número caiga dentro de su región, que la
  dificultad no baje en el recorrido y que cada lugar tenga zona y capítulo).
- Las herramientas (lupa, bomba) son gratis mientras
  `ReglasPlumas.herramientasGratis` sea true; las plumas igual se acumulan.
- Si se cambia el formato de lo guardado, subir `Progreso.version` y migrar
  (hay test de migración desde v1).
- Los cuadros de `arte/` se generan: no editar su SVG a mano; cambiar
  `scripts/catalogo-arte.json` y volver a convertir.
- Antes de dar algo por terminado: `flutter analyze` sin issues y `flutter test`
  en verde (y los tests de Python si se tocó el conversor).
