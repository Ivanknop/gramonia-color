@canon/CLAUDE.md
# Gramonia a Color

Juego de **pintar por números** para **teléfonos Android**.
Mututu le robó los colores a un montón de cuadros (paisajes, animales, objetos,
personas, arte); el jugador se los devuelve pintando cada región según su
número. Cada cuadro completado destapa una pieza del mapa de un bioma de
Gramonia; con todas sus piezas destapadas, el bioma se desbloquea entero.
La portada ofrece "Modo historia" (con un tutorial de nivel 0 la primera vez)
y "Modo libre".

Diseño: [docs/GDD.md](docs/GDD.md). Formato de cuadros:
[docs/formato-cuadros.md](docs/formato-cuadros.md).

## Idioma

Todo en **español**: comentarios, docs, nombres de dominio (cuadro, región,
paleta, bioma, pieza…), textos de la UI y commits. La UI usa voseo rioplatense
("Pintalos", "devolvéselos"). Quien juega elige chico, chica o "prefiero no
decir": los textos con género llevan `{chico|chica|neutro}` y se resuelven con
`Progreso.texto` (`lib/engine/genero.dart`).

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
                         progresión por niveles, tutorial, plumas, zoom máximo
lib/datos/catalogo.dart  Carga assets/cuadros (AssetManifest) y arma cuadros
lib/datos/biomas.dart    Lugares en orden (9 + 7 Islas Arcoíris + Isla Negra), con
                         su nivel (1 a 8), piezas y obras
lib/datos/mapa.dart      Zonas de cada lugar sobre el mapa provisorio
lib/datos/historia.dart  Historia narrada por Gobi (borrador editable)
lib/datos/textos.dart    Textos de la UI, con variantes {chico|chica|neutro}
lib/estado/              Progreso persistido (v2: + plumas, intro, capítulos;
                         v3: + género; v4: + desbloqueadas y dificultad de las
                         obras rehechas; v5: + lupas y bombas; v6: + tutorial
                         pasado y premiado; v7: + nombre; v8: + regalo
                         inicial y tutorial de la tienda; v9: siete dificultades) y
                         "Mis obras"
lib/ui/                  Pintor del cuadro, lienzo con zoom, paleta, miniatura,
                         enlaces (abre el blog con un canal nativo de MainActivity)
lib/ui/pantallas/        inicio (portada: modo historia / modo libre), perfil (nombre y género),
                         creditos, modo_libre, principal (pestañas: galería,
                         mis obras, mapa, tienda), pintar (también el tutorial),
                         historia
