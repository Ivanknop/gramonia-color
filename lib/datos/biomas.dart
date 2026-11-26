/// Lugares de Gramonia en el orden del recorrido, con su nivel. Las piezas sin `cuadroId` son
/// "próximamente".
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
    nivel: 1,
    piezas: const [
      Pieza(id: 'nido', cuadroId: 'nido-de-rocanon'),
      Pieza(id: 'copa', cuadroId: 'arbol-magico-de-noche'),
      Pieza(id: 'rocanon', cuadroId: 'rocanon-en-la-copa'),
    ],
  ),
  Bioma(
    id: 'bosque-magico',
    nombre: 'Bosque Mágico',
    descripcion:
        'Rodea al Árbol y parece igual mires hacia donde mires. Lo cuidan las Hormiguitas.',
    color: 0xFF2E7D32,
    nivel: 2,
    piezas: [
      const Pieza(id: 'hormiguero', cuadroId: 'hormiguero-del-arbol'),
      const Pieza(id: 'cumpleanos', cuadroId: 'cumple-del-rocanon'),
      // Pozo Sanador en el Bosque Mágico: (a confirmar) en el canon.
      const Pieza(id: 'pozo-sanador', cuadroId: 'pozo-sanador'),
      const Pieza(id: 'caminos', cuadroId: 'todos-los-caminos'),
    ],
  ),
  Bioma(
    id: 'reino-animal',
    nombre: 'Reino Animal',
    descripcion:
        'La gran ciudad de los animales: el correo de León, la tienda de Vaca y mucho queso.',
    color: 0xFFE0A13B,
    nivel: 3,
    piezas: [
      const Pieza(id: 'correo-de-leon', cuadroId: 'leon-y-kiribiki'),
      const Pieza(id: 'granero-de-cleo', cuadroId: 'cleo-quiere-dormir'),
      // Mercado nocturno en el Reino Animal: (a confirmar) en el canon.
      const Pieza(id: 'mercado-nocturno', cuadroId: 'mercado-nocturno'),
      // El Oso, vecino del Reino Animal (canon: "León y el queso").
      const Pieza(id: 'biblioteca', cuadroId: 'el-oso-en-la-biblioteca'),
      const Pieza(id: 'granja', cuadroId: 'la-granja'),
    ],
  ),
  Bioma(
    id: 'tierra-de-las-caperucitas',
    nombre: 'Tierra de las Caperucitas',
    femenino: true,
    descripcion:
        'Caperuzas de todos los colores, a rayas, con lunares… y una que cambia con "panqueque".',
    color: 0xFFE53935,
    nivel: 4,
    piezas: [
      const Pieza(id: 'casa-de-la-abuelita', cuadroId: 'casa-de-la-abuelita'),
      const Pieza(id: 'timoteo', cuadroId: 'timoteo-y-su-caperuza'),
      const Pieza(id: 'ronda', cuadroId: 'ronda-de-caperucitas'),
      const Pieza(id: 'elefantito', cuadroId: 'el-elefantito-caperucito'),
    ],
  ),
  Bioma(
    id: 'prado-de-las-hadas',
    nombre: 'Prado de las Hadas',
    descripcion: 'Flores, capullos y mariposas: acá las Hadas practican sus poderes.',
    color: 0xFFF48FB1,
    nivel: 4,
    piezas: [
      const Pieza(id: 'prado', cuadroId: 'el-prado-de-las-hadas'),
      const Pieza(id: 'hada-madrina', cuadroId: 'el-hada-madrina'),
      const Pieza(id: 'haditas', cuadroId: 'las-haditas-practican'),
    ],
  ),
  Bioma(
    id: 'montana-dragon',
    nombre: 'Montaña Dragón',
    femenino: true,
    descripcion: 'La más alta de Gramonia después del Árbol: cuevas tibias, gemas y dragones.',
    color: 0xFF7E57C2,
    nivel: 5,
    piezas: [
      const Pieza(id: 'cumbre', cuadroId: 'montana-de-los-dragones'),
      // Alma vive en la Montaña Dragón ("Reino Dragón").
      const Pieza(id: 'alma', cuadroId: 'alma-y-sus-alas'),
      const Pieza(id: 'entre-nubes', cuadroId: 'montana-entre-nubes'),
      const Pieza(id: 'futbol', cuadroId: 'futbol-de-dragones'),
      const Pieza(id: 'tormenta', cuadroId: 'dragones-en-la-tormenta'),
    ],
  ),
  Bioma(
    id: 'reino-helado',
    nombre: 'Reino Helado',
    descripcion: 'Nieve, frío y el mejor helado de menta granizada de toda la isla.',
    color: 0xFF81D4FA,
    nivel: 5,
    piezas: [
      const Pieza(id: 'heladeria', cuadroId: 'la-heladeria'),
      const Pieza(id: 'gema-helada', cuadroId: 'la-gema-helada'),
    ],
  ),
  Bioma(
    id: 'ciudad',
    nombre: 'La Ciudad',
    descripcion: 'Edificios brillantes, trenes velocísimos y dos mil personas yendo y viniendo.',
    color: 0xFFB0855A,
    nivel: 6,
    piezas: [
      const Pieza(id: 'tienda', cuadroId: 'la-tienda'),
      const Pieza(id: 'plaza-de-juegos', cuadroId: 'la-plaza-de-juegos'),
      const Pieza(id: 'vista', cuadroId: 'la-ciudad-desde-lo-alto'),
      // Papá vive en la Ciudad (canon).
      const Pieza(id: 'refugio', cuadroId: 'refugio-de-papa'),
    ],
  ),
  Bioma(
    id: 'costa',
    nombre: 'La Costa',
    descripcion: 'Playas, muelles y SirenHadas que juntan caracolas. Más allá, el mar.',
    color: 0xFF1E88E5,
    nivel: 6,
    piezas: [
      const Pieza(id: 'puerto', cuadroId: 'puerto-en-la-tormenta'),
      const Pieza(id: 'muelle', cuadroId: 'barco-en-el-muelle'),
      const Pieza(id: 'horizonte', cuadroId: 'rumbo-a-la-isla'),
      // La Caperucita pirata: (a confirmar) en el canon.
      const Pieza(id: 'caperucita-pirata', cuadroId: 'caperucita-pirata'),
      const Pieza(id: 'sirenhadas', cuadroId: 'sirenhadas'),
      const Pieza(id: 'caracolas', cuadroId: 'caracolas-en-la-playa'),
    ],
  ),
  for (final (id, nombre, color) in const [
    ('isla-roja', 'Isla Roja', 0xFFE53935),
    ('isla-naranja', 'Isla Naranja', 0xFFFB8C00),
    ('isla-amarilla', 'Isla Amarilla', 0xFFFDD835),
    ('isla-verde', 'Isla Verde', 0xFF43A047),
    ('isla-celeste', 'Isla Celeste', 0xFF4FC3F7),
    ('isla-azul', 'Isla Azul', 0xFF1E88E5),
    ('isla-violeta', 'Isla Violeta', 0xFF8E24AA),
  ])
    Bioma(
      id: id,
      nombre: nombre,
      descripcion: 'Una de las siete Islas Arcoíris, hogar de duendecitos de su mismo color.',
      color: color,
      nivel: 7,
      tipo: TipoBioma.isla,
      femenino: true,
      // Un solo nivel ("Islas Arcoíris") con una obra por isla: en el mapa
      // se van coloreando de a una.
      piezas: [Pieza(id: '$id-1', cuadroId: obrasDeIslas[id])],
    ),
  Bioma(
    id: 'isla-negra',
    nombre: 'Isla Negra',
    femenino: true,
    descripcion: 'Lejos, más allá de las Islas Arcoíris. Ahí dormía Mututu.',
    color: 0xFF3A3442,
    nivel: 8,
    tipo: TipoBioma.isla,
    // Tres obras, las más difíciles: el nivel 8 tiene la mayor cantidad de colores.
    piezas: _proximamente('isla-negra', 3),
  ),
];

/// La obra de cada isla (las que todavía no tienen, "próximamente").
const obrasDeIslas = <String, String>{
  'isla-roja': 'lobitos-de-la-isla-roja',
  'isla-naranja': 'minas-de-la-isla-naranja',
  'isla-amarilla': 'baile-en-la-isla-amarilla',
  'isla-verde': 'desierto-de-la-isla-verde',
  'isla-celeste': 'selva-de-la-isla-celeste',
  'isla-azul': 'llegada-a-la-isla-azul',
  'isla-violeta': 'sirenhadas-de-la-isla-violeta',
};

const nombresDeNivel = <int, String>{7: 'Islas Arcoíris'};
