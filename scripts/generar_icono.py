#!/usr/bin/env python3
"""
Genera el ícono de la app Android a partir de arte/icono.jpeg (cuadrado).

- Ícono adaptativo (Android 8+): capa de fondo (color madera) + capa frontal
  con la ilustración encuadrada para que la máscara del teléfono (círculo,
  "squircle", etc.) no corte la paleta. La zona visible es el 66% central de
  la capa (72 de 108 dp); la ilustración ocupa el 78% (84 dp), así la máscara
  solo recorta el borde de madera.
- Monocromo (Android 13, íconos temáticos): silueta de una pluma del Rocanón.
- Íconos clásicos (Android 7 y anteriores): la ilustración con esquinas
  redondeadas, en cada densidad.

Uso: python3 scripts/generar_icono.py
"""

from pathlib import Path

from PIL import Image, ImageDraw

RAIZ = Path(__file__).resolve().parent.parent
ORIGEN = RAIZ / "arte" / "icono.jpeg"
RES = RAIZ / "android" / "app" / "src" / "main" / "res"

# Densidades: tamaño del ícono clásico (48 dp) y de las capas adaptativas (108 dp).
DENSIDADES = {"mdpi": 1.0, "hdpi": 1.5, "xhdpi": 2.0, "xxhdpi": 3.0, "xxxhdpi": 4.0}
FRACCION_ILUSTRACION = 84 / 108
COLOR_FONDO = "#4A3222"  # madera oscura, como el borde de la ilustración


def esquinas_redondeadas(img: Image.Image, radio: float) -> Image.Image:
    mascara = Image.new("L", img.size, 0)
    ImageDraw.Draw(mascara).rounded_rectangle([0, 0, img.width - 1, img.height - 1], radius=radio, fill=255)
    salida = img.convert("RGBA")
    salida.putalpha(mascara)
    return salida


def capa_frontal(original: Image.Image, lado: int) -> Image.Image:
    capa = Image.new("RGBA", (lado, lado), (0, 0, 0, 0))
    tam = round(lado * FRACCION_ILUSTRACION)
    ilustracion = original.resize((tam, tam), Image.Resampling.LANCZOS)
    # Bordes suaves para que no se vea el corte cuadrado si alguna máscara lo deja ver.
    ilustracion = esquinas_redondeadas(ilustracion, tam * 0.22)
    capa.paste(ilustracion, ((lado - tam) // 2, (lado - tam) // 2), ilustracion)
    return capa


def _bezier(p0, p1, p2, p3, pasos=40):
    return [
        (
            (1 - t) ** 3 * p0[0] + 3 * (1 - t) ** 2 * t * p1[0] + 3 * (1 - t) * t**2 * p2[0] + t**3 * p3[0],
            (1 - t) ** 3 * p0[1] + 3 * (1 - t) ** 2 * t * p1[1] + 3 * (1 - t) * t**2 * p2[1] + t**3 * p3[1],
        )
        for t in (i / pasos for i in range(pasos + 1))
    ]


def capa_monocromo(lado: int) -> Image.Image:
    """Silueta de una pluma (la del Rocanón), blanca sobre transparente, en la zona segura."""
    sup = 4  # se dibuja más grande y se achica: bordes suaves
    L = lado * sup
    capa = Image.new("L", (L, L), 0)
    d = ImageDraw.Draw(capa)
    tam = L * 0.46  # dentro de los 66 dp visibles, con aire
    x0, y0 = (L - tam) / 2, (L - tam) / 2

    def P(u, v):
        return (x0 + u * tam, y0 + v * tam)

    vane = _bezier(P(0.18, 0.92), P(0.10, 0.45), P(0.45, 0.08), P(0.88, 0.06))
    vane += _bezier(P(0.88, 0.06), P(0.86, 0.50), P(0.55, 0.85), P(0.18, 0.92))[1:]
    d.polygon(vane, fill=255)
    # Cañón de la pluma (hueco sobre la silueta y saliendo por abajo).
    d.line([P(0.80, 0.16), P(0.08, 0.98)], fill=0, width=int(tam * 0.035))
    d.line([P(0.22, 0.80), P(0.06, 1.0)], fill=255, width=int(tam * 0.06))
    capa = capa.resize((lado, lado), Image.Resampling.LANCZOS)
    salida = Image.new("RGBA", (lado, lado), (255, 255, 255, 0))
    salida.putalpha(capa)
    return salida


def main() -> None:
    original = Image.open(ORIGEN).convert("RGB")
    lado_original = min(original.size)
    original = original.crop((0, 0, lado_original, lado_original))

    for nombre, escala in DENSIDADES.items():
        carpeta = RES / f"mipmap-{nombre}"
        carpeta.mkdir(parents=True, exist_ok=True)
        clasico = round(48 * escala)
        icono = original.resize((clasico, clasico), Image.Resampling.LANCZOS)
        esquinas_redondeadas(icono, clasico * 0.18).save(carpeta / "ic_launcher.png")
        capa = round(108 * escala)
        capa_frontal(original, capa).save(carpeta / "ic_launcher_foreground.png")
        capa_monocromo(capa).save(carpeta / "ic_launcher_monochrome.png")

    anydpi = RES / "mipmap-anydpi-v26"
    anydpi.mkdir(parents=True, exist_ok=True)
    (anydpi / "ic_launcher.xml").write_text(
        """<?xml version="1.0" encoding="utf-8"?>
<!-- Generado por scripts/generar_icono.py a partir de arte/icono.jpeg -->
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />
</adaptive-icon>
""",
        encoding="utf-8",
    )
    valores = RES / "values"
    valores.mkdir(parents=True, exist_ok=True)
    (valores / "ic_launcher_background.xml").write_text(
        f"""<?xml version="1.0" encoding="utf-8"?>
<!-- Generado por scripts/generar_icono.py -->
<resources>
    <color name="ic_launcher_background">{COLOR_FONDO}</color>
</resources>
""",
        encoding="utf-8",
    )
    print("Ícono generado en", RES.relative_to(RAIZ))


if __name__ == "__main__":
    main()
