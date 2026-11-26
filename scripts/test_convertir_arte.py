"""Tests del conversor. Los datos generados los valida test/datos_test.dart."""

import json
import sys
import unittest
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from convertir_arte import (  # noqa: E402
    CATALOGO,
    RAIZ,
    colores_del_nivel,
    fuente,
    id_variante,
)
from imagen_a_cuadro import etiquetar_regiones, fusionar_chicas, juntar_colores  # noqa: E402


class TestNiveles(unittest.TestCase):
    def test_colores_de_cada_nivel(self):
        self.assertEqual(
            [colores_del_nivel(n) for n in range(1, 9)], [10, 15, 22, 33, 49, 73, 109, 163]
        )
        with self.assertRaises(ValueError):
            colores_del_nivel(0)

    def test_las_obras_van_por_nivel_y_las_de_solo_modo_libre_al_final(self):
        catalogo = json.loads(CATALOGO.read_text(encoding="utf-8"))
        historia = [c for c in catalogo["cuadros"] if not c.get("solo_libre")]
        libres = [c for c in catalogo["cuadros"] if c.get("solo_libre")]
        niveles = [c["nivel"] for c in historia]
        self.assertEqual(niveles, sorted(niveles))
        # Los de solo modo libre van al final, sin nivel y con sus colores.
        self.assertEqual(catalogo["cuadros"][len(historia):], libres)
        for c in libres:
            self.assertNotIn("nivel", c)
            self.assertIn("colores", c)


class TestVariantes(unittest.TestCase):
    def test_id_variante(self):
        self.assertEqual(id_variante("nido-de-rocanon", "facil"), "nido-de-rocanon--facil")

    def test_sin_original_usa_la_ilustracion_del_cuadro(self):
        c = {"imagen": "no-existe.jpeg", "id": "nido-de-rocanon"}
        self.assertEqual(fuente(c), RAIZ / "assets" / "cuadros" / "nido-de-rocanon.webp")
        with self.assertRaises(FileNotFoundError):
            fuente({"imagen": "no-existe.jpeg", "id": "tampoco"})

    def test_sin_original_puede_usar_la_ilustracion_de_otro_cuadro(self):
        c = {"imagen": "no-existe.jpeg", "id": "tutorial-arbol-magico", "desde": "nido-de-rocanon"}
        self.assertEqual(fuente(c), RAIZ / "assets" / "cuadros" / "nido-de-rocanon.webp")


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
