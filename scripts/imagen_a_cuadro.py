#!/usr/bin/env python3
"""
Convierte una imagen en un cuadro pintable por números (primera versión).

Genera src/data/cuadros/<id>/cuadro.svg y cuadro.json con el formato que
espera el motor (ver docs/formato-cuadros.md). Después hay que correr
`npm run cuadros` y asignar el cuadro a una pieza en src/data/biomas.

Pasos:
  1. Reducir la imagen a una grilla chica (--ancho px de lado mayor).
  2. Cuantizar a N colores (--colores) con median cut.
  3. Suavizar con un filtro de moda para quitar ruido.
  4. Separar regiones conexas por color (4-conectividad).
  5. Fusionar regiones chicas (--area-minima px) con su vecina de mayor borde.
  6. Trazar el contorno de cada región sobre la grilla de píxeles y
     simplificarlo (Douglas-Peucker, --tolerancia).
  7. Ubicar el número en el píxel más alejado del borde (transformada de
     distancia) y escribirlo como data-etiqueta.

Limitaciones conocidas (v1):
  - Los bordes se simplifican por región, así que entre regiones vecinas
    puede haber diferencias de fracciones de píxel (las tapa el trazo).
  - Los contornos son poligonales (sin curvas).
  - Los nombres de los colores son genéricos ("Color 3"): conviene editarlos.

Uso:
  python3 scripts/imagen_a_cuadro.py foto.jpg --id mi-cuadro --titulo "Mi cuadro" \\
      --categoria paisaje --colores 8
Requiere: Pillow, numpy, scipy (incluidos en el devcontainer).
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

RAIZ = Path(__file__).resolve().parent.parent
DIR_CUADROS = RAIZ / "src" / "data" / "cuadros"
LADO_VIEWBOX = 300  # lado mayor del viewBox, igual que los cuadros hechos a mano
CATEGORIAS = ["paisaje", "animal", "objeto", "persona", "arte"]


# --------------------------------------------------------------------------
# 1-3. Reducción, cuantización y suavizado
# --------------------------------------------------------------------------


def cuantizar(ruta: Path, ancho: int, colores: int, suavizado: int) -> tuple[np.ndarray, np.ndarray]:
    """Devuelve (índices por píxel [alto, ancho], paleta RGB [n, 3])."""
    img = Image.open(ruta).convert("RGB")
    escala = ancho / max(img.size)
    tam = (max(1, round(img.width * escala)), max(1, round(img.height * escala)))
    img = img.resize(tam, Image.Resampling.LANCZOS)
    q = img.quantize(colors=colores, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    for _ in range(suavizado):
        q = q.filter(ImageFilter.ModeFilter(3))
    indices = np.array(q, dtype=np.int32)
    paleta = np.array(q.getpalette()[: 3 * colores], dtype=np.int32).reshape(-1, 3)
    return indices, paleta


# --------------------------------------------------------------------------
# 4-5. Regiones conexas y fusión de las chicas
# --------------------------------------------------------------------------


def etiquetar_regiones(indices: np.ndarray) -> tuple[np.ndarray, dict[int, int]]:
    """Etiqueta regiones conexas. Devuelve (etiquetas, color de cada etiqueta)."""
    etiquetas = np.zeros(indices.shape, dtype=np.int32)
    color_de: dict[int, int] = {}
    siguiente = 1
    for c in np.unique(indices):
        lab, n = ndimage.label(indices == c)  # 4-conectividad por defecto
        mascara = lab > 0
        etiquetas[mascara] = lab[mascara] + (siguiente - 1)
        for i in range(n):
            color_de[siguiente + i] = int(c)
        siguiente += n
    return etiquetas, color_de


def vecinos_por_borde(etiquetas: np.ndarray, region: int) -> dict[int, int]:
    """Cuenta cuántos lados de píxel comparte la región con cada vecina."""
    m = etiquetas == region
    conteo: dict[int, int] = {}
    for desplazado, mascara_borde in (
        (etiquetas[1:, :], m[:-1, :]),
        (etiquetas[:-1, :], m[1:, :]),
        (etiquetas[:, 1:], m[:, :-1]),
        (etiquetas[:, :-1], m[:, 1:]),
    ):
        vals = desplazado[mascara_borde]
        for v, k in zip(*np.unique(vals[vals != region], return_counts=True)):
            conteo[int(v)] = conteo.get(int(v), 0) + int(k)
    return conteo


def fusionar_chicas(etiquetas: np.ndarray, color_de: dict[int, int], area_minima: int) -> None:
    """Absorbe cada región menor a area_minima en la vecina con más borde compartido."""
    while True:
        ids, areas = np.unique(etiquetas, return_counts=True)
        chicas = [(a, i) for i, a in zip(ids, areas) if a < area_minima]
        if not chicas:
            return
        _, region = min(chicas)
        vecinos = vecinos_por_borde(etiquetas, int(region))
        if not vecinos:  # la imagen entera es una sola región
            return
        destino = max(vecinos, key=vecinos.get)
        etiquetas[etiquetas == region] = destino
        del color_de[int(region)]


# --------------------------------------------------------------------------
# 6. Trazado de contornos
# --------------------------------------------------------------------------


def trazar_contornos(mascara: np.ndarray) -> list[list[tuple[int, int]]]:
    """
    Contornos de una máscara sobre la grilla de esquinas de píxel.

    Cada píxel aporta sus 4 lados en sentido horario (y hacia abajo); los
    lados compartidos por dos píxeles de la máscara se cancelan. Lo que queda
    forma lazos cerrados: los externos en sentido horario y los agujeros en
    antihorario (la regla evenodd del motor los resuelve igual).
    """
    alto, ancho = mascara.shape
    p = np.pad(mascara, 1)
    salidas: dict[tuple[int, int], list[tuple[int, int]]] = {}

    def agregar(a: tuple[int, int], b: tuple[int, int]) -> None:
        salidas.setdefault(a, []).append(b)

    ys, xs = np.nonzero(mascara)
    for y, x in zip(ys.tolist(), xs.tolist()):
        py, px = y + 1, x + 1
        if not p[py - 1, px]:
            agregar((x, y), (x + 1, y))  # arriba →
        if not p[py, px + 1]:
            agregar((x + 1, y), (x + 1, y + 1))  # derecha ↓
        if not p[py + 1, px]:
            agregar((x + 1, y + 1), (x, y + 1))  # abajo ←
        if not p[py, px - 1]:
            agregar((x, y + 1), (x, y))  # izquierda ↑

    lazos: list[list[tuple[int, int]]] = []
    while salidas:
        inicio = next(iter(salidas))
        lazo = [inicio]
        actual = inicio
        direccion = None
        while True:
            opciones = salidas[actual]
            if len(opciones) == 1 or direccion is None:
                siguiente = opciones[0]
            else:
                # Vértice donde dos píxeles se tocan solo en diagonal: girar a la
                # derecha mantiene separadas las regiones (4-conectividad).
                dx, dy = direccion
                preferencias = [(-dy, dx), (dx, dy), (dy, -dx)]
                siguiente = next(
                    o
                    for pref in preferencias
                    for o in opciones
                    if (o[0] - actual[0], o[1] - actual[1]) == pref
                )
            opciones.remove(siguiente)
            if not opciones:
                del salidas[actual]
            direccion = (siguiente[0] - actual[0], siguiente[1] - actual[1])
            actual = siguiente
            # Al volver al inicio se cierra el lazo. Si el contorno pasa dos
            # veces por ese vértice (pellizco diagonal), queda partido en dos
            # lazos que comparten un vértice: con evenodd se rellena igual.
            if actual == inicio:
                break
            lazo.append(actual)
        lazos.append(lazo)
    return lazos


def quitar_colineales(lazo: list[tuple[float, float]]) -> list[tuple[float, float]]:
    resultado = []
    n = len(lazo)
    for i in range(n):
        a, b, c = lazo[i - 1], lazo[i], lazo[(i + 1) % n]
        if (b[0] - a[0]) * (c[1] - b[1]) != (b[1] - a[1]) * (c[0] - b[0]):
            resultado.append(b)
    return resultado


def douglas_peucker(puntos: list[tuple[float, float]], tolerancia: float) -> list[tuple[float, float]]:
    if len(puntos) < 3 or tolerancia <= 0:
        return puntos
    a, b = np.array(puntos[0], float), np.array(puntos[-1], float)
    ab = b - a
    largo = np.hypot(*ab)
    mejor, idx = 0.0, 0
    for i in range(1, len(puntos) - 1):
        p = np.array(puntos[i], float)
        d = abs(ab[0] * (a[1] - p[1]) - ab[1] * (a[0] - p[0])) / largo if largo else np.hypot(*(p - a))
        if d > mejor:
            mejor, idx = d, i
    if mejor <= tolerancia:
        return [puntos[0], puntos[-1]]
    izq = douglas_peucker(puntos[: idx + 1], tolerancia)
    der = douglas_peucker(puntos[idx:], tolerancia)
    return izq[:-1] + der


def simplificar_lazo(lazo: list[tuple[int, int]], tolerancia: float) -> list[tuple[float, float]]:
    pts = quitar_colineales([(float(x), float(y)) for x, y in lazo])
    if len(pts) <= 4 or tolerancia <= 0:
        return pts
    # Douglas-Peucker sobre un lazo cerrado: partir en el punto más lejano al primero.
    lejano = max(range(len(pts)), key=lambda i: (pts[i][0] - pts[0][0]) ** 2 + (pts[i][1] - pts[0][1]) ** 2)
    mitad1 = douglas_peucker(pts[: lejano + 1], tolerancia)
    mitad2 = douglas_peucker(pts[lejano:] + [pts[0]], tolerancia)
    simplificado = mitad1[:-1] + mitad2[:-1]
    return simplificado if len(simplificado) >= 3 else pts


def path_d(lazos: list[list[tuple[float, float]]], escala: float) -> str:
    def f(v: float) -> str:
        return f"{v * escala:.2f}".rstrip("0").rstrip(".")

    partes = []
    for lazo in lazos:
        x0, y0 = lazo[0]
        segmentos = " ".join(f"L{f(x)} {f(y)}" for x, y in lazo[1:])
        partes.append(f"M{f(x0)} {f(y0)} {segmentos} Z")
    return " ".join(partes)


# --------------------------------------------------------------------------
# Armado del cuadro
# --------------------------------------------------------------------------


def a_hex(rgb: np.ndarray) -> str:
    return "#{:02X}{:02X}{:02X}".format(*[int(v) for v in rgb])


def convertir(args: argparse.Namespace) -> Path:
    indices, paleta = cuantizar(args.imagen, args.ancho, args.colores, args.suavizado)
    etiquetas, color_de = etiquetar_regiones(indices)
    fusionar_chicas(etiquetas, color_de, args.area_minima)

    alto, ancho = etiquetas.shape
    escala = LADO_VIEWBOX / max(alto, ancho)

    ids, areas = np.unique(etiquetas, return_counts=True)
    # Numerar los colores por superficie total (el 1 es el que más aparece).
    area_por_color: dict[int, int] = {}
    for i, a in zip(ids.tolist(), areas.tolist()):
        area_por_color[color_de[i]] = area_por_color.get(color_de[i], 0) + a
    orden_colores = sorted(area_por_color, key=area_por_color.get, reverse=True)
    numero_de = {c: n + 1 for n, c in enumerate(orden_colores)}

    paths = []
    for k, (region, _area) in enumerate(sorted(zip(ids.tolist(), areas.tolist()), key=lambda t: -t[1])):
        mascara = etiquetas == region
        lazos = [simplificar_lazo(l, args.tolerancia) for l in trazar_contornos(mascara)]
        distancia = ndimage.distance_transform_edt(np.pad(mascara, 1))[1:-1, 1:-1]
        ey, ex = np.unravel_index(int(np.argmax(distancia)), distancia.shape)
        etiqueta = f"{(ex + 0.5) * escala:.1f} {(ey + 0.5) * escala:.1f}"
        paths.append(
            f'  <path id="r{k + 1}" data-numero="{numero_de[color_de[region]]}" '
            f'data-etiqueta="{etiqueta}" d="{path_d(lazos, escala)}" />'
        )

    destino = DIR_CUADROS / args.id
    destino.mkdir(parents=True, exist_ok=True)
    vb = f"0 0 {ancho * escala:.0f} {alto * escala:.0f}"
    (destino / "cuadro.svg").write_text(
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{vb}" fill="#eeeeee" '
        f'fill-rule="evenodd" stroke="#333333" stroke-width="0.8">\n' + "\n".join(paths) + "\n</svg>\n",
        encoding="utf-8",
    )

    cantidad = len(paths)
    meta = {
        "id": args.id,
        "titulo": args.titulo,
        "categoria": args.categoria,
        "dificultad": int(min(5, max(1, round(cantidad / 40) + 1))),
        "paleta": [
            {"numero": numero_de[c], "nombre": f"Color {numero_de[c]}", "hex": a_hex(paleta[c])}
            for c in orden_colores
        ],
        "mensajeMututu": args.mensaje,
    }
    (destino / "cuadro.json").write_text(json.dumps(meta, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Cuadro '{args.id}': {cantidad} regiones, {len(orden_colores)} colores → {destino.relative_to(RAIZ)}")
    print("Siguiente paso: `npm run cuadros` y asignarle una pieza en src/data/biomas/index.ts.")
    return destino


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Convierte una imagen en un cuadro pintable por números.")
    ap.add_argument("imagen", type=Path)
    ap.add_argument("--id", required=True, help="id del cuadro (minúsculas y guiones)")
    ap.add_argument("--titulo", required=True)
    ap.add_argument("--categoria", choices=CATEGORIAS, default="arte")
    ap.add_argument("--colores", type=int, default=8, help="cantidad de colores de la paleta")
    ap.add_argument("--ancho", type=int, default=96, help="lado mayor de la grilla de trabajo (px)")
    ap.add_argument("--area-minima", type=int, default=12, help="área mínima de una región (px de la grilla)")
    ap.add_argument("--suavizado", type=int, default=2, help="pasadas del filtro de moda")
    ap.add_argument("--tolerancia", type=float, default=0.6, help="tolerancia de simplificación (px)")
    ap.add_argument(
        "--mensaje",
        default="¡Los colores volvieron! Mututu tendrá que buscar otro cuadro para esconderse.",
        help="mensaje al completar",
    )
    args = ap.parse_args(argv)
    if not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", args.id):
        ap.error("--id debe ser minúsculas, números y guiones (ej: gato-en-la-ventana)")
    if not 2 <= args.colores <= 24:
        ap.error("--colores debe estar entre 2 y 24")
    convertir(args)
    return 0


if __name__ == "__main__":
    sys.exit(main())
