#!/usr/bin/env python3
"""
Convierte todas las imágenes de arte/ listadas en scripts/catalogo-arte.json
en cuadros (src/data/cuadros/<id>/) y regenera el índice de cuadros.

Uso: npm run arte            (todas)
     npm run arte -- <id>    (solo esas)
"""

import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import imagen_a_cuadro  # noqa: E402

RAIZ = Path(__file__).resolve().parent.parent
CATALOGO = RAIZ / "scripts" / "catalogo-arte.json"


def main() -> int:
    catalogo = json.loads(CATALOGO.read_text(encoding="utf-8"))
    base = catalogo["por_defecto"]
    pedidos = set(sys.argv[1:])
    for orden, c in enumerate(catalogo["cuadros"], start=1):
        if pedidos and c["id"] not in pedidos:
            continue
        p = {**base, **c}
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
            ]
        )
    subprocess.run(["node", str(RAIZ / "scripts" / "compilar-cuadros.mjs")], check=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
