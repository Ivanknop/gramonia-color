# Colores de Gramonia

Juego para celular de **pintar por números** (nombre provisorio). Mututu le robó
los colores a un montón de cuadros (de toda índole: paisajes, animales, objetos,
personas, arte); el jugador se los devuelve pintando cada región según su
número. Cada cuadro completado destapa una pieza del mapa de un bioma de
Gramonia; con todas sus piezas destapadas, el bioma se desbloquea entero.

Diseño completo: [docs/GDD.md](docs/GDD.md). Formato de cuadros:
[docs/formato-cuadros.md](docs/formato-cuadros.md).

## Idioma

Todo en **español**: comentarios, docs, nombres de dominio (cuadro, región,
paleta, bioma, pieza…), textos de la UI y mensajes de commit. Los textos de la
UI usan voseo rioplatense ("Pintalos", "devolvéselos").

## Stack

- **Expo SDK 58** (React Native 0.88, React 19.3) + TypeScript estricto.
- **expo-router** (rutas en `app/`, typed routes activadas).
- **react-native-svg** para dibujar cuadros.
- **react-native-gesture-handler 3** + **react-native-reanimated 4** (con
  `react-native-worklets`) para zoom/paneo. Ojo: RNGH 3 tiene API de hooks
  nueva (`usePinchGesture`, etc.); revisar `node_modules` antes de usarla.
- **zustand 5** + **AsyncStorage** para el progreso persistido.
- **expo-haptics** y **expo-audio** para feedback. `expo-av` NO: quedó
  congelado en SDK 54 y no es compatible con SDK 58.
- Jest (`jest-expo`) + `@testing-library/react-native` 14 (**`render` y
  `fireEvent` son asíncronos: siempre `await`**). `expo-router/testing-library`
  para pantallas.
- ESLint (flat config de Expo) + Prettier.
- Python 3 + Pillow/numpy/scipy para el conversor de imágenes.

Expo cambia mucho entre SDKs: antes de usar una API de Expo/RN, leer
`AGENTS.md` y consultar la documentación de la versión instalada.

## Estructura

```
app/                     Pantallas (expo-router): index, galeria, pintar/[id], mapa
src/engine/              Motor puro (sin React): geometría de paths SVG, lectura
                         del SVG, ubicación de números, reglas de pintar,
                         colores, progresión de biomas. Todo testeado.
src/components/          Lienzo (SVG del cuadro) y Paleta
src/data/cuadros/<id>/   cuadro.json + cuadro.svg de cada cuadro
src/data/cuadros/indice.generado.ts   GENERADO (npm run cuadros), no editar
src/data/biomas/         Biomas, piezas y qué cuadro destapa cada pieza
src/store/               Progreso del jugador (zustand persistido)
scripts/                 compilar-cuadros.mjs, imagen_a_cuadro.py,
                         generar-tipos-rutas.mjs
docs/                    GDD y formato de cuadros
```

Import alias: `@/` → `src/`.

## Comandos

```bash
npx expo start            # servidor de desarrollo (Expo Go); --tunnel si el
                          # celular no llega a la red del contenedor
npm run verificar         # todo: índice al día + typecheck + lint + tests JS y Python
npm test                  # Jest
npm run typecheck         # genera tipos de rutas y corre tsc
npm run lint              # expo lint (ESLint + Prettier)
npm run format            # prettier --write
npm run cuadros           # regenera el índice de cuadros tras editar src/data/cuadros
npm run imagen-a-cuadro -- foto.jpg --id mi-cuadro --titulo "Mi cuadro"
npm run test:scripts      # tests del conversor (Python)
npx expo install <pkg>    # SIEMPRE para agregar dependencias (versiones del SDK)
npx expo-doctor           # diagnóstico de dependencias
```

## Reglas del proyecto

- La lógica de juego va en `src/engine/` como funciones puras con tests; las
  pantallas solo orquestan.
- El store guarda lo mínimo (regiones pintadas y fecha de completado); lo
  derivado (porcentaje, piezas, biomas) se calcula con el motor.
- La detección de toques usa la geometría del motor (`regionEnPunto`), no los
  eventos de toque de react-native-svg, para que funcione con zoom/paneo.
- Al tocar `src/data/cuadros/`, correr `npm run cuadros`; un test falla si el
  índice generado está desactualizado.
- Cada cuadro destapa exactamente una pieza (lo validan los tests de datos).
- Antes de dar algo por terminado: `npm run verificar`.
- El devcontainer trae además Flutter/Android SDK de un proyecto anterior; no
  se usan en este proyecto.
