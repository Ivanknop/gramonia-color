/// Biomas de Gramonia y sus piezas. Cada pieza se destapa al completar el
/// cuadro indicado en `cuadroId`; un cuadro destapa como máximo una pieza
/// (lo verifica test/datos_test.dart).
///
/// Asignación provisoria de los cuadros de prueba (arte/ + ejemplos).
library;

import '../engine/progresion.dart';

const biomas = <Bioma>[
  Bioma(
    id: 'bosque-susurrante',
    nombre: 'Bosque Susurrante',
    descripcion:
        'Árboles altísimos que se cuentan secretos con el viento. Mututu empezó su robo por acá.',
    color: 0xFF6AA84F,
    filas: 2,
    columnas: 3,
    piezas: [
      Pieza(id: 'casa-de-la-abuelita', cuadroId: 'casa-de-la-abuelita', fila: 0, columna: 0),
      Pieza(id: 'nido', cuadroId: 'nido-de-rocanon', fila: 0, columna: 1),
      Pieza(id: 'hormiguero', cuadroId: 'hormiguero-del-arbol', fila: 0, columna: 2),
      Pieza(id: 'refugio', cuadroId: 'refugio-de-papa', fila: 1, columna: 0),
      Pieza(id: 'claro', cuadroId: 'atardecer-en-el-lago', fila: 1, columna: 1),
      Pieza(id: 'casa-del-arbol', cuadroId: 'taza-de-te', fila: 1, columna: 2),
    ],
  ),
  Bioma(
    id: 'costa-de-espuma',
    nombre: 'Costa de Espuma',
    descripcion: 'Playas de arena rosada donde las olas traen botellas con mensajes.',
    color: 0xFF45818E,
    filas: 2,
    columnas: 2,
    piezas: [
      Pieza(id: 'puerto', cuadroId: 'puerto-en-la-tormenta', fila: 0, columna: 0),
      Pieza(id: 'muelle', cuadroId: 'barco-en-el-muelle', fila: 0, columna: 1),
      Pieza(id: 'horizonte', cuadroId: 'rumbo-a-la-isla', fila: 1, columna: 0),
      Pieza(id: 'arrecife', cuadroId: 'pez-naranja', fila: 1, columna: 1),
    ],
  ),
  Bioma(
    id: 'montanas-de-cristal',
    nombre: 'Montañas de Cristal',
    descripcion: 'Picos llenos de gemas donde anidan los dragones y los viajeros hacen noche.',
    color: 0xFF8E7CC3,
    filas: 1,
    columnas: 3,
    piezas: [
      Pieza(id: 'cumbre', cuadroId: 'montana-de-los-dragones', fila: 0, columna: 0),
      Pieza(id: 'tienda', cuadroId: 'la-tienda', fila: 0, columna: 1),
      Pieza(id: 'mapa', cuadroId: 'mapa-de-las-caminatas', fila: 0, columna: 2),
    ],
  ),
];
