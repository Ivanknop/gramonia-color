/// Biomas de Gramonia en orden de progresión (dificultad creciente: más obras
/// y más regiones por obra). Cada pieza se destapa al completar su obra; las
/// piezas sin `cuadroId` son "próximamente" (falta la obra) y no traban el
/// avance. Un cuadro destapa como máximo una pieza (test/datos_test.dart).
///
/// Las obras de cada bioma van de menos a más regiones.
library;

import '../engine/progresion.dart';

/// Piezas "próximamente" numeradas: `_proximamente('ciudad', 2, desde: 2)` → ciudad-2, ciudad-3.
List<Pieza> _proximamente(String bioma, int cantidad, {int desde = 1}) => [
  for (var i = 0; i < cantidad; i++) Pieza(id: '$bioma-${desde + i}'),
];

final biomas = <Bioma>[
  Bioma(
    id: 'arbol-magico',
    nombre: 'Árbol Mágico',
    descripcion:
        'El corazón de Gramonia: sus raíces son el suelo de la isla y su copa es el cielo.',
    color: 0xFF7FB8D9,
    piezas: const [
      Pieza(id: 'nido', cuadroId: 'nido-de-rocanon'),
      Pieza(id: 'hormiguero', cuadroId: 'hormiguero-del-arbol'),
      Pieza(id: 'copa', cuadroId: 'arbol-magico-de-noche'),
      Pieza(id: 'cumpleanos', cuadroId: 'cumple-del-rocanon'),
    ],
  ),
  Bioma(
    id: 'bosque-magico',
    nombre: 'Bosque Mágico',
    descripcion:
        'Rodea al Árbol y parece igual mires hacia donde mires. Lo cuidan las Hormiguitas.',
    color: 0xFF2E7D32,
    piezas: [
      const Pieza(id: 'casa-de-la-abuelita', cuadroId: 'casa-de-la-abuelita'),
      const Pieza(id: 'refugio', cuadroId: 'refugio-de-papa'),
      // Pozo Sanador en el Bosque Mágico: (a confirmar) en el canon.
      const Pieza(id: 'pozo-sanador', cuadroId: 'pozo-sanador'),
      const Pieza(id: 'caminos', cuadroId: 'todos-los-caminos'),
    ],
  ),
  Bioma(
    id: 'ciudad',
    nombre: 'La Ciudad',
    descripcion: 'Edificios brillantes, trenes velocísimos y dos mil personas yendo y viniendo.',
    color: 0xFFB0855A,
    piezas: [
      const Pieza(id: 'tienda', cuadroId: 'la-tienda'),
      ..._proximamente('ciudad', 3, desde: 2),
    ],
  ),
  Bioma(
    id: 'reino-animal',
    nombre: 'Reino Animal',
    descripcion:
        'La gran ciudad de los animales: el correo de León, la tienda de Vaca y mucho queso.',
    color: 0xFFE0A13B,
    piezas: [
      const Pieza(id: 'granero-de-cleo', cuadroId: 'cleo-quiere-dormir'),
      ..._proximamente('reino-animal', 3, desde: 2),
    ],
  ),
  Bioma(
    id: 'montana-dragon',
    nombre: 'Montaña Dragón',
    descripcion: 'La más alta de Gramonia después del Árbol: cuevas tibias, gemas y dragones.',
    color: 0xFF7E57C2,
    piezas: [
      const Pieza(id: 'cumbre', cuadroId: 'montana-de-los-dragones'),
      ..._proximamente('montana-dragon', 3, desde: 2),
    ],
  ),
  Bioma(
    id: 'prado-de-las-hadas',
    nombre: 'Prado de las Hadas',
    descripcion: 'Flores, capullos y mariposas: acá las Hadas practican sus poderes.',
    color: 0xFFF48FB1,
    piezas: _proximamente('prado-de-las-hadas', 5),
  ),
  Bioma(
    id: 'tierra-de-las-caperucitas',
    nombre: 'Tierra de las Caperucitas',
    descripcion:
        'Caperuzas de todos los colores, a rayas, con lunares… y una que cambia con "panqueque".',
    color: 0xFFE53935,
    piezas: [
      const Pieza(id: 'timoteo', cuadroId: 'timoteo-y-su-caperuza'),
      ..._proximamente('tierra-de-las-caperucitas', 4, desde: 2),
    ],
  ),
  Bioma(
    id: 'reino-helado',
    nombre: 'Reino Helado',
    descripcion: 'Nieve, frío y el mejor helado de menta granizada de toda la isla.',
    color: 0xFF81D4FA,
    piezas: _proximamente('reino-helado', 6),
  ),
  Bioma(
    id: 'costa',
    nombre: 'La Costa',
    descripcion: 'Playas, muelles y SirenHadas que juntan caracolas. Más allá, el mar.',
    color: 0xFF1E88E5,
    piezas: [
      const Pieza(id: 'puerto', cuadroId: 'puerto-en-la-tormenta'),
      const Pieza(id: 'muelle', cuadroId: 'barco-en-el-muelle'),
      const Pieza(id: 'horizonte', cuadroId: 'rumbo-a-la-isla'),
      // La Caperucita pirata: (a confirmar) en el canon.
      const Pieza(id: 'caperucita-pirata', cuadroId: 'caperucita-pirata'),
      ..._proximamente('costa', 2, desde: 5),
    ],
  ),
  for (final (i, (id, nombre, color)) in const [
    ('isla-roja', 'Isla Roja', 0xFFE53935),
    ('isla-naranja', 'Isla Naranja', 0xFFFB8C00),
    ('isla-amarilla', 'Isla Amarilla', 0xFFFDD835),
    ('isla-verde', 'Isla Verde', 0xFF43A047),
    ('isla-azul', 'Isla Azul', 0xFF1E88E5),
    ('isla-anil', 'Isla Añil', 0xFF3949AB),
    ('isla-morada', 'Isla Morada', 0xFF8E24AA),
  ].indexed)
    Bioma(
      id: id,
      nombre: nombre,
      descripcion: 'Una de las siete Islas Arcoíris, hogar de duendecitos de su mismo color.',
      color: color,
      tipo: TipoBioma.isla,
      // De 6 a 9 obras: la dificultad sigue creciendo isla por isla.
      piezas: _proximamente(id, 6 + i ~/ 2),
    ),
];
