#!/usr/bin/env python3
"""
Convierte todas las imágenes de arte/ listadas en scripts/catalogo-arte.json
en cuadros (assets/cuadros/<id>.svg + <id>.json) y en sus variantes de
dificultad (assets/variantes/<id>--<dificultad>.svg + .json, según
assets/dificultades.json; usan la ilustración del cuadro).

Si el original ya no está en arte/ (se borra para liberar espacio), se usa la
ilustración del cuadro (assets/cuadros/<id>.webp): alcanza para la grilla del
conversor.

Uso: python3 scripts/convertir_arte.py          (todo: cuadros, variantes, mapa y música)
     python3 scripts/convertir_arte.py <id> ... (solo esos cuadros, con sus variantes;
                                                 "mapa", "musica" o "variantes" = las de todos;
                                                 --sin-variantes: solo los cuadros)
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
# valores en los tests): colores(n) = colores(n-1) + colores(n-1) // 2, con el
# nivel 1 en 10. El nivel de cada obra va en catalogo-arte.json.
COLORES_DEL_NIVEL_1 = 10


def valor_del_nivel(n: int, inicial: int) -> int:
    if n < 1:
        raise ValueError("los niveles con obras empiezan en 1")
    valor = inicial
    for _ in range(1, n):
        valor += valor // 2
    return valor


def colores_del_nivel(nivel: int) -> int:
    """Colores de cada obra del nivel `nivel`."""
    return valor_del_nivel(nivel, COLORES_DEL_NIVEL_1)


DIR_CUADROS = RAIZ / "assets" / "cuadros"
DIR_VARIANTES = RAIZ / "assets" / "variantes"
DIFICULTADES = RAIZ / "assets" / "dificultades.json"


def ancho_para(regiones: int) -> int:
    """Grilla de trabajo según la cantidad de regiones buscada (más regiones, más detalle)."""
    if regiones <= 120:
        return 120
    if regiones <= 250:
        return 170
    if regiones <= 450:
        return 220
    return 260


def fuente(c: dict) -> Path:
    """
    Imagen de origen: el original de arte/ o, si ya se borró, la ilustración
    del cuadro (o la del cuadro `desde`, si la toma prestada, como el tutorial).
    """
    original = RAIZ / "arte" / c["imagen"]
    if original.exists():
        return original
    ilustracion = RAIZ / "assets" / "cuadros" / f"{c.get('desde', c['id'])}.webp"
    if ilustracion.exists():
        return ilustracion
    raise FileNotFoundError(f"No está {original} ni {ilustracion}")


def id_variante(cuadro_id: str, dificultad_id: str) -> str:
    return f"{cuadro_id}--{dificultad_id}"


def leer_dificultades() -> list[dict]:
    return json.loads(DIFICULTADES.read_text(encoding="utf-8"))["dificultades"]


def argumentos(p: dict, imagen: Path, id_: str, colores: int, regiones: int) -> list[str]:
    """Argumentos del conversor (sin --ancho: lo pone convertir_con_objetivo)."""
    return [
        str(imagen),
        "--id", id_,
        "--titulo", p["titulo"],
        "--categoria", p["categoria"],
        "--mensaje", p["mensaje"],
        "--colores", str(colores),
        "--area-minima", str(p["area_minima"]),
        "--suavizado", str(p["suavizado"]),
        "--tolerancia", str(p["tolerancia"]),
        "--curvas", str(p["curvas"]),
        "--regiones", str(regiones),
    ]


def regiones_de(svg: Path) -> int:
    return svg.read_text(encoding="utf-8").count("<path ")


def convertir_con_objetivo(argv: list[str], regiones: int, ancho: int, carpeta: Path, id_: str) -> None:
    """
    Convierte y, si la imagen tiene poco detalle (mucho fondo liso) y no llega
    al 90 % de las regiones buscadas, reintenta con una grilla más fina.
    """
    for _ in range(4):
        imagen_a_cuadro.main(argv + ["--ancho", str(ancho)])
        if regiones_de(carpeta / f"{id_}.svg") >= 0.9 * regiones:
            return
        ancho = round(ancho * 1.35)
        print(f"  {id_}: pocas regiones, otra vez con grilla de {ancho}")


def convertir_variantes(p: dict) -> None:
    """
    Una variante por dificultad, con sus colores exactos y su objetivo de regiones.
    Con pocos colores hay menos regiones naturales: la grilla es la de un objetivo
    del doble, para que alcancen.
    """
    imagen = fuente(p)
    for d in leer_dificultades():
        id_ = id_variante(p["id"], d["id"])
        argv = argumentos(p, imagen, id_, d["colores"], d["regiones"])
        argv += ["--carpeta", str(DIR_VARIANTES), "--sin-ilustracion"]
        convertir_con_objetivo(argv, d["regiones"], ancho_para(d["regiones"] * 2), DIR_VARIANTES, id_)


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


def convertir_cuadro(p: dict, colores: int, orden: int) -> None:
    """Un cuadro de la historia (o el tutorial) con sus colores exactos."""
    imagen = fuente(p)
    argv = argumentos(p, imagen, p["id"], colores, p["regiones"])
    argv += ["--orden", str(orden)]
    # Si la fuente ya es la ilustración del cuadro, no se reescribe
    # (se volvería a comprimir con pérdida).
    if imagen == DIR_CUADROS / f"{p['id']}.webp":
        argv.append("--sin-ilustracion")
    ancho = p.get("ancho") or ancho_para(p["regiones"])
    convertir_con_objetivo(argv, p["regiones"], ancho, DIR_CUADROS, p["id"])


def main() -> int:
    catalogo = json.loads(CATALOGO.read_text(encoding="utf-8"))
    base = catalogo["por_defecto"]
    sin_variantes = "--sin-variantes" in sys.argv[1:]
    pedidos = {a for a in sys.argv[1:] if a != "--sin-variantes"}
    if not pedidos or "mapa" in pedidos:
        convertir_mapa(catalogo)
    if not pedidos or "musica" in pedidos:
        convertir_musica()
    if not pedidos or "tutorial" in pedidos:
        # El tutorial va primero en el catálogo (orden 0) y no tiene variantes.
        t = {**base, **catalogo["tutorial"]}
        convertir_cuadro(t, t["colores"], 0)
    todas_las_variantes = not pedidos or "variantes" in pedidos
    for orden, c in enumerate(catalogo["cuadros"], start=1):
        p = {**base, **c}
        if not pedidos or c["id"] in pedidos:
            # En la historia, los colores salen del nivel de la obra; los de
            # solo modo libre traen los suyos (se juegan en las variantes).
            colores = p["colores"] if p.get("solo_libre") else colores_del_nivel(p["nivel"])
            convertir_cuadro(p, colores, orden)
        if todas_las_variantes or (c["id"] in pedidos and not sin_variantes):
            convertir_variantes(p)
    print("Listo. Si hay cuadros nuevos, asignales una pieza en lib/datos/biomas.dart.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
