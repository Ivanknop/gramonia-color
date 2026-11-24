#!/usr/bin/env python3
"""
Convierte todas las imágenes de arte/ listadas en scripts/catalogo-arte.json
en cuadros (assets/cuadros/<id>.svg + <id>.json).

Uso: python3 scripts/convertir_arte.py          (todas, el mapa y la música)
     python3 scripts/convertir_arte.py <id> ... (solo esas; "mapa" o "musica")
"""

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import imagen_a_cuadro  # noqa: E402

RAIZ = Path(__file__).resolve().parent.parent
CATALOGO = RAIZ / "scripts" / "catalogo-arte.json"


DIR_MAPA = RAIZ / "assets" / "mapa"

# Niveles del modo historia (igual que lib/engine/niveles.dart, con los mismos
# valores en los tests): valor(n) = valor(n-1) + valor(n-1) // 2.
OBRAS_DEL_NIVEL_1 = 2
COLORES_DEL_NIVEL_1 = 10


def valor_del_nivel(n: int, inicial: int) -> int:
    if n < 1:
        raise ValueError("los niveles empiezan en 1")
    valor = inicial
    for _ in range(1, n):
        valor += valor // 2
    return valor


def nivel_de_obra(indice: int) -> int:
    """Nivel (desde 1) de la obra en la posición `indice` (desde 0) del recorrido."""
    nivel, hasta = 1, valor_del_nivel(1, OBRAS_DEL_NIVEL_1)
    while indice >= hasta:
        nivel += 1
        hasta += valor_del_nivel(nivel, OBRAS_DEL_NIVEL_1)
    return nivel


def colores_de_obra(indice: int) -> int:
    """Colores de la obra en la posición `indice` del recorrido: los de su nivel."""
    return valor_del_nivel(nivel_de_obra(indice), COLORES_DEL_NIVEL_1)


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


DIR_MUSICA = RAIZ / "assets" / "musica"


def convertir_musica() -> None:
    """Comprime arte/musica/*.mp3 a AAC 80 kbps (assets/musica/<nombre>.m4a)."""
    import subprocess

    DIR_MUSICA.mkdir(parents=True, exist_ok=True)
    for mp3 in sorted((RAIZ / "arte" / "musica").glob("*.mp3")):
        nombre = mp3.stem.lower().replace("_", "-").replace(" ", "-")
        destino = DIR_MUSICA / f"{nombre}.m4a"
        subprocess.run(
            ["ffmpeg", "-v", "error", "-y", "-i", str(mp3), "-vn", "-c:a", "aac", "-b:a", "80k",
             "-ar", "44100", str(destino)],
            check=True,
        )
        print(f"Música → {destino} ({destino.stat().st_size // 1024} KB)")


def main() -> int:
    catalogo = json.loads(CATALOGO.read_text(encoding="utf-8"))
    base = catalogo["por_defecto"]
    pedidos = set(sys.argv[1:])
    if not pedidos or "mapa" in pedidos:
        convertir_mapa(catalogo)
    if not pedidos or "musica" in pedidos:
        convertir_musica()
    for orden, c in enumerate(catalogo["cuadros"], start=1):
        if pedidos and c["id"] not in pedidos:
            continue
        p = {**base, **c}
        # En la historia, los colores salen del nivel de la obra (su lugar en el recorrido).
        p["colores"] = colores_de_obra(orden - 1)
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
