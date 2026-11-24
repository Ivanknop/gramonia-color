#!/usr/bin/env python3
"""
Convierte todas las imágenes de arte/ listadas en scripts/catalogo-arte.json
en cuadros (assets/cuadros/<id>.svg + <id>.json).

Uso: python3 scripts/convertir_arte.py          (todas, y el mapa)
     python3 scripts/convertir_arte.py <id> ... (solo esas; "mapa" para el mapa)
"""

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import imagen_a_cuadro  # noqa: E402

RAIZ = Path(__file__).resolve().parent.parent
CATALOGO = RAIZ / "scripts" / "catalogo-arte.json"


DIR_MAPA = RAIZ / "assets" / "mapa"


def ancho_para(regiones: int) -> int:
    """Grilla de trabajo según la cantidad de regiones buscada (más regiones, más detalle)."""
    if regiones <= 120:
        return 120
    if regiones <= 250:
        return 170
    return 220


def convertir_mapa(catalogo: dict) -> None:
    """Mapa provisorio: la ilustración comprimida; la app la muestra en gris y la colorea."""
    from PIL import Image

    DIR_MAPA.mkdir(parents=True, exist_ok=True)
    img = Image.open(RAIZ / "arte" / catalogo["mapa"]["imagen"]).convert("RGB")
    img.thumbnail((imagen_a_cuadro.LADO_MAXIMO_IMAGEN,) * 2)
    img.save(DIR_MAPA / "gramonia.webp", "WEBP", quality=80, method=6)
    print(f"Mapa → {DIR_MAPA / 'gramonia.webp'} ({img.width}x{img.height})")


def main() -> int:
    catalogo = json.loads(CATALOGO.read_text(encoding="utf-8"))
    base = catalogo["por_defecto"]
    pedidos = set(sys.argv[1:])
    if not pedidos or "mapa" in pedidos:
        convertir_mapa(catalogo)
    for orden, c in enumerate(catalogo["cuadros"], start=1):
        if pedidos and c["id"] not in pedidos:
            continue
        p = {**base, **c}
        p.setdefault("ancho", ancho_para(p["regiones"]))
        imagen_a_cuadro.main(
            [
                str(RAIZ / "arte" / p["imagen"]),
                "--id", p["id"],
                "--titulo", p["titulo"],
                "--categoria", p["categoria"],
                "--mensaje", p["mensaje"],
                "--orden", str(orden),
                "--colores", str(p["colores"]),
                "--ancho", str(p["ancho"]),
                "--area-minima", str(p["area_minima"]),
                "--suavizado", str(p["suavizado"]),
                "--tolerancia", str(p["tolerancia"]),
                "--curvas", str(p["curvas"]),
                "--regiones", str(p["regiones"]),
            ]
        )
    print("Listo. Si hay cuadros nuevos, asignales una pieza en lib/datos/biomas.dart.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
