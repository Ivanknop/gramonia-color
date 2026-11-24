"""Tests de los niveles del conversor (mismos valores que test/engine/niveles_test.dart)."""

import sys
import unittest
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from convertir_arte import (  # noqa: E402
    COLORES_DEL_NIVEL_1,
    OBRAS_DEL_NIVEL_1,
    RAIZ,
    colores_de_obra,
    fuente,
    id_variante,
    leer_dificultades,
    nivel_de_obra,
    valor_del_nivel,
)
from imagen_a_cuadro import etiquetar_regiones, fusionar_chicas, juntar_colores  # noqa: E402


class TestNiveles(unittest.TestCase):
    def test_primeros_niveles(self):
        self.assertEqual([valor_del_nivel(n, OBRAS_DEL_NIVEL_1) for n in range(1, 6)], [2, 3, 4, 6, 9])
        self.assertEqual([valor_del_nivel(n, COLORES_DEL_NIVEL_1) for n in range(1, 6)], [10, 15, 22, 33, 49])

    def test_nivel_y_colores_de_cada_obra(self):
        self.assertEqual([nivel_de_obra(i) for i in range(10)], [1, 1, 2, 2, 2, 3, 3, 3, 3, 4])
        self.assertEqual([colores_de_obra(i) for i in (0, 2, 5, 9, 15)], [10, 15, 22, 33, 49])


class TestDificultades(unittest.TestCase):
    def test_tabla(self):
        tabla = leer_dificultades()
        self.assertEqual(len(tabla), 10)
        self.assertEqual(tabla[0]["id"], "super-facil")
        self.assertEqual(tabla[-1]["id"], "divino")
        for a, b in zip(tabla, tabla[1:]):
            self.assertLess(a["colores"], b["colores"])
            self.assertLess(a["regiones"], b["regiones"])

    def test_id_variante(self):
        self.assertEqual(id_variante("nido-de-rocanon", "facil"), "nido-de-rocanon--facil")

    def test_sin_original_usa_la_ilustracion_del_cuadro(self):
        c = {"imagen": "no-existe.jpeg", "id": "nido-de-rocanon"}
        self.assertEqual(fuente(c), RAIZ / "assets" / "cuadros" / "nido-de-rocanon.webp")
        with self.assertRaises(FileNotFoundError):
            fuente({"imagen": "no-existe.jpeg", "id": "tampoco"})


class TestColoresExactos(unittest.TestCase):
    def test_juntar_colores_deja_los_pedidos_y_junta_los_parecidos(self):
        indices = np.array([[0, 1, 2, 3]], dtype=np.int32)
        paleta = np.array([[0, 0, 0], [250, 0, 0], [255, 0, 0], [0, 0, 255]])
        nuevos, pal = juntar_colores(indices, paleta, 3)
        self.assertEqual(len(pal), 3)
        self.assertEqual(nuevos[0, 1], nuevos[0, 2])  # los dos rojos quedan juntos
        self.assertEqual(len(np.unique(nuevos)), 3)

    def test_juntar_colores_descarta_los_que_no_se_usan(self):
        indices = np.array([[0, 2]], dtype=np.int32)
        _, pal = juntar_colores(indices, np.array([[0, 0, 0], [9, 9, 9], [255, 255, 255]]), 5)
        self.assertEqual(len(pal), 2)

    def test_fusionar_no_pierde_colores(self):
        # Un píxel de color 1 aislado en un mar de color 0: aunque sea chico, no desaparece.
        indices = np.zeros((6, 6), dtype=np.int32)
        indices[2, 2] = 1
        indices[0:2, 4:6] = 2
        etiquetas, color_de = etiquetar_regiones(indices)
        fusionar_chicas(etiquetas, color_de, area_minima=4, objetivo=1)
        self.assertEqual(set(color_de.values()), {0, 1, 2})


if __name__ == "__main__":
    unittest.main()
