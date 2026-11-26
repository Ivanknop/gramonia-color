# Gramonia a Color

Juego de pintar por números para Android basado en los
[Cuentos de Gramonia](https://cuentosdegramonia.substack.com/), de Iván y
Regina Knopoff.

Una mañana Gramonia amaneció en blanco y negro: Mututu se llevó sus colores
rumbo al mar. Gobi, el más chiquito de los Lobos guardianes, te pide ayuda para
devolvérselos. Cada dibujo tiene sus partes numeradas: elegís un color y tocás
las partes con ese número. Al terminar un dibujo, un pedacito de Gramonia
vuelve a brillar en el mapa.

## Cómo se juega

- **Modo historia**: Gramonia se recorre por niveles, del Árbol Mágico a la
  Isla Negra, donde vive Mututu. Cada nivel tiene sus lugares y sus dibujos, y
  cada uno pide más colores que el anterior. Al completar un nivel, Gobi cuenta
  cómo sigue la historia. La primera vez hay un tutorial cortito.
- **Modo libre**: dibujos para pintar sin historia, en la dificultad que
  quieras, de Súper fácil a Insano.
- **Plumas del Rocanón**: se ganan cada día, al terminar dibujos y al subir de
  nivel. En la tienda se cambian por **lupas**, que te muestran una parte que
  falta, y **bombas de color**, que pintan un montón de partes de una vez.

Por ahora se pueden jugar los niveles 1 a 6 completos y una de las siete Islas
Arcoíris. Faltan las otras islas y la Isla Negra.

## Instalarlo en el celular

Requiere Android 7 o superior.

1. Desde el celular, entrá a la
   [última versión](https://github.com/Ivanknop/gramonia-color/releases/latest)
   y descargá el archivo `.apk`.
2. Abrí el archivo descargado. Si el celular avisa que es un archivo de origen
   desconocido, tocá **Configuración** y activá **Permitir de esta fuente**
   para el navegador o el gestor de archivos.
3. Tocá **Instalar**. Si aparece Google Play Protect, elegí **Instalar de todas
   formas**.
4. Abrí **Gramonia a Color** (así aparece debajo del ícono). No pide ningún
   permiso.

Para actualizar, descargá el APK nuevo e instalalo encima. La partida se
conserva.

**Privacidad**: la app no recopila ni envía datos. La partida queda solo en tu
celular.

## Créditos

- Guion y desarrollo: Iván y Regina Knopoff, Cuentos de Gramonia.
- Imágenes y música: generadas con Google Gemini a partir de los cuentos.
- Colaboración en el código: Claude.

## Para desarrollar

```bash
flutter test
flutter build apk --release --target-platform android-arm64
# → build/app/outputs/flutter-apk/app-release.apk
```

- Diseño del juego: [docs/GDD.md](docs/GDD.md)
- Cómo hacer cuadros: [docs/formato-cuadros.md](docs/formato-cuadros.md)
- Contexto para desarrollo: [CLAUDE.md](CLAUDE.md)