assets/cuadros/          <id>.json + <id>.svg + <id>.webp de cada cuadro
assets/variantes/        <id>--<dificultad>.json/.svg (modo libre; usan la webp)
assets/dificultades.json Tabla de dificultades (colores, regiones y plumas), a mano
assets/mapa/             gramonia.webp (mapa provisorio, de arte/fondo-caminatas)
assets/musica/           temas en AAC 80 kbps (de arte/musica/*.mp3)
assets/sonidos/          efectos (festejo.m4a, sintetizado por script)
assets/fuentes/          Luckiest Guy (del canon): títulos y logo
assets/personajes/       dibujos de personajes copiados del canon (lobo.webp: la tienda)
assets/iconos/           lupa, bomba y tienda (de arte/lupa.png, bomba.png, carro.png)
arte/                    Originales (imágenes, música, íconos): NO se versiona (.gitignore),
                         queda solo en la máquina local; el juego usa assets/
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
python3 scripts/convertir_arte.py [id...]   # arte/ → assets (cuadros, variantes, mapa, musica)
python3 scripts/convertir_arte.py variantes # solo las variantes de dificultad (~1,5 min)
python3 scripts/convertir_arte.py tutorial  # solo el cuadro del tutorial
python3 scripts/convertir_arte.py iconos    # solo los íconos (lupa, bomba, tienda)
python3 scripts/generar_icono.py            # arte/icono.jpeg → ícono de la app (android/res)
python3 scripts/generar_festejo.py          # sintetiza assets/sonidos/festejo.m4a
python3 scripts/imagen_a_cuadro.py foto.jpg --id mi-cuadro --titulo "Mi cuadro"
python3 -m unittest discover -s scripts -p "test_*.py"   # tests del conversor
flutter test tool/capturas_test.dart # capturas de las pantallas → temp/capturas/ (ignorada)
flutter test tool/gif_test.dart && python3 scripts/armar_gif.py
                                     # GIF de la intro y del tutorial → temp/gif/ (< 15 MB)
```

El usuario instala el APK directo en el teléfono (no usa tiendas ni Expo Go).
La variante release se firma con la clave de debug (`~/.android/debug.keystore`;
el devcontainer la restaura desde `.devcontainer/android-keys/` si existe).

## Reglas del proyecto

- La lógica de juego va en `lib/engine/` como funciones puras con tests; las
  pantallas solo orquestan.
- El progreso guarda lo mínimo (regiones pintadas y fechas); lo derivado
  (porcentaje, piezas, biomas) se calcula con el motor.
- Cada cuadro (menos el del tutorial) destapa exactamente una pieza (lo valida `test/datos_test.dart`,
  que también verifica que cada número caiga dentro de su región, que la
  dificultad no baje en el recorrido y que cada lugar tenga zona en el mapa).
- Niveles (`lib/engine/niveles.dart`): 0 = tutorial; del 1 al 8, grupos de
  lugares (`Bioma.nivel`). Los lugares de un nivel se abren juntos. Al
  completar cada nivel Gobi cuenta su capítulo (`capitulosDeNivel` en
  `lib/datos/historia.dart`: qué se recuperó, cómo sigue y, en general, ojo con Mututu).
- Cuadros `solo_libre` en `scripts/catalogo-arte.json` (los `arte/libre<n>`):
  no son de la historia, van al final y solo se juegan en el modo libre. Los
  de la historia aparecen en el modo libre recién cuando se colorearon ahí.
- Los textos pueden llevar `{nombre}` (el de quien juega, se pide en el
  perfil junto con el género); se resuelve con `Progreso.texto`.
- Versión: `Textos.version` (portada) igual a `version` de pubspec.yaml (test).
- Plumas (`lib/engine/plumas.dart`): 5 por día, 3 por cuadro terminado de la
  historia, en el modo libre las de la dificultad (de 1 a 100, en
  `assets/dificultades.json`), 10 por nivel subido y 20 por el tutorial (una sola vez).
  Lupas (5) y bombas (10) se compran en la pestaña Tienda (cada compra se
  confirma); usarlas gasta una del inventario (en el tutorial son gratis). Al
  llegar al nivel 1 se regalan 3 lupas y 3 bombas (`herramientasIniciales`).
- Tutoriales (`lib/engine/tutorial.dart`): el de pintar tiene pasos obligatorios
  y en orden (color → completar un color → lupa → bomba → terminar); al
  completar el nivel 1, el de la tienda (5 plumas y comprar una lupa). Los dos
  se pueden saltar; los premios son solo por cumplirlos.
- Si se cambia el formato de lo guardado, subir `Progreso.version` y migrar
  (hay test de migración desde v1).
- Los cuadros de `arte/` se generan: no editar su SVG a mano; cambiar
  `scripts/catalogo-arte.json` y volver a convertir. Si el original ya se borró
  de `arte/`, el conversor usa `assets/cuadros/<id>.webp`.
- Colores: en la historia los pone el nivel de la obra (campo `nivel` de
  `scripts/catalogo-arte.json`, igual al de su lugar; regla en
  `lib/engine/niveles.dart`); en el modo libre, la dificultad
  (`assets/dificultades.json`); el tutorial tiene 5 fijos. El conversor los
  respeta exactos.
- Botones: redondos (píldora o círculo) en lilas, celestes y verde agua, desde
  el tema (`Tema.datos` en `lib/ui/comun.dart`): relleno = lila, con borde =
  celeste, de texto e íconos = verde agua, herramientas = `Tema.botonAqua`. No
  ponerles colores sueltos. "Volver a empezar" usa `IconoEspiral`.
- Antes de dar algo por terminado: `flutter analyze` sin issues y `flutter test`
  en verde (y los tests de Python si se tocó el conversor).
