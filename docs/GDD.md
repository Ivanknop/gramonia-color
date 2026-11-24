# Colores de Gramonia — Documento de diseño (GDD corto)

> Nombre provisorio. Juego para teléfonos Android de pintar por números.

## 1. Historia

Basada en el material de Gramonia (`docs/Cuentos.pdf` y `docs/Universo Gramonia.pdf`).
El texto completo, en borrador para revisar, está en `lib/datos/historia.dart`.

**Gramonia** es una isla enorme que se sostiene sobre las raíces del **Árbol
Mágico**, cuya copa es el cielo. Allá arriba vive el **Rocanón**, el ave-sol; de
noche, sus plumas caídas son las estrellas. La memoria de Gramonia vive en sus
**cuadros**.

**Mututu** —el ser misterioso de la Isla Negra, más allá de las Islas Arcoíris—
se llevó los colores de los cuadros, y sin ellos Gramonia se fue apagando.

El guía es **Gobi, el Lobito Guardián**: el más chiquito de los Lobos, nacido de
un huevo carmesí con mariposas bordadas, que no tenía bioma para cuidar… hasta
ahora. Gobi narra la historia: una introducción la primera vez que se juega
(con una imagen inicial todavía no definida) y un capítulo cada vez que se
recupera un lugar. El final llega en la Isla Negra, con un abrazo para Mututu
(Gobi es el coleccionista de abrazos).

## 2. Mecánica principal

1. El cuadro se muestra en **blanco y negro puro**, como un libro para
   colorear: regiones blancas con contorno negro y su **número**.
2. Abajo hay una **paleta** con los colores numerados; al abrir un cuadro ya
   está elegido el **color 1**, y sus regiones pendientes se marcan con un tinte.
3. Al tocar una región del número correcto, el color **se expande con
   movimiento desde el dedo** hasta llenarla, mostrando la ilustración a color
   en esa región: con sus luces, sombras y brillos (no un color plano).
   - Toque tolerante: si el dedo cae un poco al costado (~14 puntos) de una
     región pendiente del color elegido, se pinta igual.
   - Número incorrecto: no pinta (vibración suave). Correcto: vibración leve.
4. Al completar un color, la paleta lo marca con ✓ y se pasa al siguiente.
5. **Zoom y paneo** con gestos. El cuadro arranca llenando toda la pantalla.
6. **Lupa**: lleva la vista a la próxima región pendiente del color elegido
   (cada toque, la siguiente) y la señala.
7. **Bomba de color**: se arma con el botón y el próximo toque pinta todas las
   regiones cercanas, cada una con su color, en una onda desde donde cae.
8. Al terminar el cuadro: mensaje, parte del mapa recuperada y plumas.

No hay derrota ni tiempo límite. El progreso se guarda en todo momento.

## 2b. Plumas del Rocanón (moneda)

- Se ganan: **5 por día** al entrar, **10 por obra** terminada y **30 por lugar**
  completo (valores en `lib/engine/plumas.dart`).
- Se gastan en la lupa (1) y la bomba (5). **Por ahora las herramientas son
  gratis** (`ReglasPlumas.herramientasGratis`); el saldo igual se acumula.

## 3. Progresión

Gramonia se recorre lugar por lugar, con **dificultad creciente**: cada lugar
tiene más obras que el anterior y cada obra más regiones para pintar.

1. Árbol Mágico (2 obras) → 2. Bosque Mágico (3) → 3. La Ciudad (3) →
4. Reino Animal (4) → 5. Montaña Dragón (4) → 6. Prado de las Hadas (5) →
7. Tierra de las Caperucitas (5) → 8. Reino Helado (6) → 9. La Costa (6) →
10–16. Las siete **Islas Arcoíris**, una por color (roja, naranja, amarilla,
verde, azul, añil y morada), de 6 a 9 obras cada una.

- Un lugar se puede jugar cuando el anterior está recuperado en todo lo que
  tiene disponible. Las piezas **"próximamente"** (todavía sin obra) no traban.
- Cada obra terminada colorea una parte del **mapa**; con el lugar completo se
  colorea entero y Gobi cuenta su capítulo.
- Las regiones por obra hoy van de 70 (Árbol) a ~340 (Costa).

## 4. Contenido

- **Cuadros**: SVG con regiones numeradas + JSON con paleta y metadatos
  (ver [formato-cuadros.md](formato-cuadros.md)). Se pueden hacer a mano en un
  editor vectorial o generar desde una imagen con `scripts/imagen_a_cuadro.py`.
- **Lugares (biomas)**: `lib/datos/biomas.dart`. Zonas del mapa provisorio:
  `lib/datos/mapa.dart` (sobre `fondo-caminatas`, que después volverá a ser obra).
- **Historia**: `lib/datos/historia.dart`.
- **Mensajes de Mututu**: uno por cuadro (campo `mensajeMututu`).

## 5. Pantallas

- **Inicio** (portada): Gobi, plumas, botones a pintar, mapa e historia. La
  primera vez muestra la introducción.
- Pestañas:
  - **Galería**: obras agrupadas por lugar, en orden; lugares bloqueados con
    candado y piezas "próximamente".
  - **Mis obras**: cuadros empezados (para retomar) y terminados, con miniatura.
  - **Mapa**: Gramonia en gris que se va coloreando; lista de lugares.
- **Pintar**: lienzo grande con zoom, lupa, bomba, avance y paleta.
- **Historia**: escenas narradas por Gobi (introducción y capítulos).

## 6. Ideas para más adelante (fuera del alcance inicial)

- Pistas: un toque largo en un color muestra dónde quedan regiones pendientes.
- Galería por categorías y cuadros "especiales" de Gramonia.
- Exportar/compartir el cuadro terminado.
- Coleccionables de Mututu (frases, apariciones escondidas en los cuadros).
- Modo "pincel": arrastrar para pintar varias regiones seguidas.
