"""Tests del conversor. Correr con: python3 -m unittest discover -s scripts -p "test_*.py""""

import sys
import unittest
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from imagen_a_cuadro import quitar_colineales, simplificar_lazo, trazar_contornos  # noqa: E402


def area(lazo):
    """Área con signo (positiva = horario con y hacia abajo)."""
    return sum(a[0] * b[1] - b[0] * a[1] for a, b in zip(lazo, lazo[1:] + lazo[:1])) / 2


class TestContornos(unittest.TestCase):
    def test_cuadrado(self):
        m = np.zeros((4, 4), bool)
        m[1:3, 1:3] = True
        (lazo,) = trazar_contornos(m)
        self.assertEqual(sorted(quitar_colineales(lazo)), [(1, 1), (1, 3), (3, 1), (3, 3)])
        self.assertEqual(area(lazo), 4)

    def test_anillo_tiene_agujero_antihorario(self):
        m = np.ones((5, 5), bool)
        m[2, 2] = False
        lazos = trazar_contornos(m)
        self.assertEqual(sorted(area(l) for l in lazos), [-1, 25])

    def test_diagonal_no_une_pixeles(self):
        # Dos píxeles que se tocan solo por la esquina: el área total es 2.
        m = np.array([[1, 0], [0, 1]], bool)
        lazos = trazar_contornos(m)
        self.assertEqual(sum(area(l) for l in lazos), 2)

    def test_simplificar_conserva_un_poligono_valido(self):
        m = np.zeros((20, 20), bool)
        for y in range(20):
            m[y, : y + 1] = True  # triángulo escalonado
        (lazo,) = trazar_contornos(m)
        simple = simplificar_lazo(lazo, 1.0)
        self.assertLess(len(simple), len(lazo))
        self.assertGreaterEqual(len(simple), 3)
        self.assertAlmostEqual(area(simple), area(lazo), delta=25)


if __name__ == "__main__":
    unittest.main()
