# Formato de los cuadros

Cada cuadro vive en su carpeta: `src/data/cuadros/<id>/`, con dos archivos.

## cuadro.json — metadatos y paleta

```json
{
  "id": "taza-de-te",
  "titulo": "Taza de té",
  "categoria": "objeto",
  "dificultad": 2,
  "paleta": [
    { "numero": 1, "nombre": "Crema", "hex": "#FFF2CC" },
    { "numero": 2, "nombre": "Madera", "hex": "#B45F06" }
  ],
  "mensajeMututu": "¡Té caliente otra vez!",
  "orden": 0
}
```

- `id` debe coincidir con el nombre de la carpeta.
- `categoria`: `paisaje`, `animal`, `objeto`, `persona` o `arte`.
- `hex` en formato `#RRGGBB`. Todos los colores de la paleta deben usarse.
- `orden` (opcional) ordena la galería (menor primero; empate → por id).

## cuadro.svg — regiones

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 300">
  <path id="pared" data-numero="1" d="M0 0 H300 V210 H0 Z" />
  <path id="taza" data-numero="4" d="M90 115 H210 L195 225 Q150 240 105 225 Z" />
  <path id="vapor-1" data-numero="7" data-etiqueta="135 80" d="…" />
</svg>
```

- Solo se leen los `<path>`. Cada uno es una **región** y necesita `id` único,
  `data-numero` (un número de la paleta) y `d`.
- **Orden = capas**: las regiones se dibujan en orden y las últimas tapan a las
  primeras. Se puede dibujar "por capas" (un cielo entero y el sol encima) sin
  recortar formas. Una región totalmente tapada es un error.
- **Agujeros**: varios subpaths en el mismo `d` usan la regla _evenodd_ (un
  subpath dentro de otro es un hueco).
- Comandos de path: `M L H V C S Q T Z` (absolutos y relativos). Evitar arcos
  (`A`): se aproximan con una recta. En Inkscape/Illustrator, convertir objetos
  a trayecto (_Object to Path_) resuelve esto.
- `data-etiqueta="x y"` (opcional) fija dónde va el número. Si no está, el motor
  lo calcula: busca el punto de la parte visible de la región más alejado de
  los bordes.
- Los demás atributos (`fill`, `stroke`, estilos) se ignoran: sirven para
  previsualizar el SVG en un navegador.

## Después de agregar o editar un cuadro

1. `npm run cuadros` — regenera `src/data/cuadros/indice.generado.ts`.
2. Asignarle una pieza en `src/data/biomas/index.ts`.
3. `npm test` — los tests de datos validan que el cuadro se construya, que cada
   número quede sobre su región y que los biomas sean consistentes.

## Desde una imagen

```bash
npm run imagen-a-cuadro -- foto.jpg --id gato-en-la-ventana --titulo "Gato en la ventana" \
  --categoria animal --colores 10
```

Opciones útiles: `--ancho` (detalle de la grilla, por defecto 96 px),
`--area-minima` (fusiona regiones chicas), `--tolerancia` (simplificación de
bordes), `--suavizado`. Conviene revisar el resultado y renombrar los colores en el
JSON ("Color 3" → "Verde musgo").
