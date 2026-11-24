# Colores de Gramonia — Documento de diseño (GDD corto)

> Nombre provisorio. Juego para celular (Android / iOS) de pintar por números.

## 1. Historia

**Gramonia** es un mundo de biomas muy distintos entre sí: bosques que susurran,
costas de espuma, montañas de cristal… Su memoria vive en los **cuadros**: miles de
pinturas de todo tipo (paisajes, animales, objetos, personas, obras de arte) que
la gente de Gramonia fue juntando de todas partes, no solo de su propio mundo.

**Mututu** es una criatura traviesa (no malvada) que se _robó los colores_ de un
montón de cuadros, que quedaron en blanco y negro. Sin sus cuadros, los biomas de
Gramonia empiezan a desdibujarse en el mapa.

El jugador devuelve el color a cada cuadro pintando región por región. Cada
cuadro recuperado destapa una pieza del mapa de Gramonia; al destapar todas las
piezas de un bioma, ese bioma vuelve a la vida por completo.

**Tono:** amable, colorido, con humor suave. Mututu aparece con frases cortas al
completar cada cuadro (por ejemplo: _"Hasta el vapor había perdido su color por
culpa de Mututu"_). Más adelante podría tener un arco propio: ¿por qué roba
colores? (ideas: los colecciona porque él es gris; los guarda para un bioma
secreto).

## 2. Mecánica principal

1. El cuadro se muestra en **grises claros** con un **número** en cada región.
2. Abajo hay una **paleta** con los colores numerados.
3. El jugador elige un color; las regiones de ese número que faltan se
   **resaltan**.
4. Al tocar una región:
   - número correcto → se pinta con su color (y feedback leve: vibración/sonido);
   - número incorrecto → no se pinta (feedback suave, sin castigo);
   - ya pintada → no pasa nada.
5. Al completar todas las regiones de un color, la paleta lo marca con ✓ y se
   pasa al siguiente color pendiente.
6. **Zoom y paneo** con gestos (pellizcar / arrastrar) para regiones chicas.
7. Al completar el cuadro: **animación de devolución del color**, mensaje de
   Mututu y **revelado de la pieza** del bioma.

No hay derrota ni tiempo límite: es un juego relajante. El progreso de cada
cuadro se guarda en todo momento.

## 3. Progresión

- **Biomas**: cada uno es una grilla de piezas (por ejemplo 2x2, 3x3).
- **Piezas**: cada pieza está asociada a **un cuadro**. Completar ese cuadro la
  destapa.
- **Bioma desbloqueado**: cuando todas las celdas de su grilla están destapadas.
  Recompensa: ilustración completa del bioma, descripción y (a futuro) música
  ambiente, nuevos cuadros o una escena animada.
- Los cuadros no tienen por qué tener relación temática con el bioma que
  destapan (un cuadro de una taza de té puede destapar una parte del bosque).
- Dificultad de un cuadro: 1 a 5, según cantidad y tamaño de regiones.

Ejemplo actual (datos de prueba): _Bosque Susurrante_ (2 piezas) y _Costa de
Espuma_ (4 celdas, 1 pieza asignada por ahora).

## 4. Contenido

- **Cuadros**: SVG con regiones numeradas + JSON con paleta y metadatos
  (ver [formato-cuadros.md](formato-cuadros.md)). Se pueden hacer a mano en un
  editor vectorial o generar desde una imagen con `scripts/imagen_a_cuadro.py`.
- **Biomas**: definidos en `src/data/biomas/index.ts`.
- **Mensajes de Mututu**: uno por cuadro (campo `mensajeMututu`).

## 5. Pantallas

| Pantalla | Ruta           | Contenido                                           |
| -------- | -------------- | --------------------------------------------------- |
| Inicio   | `/`            | Título, frase de historia, botones a galería y mapa |
| Galería  | `/galeria`     | Lista de cuadros con avance (%) o "¡Con color!"     |
| Pintar   | `/pintar/[id]` | Lienzo, paleta, avance; panel final al completar    |
| Mapa     | `/mapa`        | Biomas con sus piezas destapadas / ocultas          |

## 6. Ideas para más adelante (fuera del alcance inicial)

- Pistas: un toque largo en un color muestra dónde quedan regiones pendientes.
- Galería por categorías y cuadros "especiales" de Gramonia.
- Exportar/compartir el cuadro terminado.
- Coleccionables de Mututu (frases, apariciones escondidas en los cuadros).
- Modo "pincel": arrastrar para pintar varias regiones seguidas.
