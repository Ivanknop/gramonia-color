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
lilas (#C8A2C8 → #9B6FBF, en `Tema`) y contorno oscuro. Debajo, dos opciones:

- **Modo historia**: la primera vez, la historia de Gobi (el mapa arranca a
  color y se va apagando escena por escena), el **perfil** (nombre y cómo
  hablarle) y el **tutorial**; después, las pestañas (galería, mis obras, mapa y tienda).
- **Modo libre**: los dibujos para pintar sin historia.

Los dos botones van uno al lado del otro. Abajo, el link a **Créditos** y la
versión (v1.0.0); arriba a la izquierda, el perfil (nombre y género, para
corregirlos). En los dos modos, la barra de abajo tiene una
opción con flecha hacia atrás ("Portada") que vuelve a la portada. Tocar la
pantalla saltea la animación. Línea de tiempo en `lib/engine/intro.dart`.

## 1c. Tutorial (nivel 0)

Un Árbol Mágico sencillo (por ahora, la ilustración de "El Árbol Mágico de
noche"), con **5 colores y 20 partes**. Arriba del dibujo se muestra el paso
que falta: elegir un color, tocar una parte, completar un color, apretar la
lupa y apretar la bomba (en el tutorial no se gastan). Al terminarlo se pasa
al **nivel 1** y se ganan **20 plumas**. Se juega una vez al empezar la historia
y se puede **saltar** (se pasa igual al nivel 1; las 20 plumas quedan para la
primera vez que se termine). Desde la galería se puede **volver a hacer**, ya
sin premio. Pasos en `lib/engine/tutorial.dart`.

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
   pintó, región por región en el orden guardado; se puede repetir desde el
   principio, saltear y volver a ver desde el panel final o desde Mis obras. El capítulo de Gobi, si lo hay,
   llega al final.

9. **Música**: en cada dibujo suena un tema al azar (de `arte/musica`); al
   terminar sigue otro. Botones "Cambiar música" y "Silenciar".

No hay derrota ni tiempo límite. El progreso se guarda en todo momento.

## 2b. Plumas del Rocanón (moneda) y tienda

- Se ganan: **5 por día** al entrar, **3 por cuadro** terminado de la historia
  (también una obra rehecha), en el **modo libre según la dificultad** (Súper
  fácil 1, Fácil 2, Normal 4, Mediano 6, Difícil 10, Muy difícil 15, Extremo 25,
  Imposible 40, Insano 60, Divino 100; campo `plumas` de
  `assets/dificultades.json`, que se ve al elegir la dificultad), **10 por nivel** que se sube en la historia y **20 al
  terminar el tutorial** por primera vez (valores
  en `lib/engine/plumas.dart`).
- Se gastan en la **Tienda** (pestaña con ícono de tienda, la atiende el Lobo
  de la tienda: "No explico mucho. Vendo."): **lupa 5 plumas, bomba 10**.
- Usar la lupa o la bomba gasta una del inventario. Sin ninguna, se avisa que
  se consiguen en la Tienda.

## 3. Progresión

Gramonia se recorre **nivel por nivel**, con **dificultad creciente**: cada
lugar tiene más obras que el anterior y cada obra más regiones y colores.

| Nivel | Lugares | Colores por obra |
|---|---|---|
| 0 | Tutorial | 5 |
| 1 | Árbol Mágico (3 obras) | 10 |
| 2 | Bosque Mágico (4) | 15 |
| 3 | Reino Animal (4) | 22 |
| 4 | Tierra de las Caperucitas (5) y Prado de las Hadas (5) | 33 |
| 5 | Montaña Dragón (5) y Reino Helado (5) | 49 |
| 6 | La Ciudad (6, linda con el Muelle) y La Costa (6) | 73 |
| 7 | Las siete **Islas Arcoíris** (roja, naranja, amarilla, verde, azul, añil y morada), de 6 a 9 obras | 109 |
| 8 | Isla Negra (10) | 163 |

**Niveles** (`lib/engine/niveles.dart`, nivel de cada lugar en
`lib/datos/biomas.dart`): al llegar a un nivel se abren **todos sus lugares
juntos**, y se pasa al siguiente al terminar todas sus obras disponibles. Los
colores siguen la regla valor(n) = valor(n-1) + ⌊valor(n-1)/2⌋ con el nivel 1
en 10; el conversor genera cada obra con los colores de su nivel (campo
`nivel` de `scripts/catalogo-arte.json`). La galería muestra el nivel actual y
cuántas obras faltan para el siguiente, y agrupa los lugares por nivel.

**Modo libre** (botón en la portada): pintar sin la historia de Mututu ni el
revelado de lugares. Entran los cuadros que solo son del modo libre
(`arte/libre<n>`) y los de la historia que ya se colorearon en la historia
(menos el tutorial).

**Capítulos de nivel**: al completar cada nivel, Gobi cuenta qué se recuperó,
cómo sigue la historia y avisa que hay que estar atentos por si vuelve
Mututu (también al terminar el tutorial). Se cuentan de corrido con el
capítulo del lugar, y quedan en "La historia".

**Tienda**: de fondo, la ilustración de la tienda; la atiende el Lobo de la
tienda (dibujo del canon). Al elegir un dibujo se elige la
dificultad; la partida se guarda aparte (clave `<cuadro>--<dificultad>`), da
las plumas de su dificultad, no destapa piezas, y aparece en Mis obras con su dificultad. Al terminar
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

- Un lugar se puede jugar cuando los de los niveles anteriores están
  recuperados en todo lo que tienen disponible. Las piezas **"próximamente"**
  (todavía sin obra) no traban.
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

- **Inicio** (portada): plumas, "Modo historia", "Modo libre" y, abajo,
  Créditos. La primera vez, el modo historia muestra la introducción y el
  tutorial.
- Pestañas del modo historia (la primera opción de la barra vuelve a la
  portada; el menú de arriba abre "La historia" y los créditos):
  - **Galería**: el tutorial (nivel 0) y las obras agrupadas por nivel y por
    lugar, en orden; lugares bloqueados con candado y piezas "próximamente".
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
