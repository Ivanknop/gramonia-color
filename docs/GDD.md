# Gramonia Color — Documento de diseño (GDD corto)

> Juego para teléfonos Android de pintar por números.

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

## 1b. Portada

El mapa de Gramonia arranca a todo color y en unos 2,5 segundos se apaga hasta
el blanco y negro (Mututu robando los colores). Ya en gris aparece el título en
dos tiempos, "Gramonia…" y después "Color", en Luckiest Guy con degradado de
lilas (#C8A2C8 → #9B6FBF, en `Tema`) y contorno oscuro. Debajo, el botón:
"¡Empezar!" la primera vez (historia de Gobi, elección de género y galería) o
"Continuar pintando" (la obra empezada más reciente, o la galería). Tocar la
pantalla saltea la animación. Línea de tiempo en `lib/engine/intro.dart`.

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
8. Al terminar el cuadro: **festejo** (confeti arcoíris, cartel "¡Terminaste!",
   campanitas y tres vibraciones), mensaje, parte del mapa recuperada y plumas.
   Después, un **timelapse**: la repetición acelerada (2,5 a 6 s) de cómo se
   pintó, región por región en el orden guardado; se puede saltear y volver a
   ver desde el panel final o desde Mis obras. El capítulo de Gobi, si lo hay,
   llega al final.

9. **Música**: en cada dibujo suena un tema al azar (de `arte/musica`); al
   terminar sigue otro. Botones "Cambiar música" y "Silenciar".

No hay derrota ni tiempo límite. El progreso se guarda en todo momento.

## 2b. Plumas del Rocanón (moneda) y tienda

- Se ganan: **5 por día** al entrar, **3 por cuadro** terminado (historia, modo
  libre u obra rehecha) y **10 por nivel** que se sube en la historia (valores
  en `lib/engine/plumas.dart`).
- Se gastan en la **Tienda** (pestaña con ícono de tienda, la atiende el Lobo
  de la tienda: "No explico mucho. Vendo."): **lupa 5 plumas, bomba 10**.
- Usar la lupa o la bomba gasta una del inventario. Sin ninguna, se avisa que
  se consiguen en la Tienda.

## 3. Progresión

Gramonia se recorre lugar por lugar, con **dificultad creciente**: cada lugar
tiene más obras que el anterior y cada obra más regiones para pintar.

1. Árbol Mágico (3 obras) → 2. Bosque Mágico (4) → 3. Reino Animal (4) →
4. Tierra de las Caperucitas (5) → 5. Montaña Dragón (5) → 6. Reino Helado (5) →
7. Prado de las Hadas (5) → 8. La Ciudad (6, linda con el Muelle) → 9. La Costa (6) →
10–16. Las siete **Islas Arcoíris**, una por color (roja, naranja, amarilla,
verde, azul, añil y morada), de 6 a 9 obras cada una.

**Niveles** (`lib/engine/niveles.dart`): marcan el avance de la historia. Cada
nivel pide una cantidad de obras para pasar al siguiente y fija los colores de
sus obras, con la regla valor(n) = valor(n-1) + ⌊valor(n-1)/2⌋ (nivel 1: 2 obras
de 10 colores): 2/10, 3/15, 4/22, 6/33, 9/49… El nivel de una obra sale de su
lugar en el recorrido; el conversor la genera con los colores de su nivel. La
galería muestra el nivel actual y cuántas obras faltan para el siguiente.

**Modo libre** (botón en la portada): pintar sin la historia de Mututu ni el
revelado de lugares. Entran los cuadros de lugares ya desbloqueados en la
historia y los que no son de la historia. Al elegir un dibujo se elige la
dificultad; la partida se guarda aparte (clave `<cuadro>--<dificultad>`), no da
plumas ni destapa piezas, y aparece en Mis obras con su dificultad. Al terminar
hay festejo y timelapse igual.

**Rehacer** (Mis obras, en las terminadas): la obra queda en blanco y se
vuelve a pintar en la dificultad que se elija (se puede cambiar cada vez). Lo
desbloqueado no se pierde: las obras terminadas se guardan aparte
(`desbloqueadas`), así que la pieza sigue destapada y el lugar siguiente
abierto. Terminarla de nuevo festeja, pero no da plumas ni pieza.

**Dificultades** (modo libre y "rehacer obra"): súper fácil, fácil, normal,
mediano, difícil, muy difícil, extremo, imposible, insano y divino. Cada una
tiene colores fijos y un objetivo de regiones, a mano en
`assets/dificultades.json` (de 4 colores y 20 regiones a 50 y 700). El
conversor genera una variante de cada cuadro por dificultad.

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
