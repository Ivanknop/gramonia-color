#!/usr/bin/env python3
"""
Sintetiza el sonido del festejo (al terminar un cuadro): un arpegio de campanitas
en Do mayor que sube, con un brillo de destellos al final.

Genera assets/sonidos/festejo.m4a (AAC). Requiere numpy y ffmpeg.
Uso: python3 scripts/generar_festejo.py
"""

import subprocess
import sys
import tempfile
import wave
from pathlib import Path

import numpy as np

RAIZ = Path(__file__).resolve().parent.parent
DESTINO = RAIZ / "assets" / "sonidos" / "festejo.m4a"
MUESTREO = 44100


def campana(frecuencia: float, duracion: float) -> np.ndarray:
    """Nota de campanita: fundamental + armónicos que se apagan rápido."""
    t = np.arange(int(MUESTREO * duracion)) / MUESTREO
    onda = (
        np.sin(2 * np.pi * frecuencia * t)
        + 0.5 * np.sin(2 * np.pi * 2 * frecuencia * t) * np.exp(-t * 6)
        + 0.25 * np.sin(2 * np.pi * 3.01 * frecuencia * t) * np.exp(-t * 9)
    )
    ataque = np.minimum(1, t / 0.005)
    return onda * ataque * np.exp(-t * 4.5)


def sintetizar() -> np.ndarray:
    total = np.zeros(int(MUESTREO * 1.8))

    def sumar(senal: np.ndarray, desde: float, volumen: float) -> None:
        i = int(MUESTREO * desde)
        fin = min(len(total), i + len(senal))
        total[i:fin] += volumen * senal[: fin - i]

    # Do5, Mi5, Sol5 y Do6 (el último más largo), y un acorde final suave.
    for k, f in enumerate([523.25, 659.25, 783.99]):
        sumar(campana(f, 0.6), 0.11 * k, 0.5)
    sumar(campana(1046.5, 1.4), 0.33, 0.6)
    for f in (523.25, 659.25, 783.99):
        sumar(campana(f, 1.3), 0.33, 0.18)
    # Destellos: notas agudas cortitas al azar (semilla fija: siempre igual).
    azar = np.random.default_rng(7)
    for _ in range(9):
        f = float(azar.choice([2093.0, 2349.3, 2637.0, 3136.0]))
        sumar(campana(f, 0.25), 0.45 + float(azar.random()) * 0.9, 0.12)
    # Fundido de salida y normalización.
    total *= np.minimum(1, (len(total) - np.arange(len(total))) / (MUESTREO * 0.3))
    return total / np.abs(total).max() * 0.8


def main() -> int:
    muestras = (sintetizar() * 32767).astype(np.int16)
    DESTINO.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        wav = Path(tmp) / "festejo.wav"
        with wave.open(str(wav), "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(MUESTREO)
            w.writeframes(muestras.tobytes())
        subprocess.run(
            ["ffmpeg", "-v", "error", "-y", "-i", str(wav), "-c:a", "aac", "-b:a", "96k", str(DESTINO)],
            check=True,
        )
    print(f"Festejo → {DESTINO} ({DESTINO.stat().st_size // 1024} KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
