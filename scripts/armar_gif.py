#!/usr/bin/env python3
"""
Arma los GIF de la introducción y el tutorial con los cuadros que graba
tool/gif_test.dart (temp/gif/<nombre>/f*.png + cuadros.json): respeta lo que
dura cada cuadro y dibuja un dedo (un círculo translúcido) donde se toca.

Uso: flutter test tool/gif_test.dart
     python3 scripts/armar_gif.py [nombre...] [--ancho 360]
     → temp/gif/<nombre>.gif
"""

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageStat

RAIZ = Path(__file__).resolve().parent.parent
CARPETA = RAIZ / "temp" / "gif"
RADIO_DEDO = 22  # en puntos de pantalla (los cuadros se graban a 1 px por punto)
LIMITE_MB = 14.5  # tienen que pesar menos de 15 MB: si se pasan, se achican


def con_dedo(img: Image.Image, x: float, y: float) -> Image.Image:
    capa = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(capa)
    r = RADIO_DEDO
    d.ellipse((x - r, y - r, x + r, y + r), fill=(255, 255, 255, 110), outline=(61, 44, 94, 220), width=3)
    d.ellipse((x - 5, y - 5, x + 5, y + 5), fill=(61, 44, 94, 200))
    return Image.alpha_composite(img, capa)


def armar(nombre: str, ancho: int) -> Path:
    """Arma el GIF; si pesa más de LIMITE_MB, lo vuelve a armar más chico."""
    while True:
        salida = armar_con_ancho(nombre, ancho)
        if salida.stat().st_size / 1e6 <= LIMITE_MB or ancho <= 200:
            return salida
        ancho = int(ancho * 0.9)
        print(f"  pesa más de {LIMITE_MB} MB: de nuevo con {ancho} px de ancho")


def armar_con_ancho(nombre: str, ancho: int) -> Path:
    dir_ = CARPETA / nombre
    cuadros = json.loads((dir_ / "cuadros.json").read_text(encoding="utf-8"))["cuadros"]
    imagenes, duraciones = [], []
    for c in cuadros:
        img = Image.open(dir_ / c["archivo"]).convert("RGBA")
        # Un cuadro liso (capturado en medio de un cambio de pantalla) no se
        # ve en el teléfono: se saltea y su tiempo pasa al anterior.
        if ImageStat.Stat(img.convert("L")).stddev[0] < 3 and duraciones:
            duraciones[-1] += c["ms"]
            continue
        if "dedo" in c:
            img = con_dedo(img, *c["dedo"])
        if img.width != ancho:
            img = img.resize((ancho, round(img.height * ancho / img.width)), Image.Resampling.LANCZOS)
        imagenes.append(img.convert("RGB").quantize(colors=256, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE))
        duraciones.append(c["ms"])
    salida = CARPETA / f"{nombre}.gif"
    imagenes[0].save(
        salida,
        save_all=True,
        append_images=imagenes[1:],
        duration=duraciones,
        loop=0,
        optimize=True,
        disposal=1,
    )
    seg = sum(duraciones) / 1000
    print(f"{salida} — {ancho} px, {len(imagenes)} cuadros, {seg:.1f} s, {salida.stat().st_size / 1e6:.1f} MB")
    return salida


def main() -> int:
    args = sys.argv[1:]
    ancho = 360
    if "--ancho" in args:
        i = args.index("--ancho")
        ancho = int(args[i + 1])
        del args[i : i + 2]
    for nombre in args or ["introduccion", "tutorial"]:
        armar(nombre, ancho)
    return 0


if __name__ == "__main__":
    sys.exit(main())
