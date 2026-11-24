/**
 * Biomas de Gramonia y sus piezas. Cada pieza se destapa al completar el
 * cuadro indicado en `cuadroId`. Un cuadro destapa como máximo una pieza
 * (lo verifica src/__tests__/datos.test.ts).
 *
 * Con 3 cuadros de ejemplo: el Bosque tiene 2 piezas (se puede desbloquear
 * entero) y la Costa 1 pieza destapable de 4 (muestra un bioma a medias).
 */
import type { Bioma } from '@/engine';

export const BIOMAS: Bioma[] = [
  {
    id: 'bosque-susurrante',
    nombre: 'Bosque Susurrante',
    descripcion:
      'Árboles altísimos que se cuentan secretos con el viento. Mututu empezó su robo por acá.',
    color: '#6AA84F',
    filas: 1,
    columnas: 2,
    piezas: [
      { id: 'claro', cuadroId: 'atardecer-en-el-lago', fila: 0, columna: 0 },
      { id: 'casa-del-arbol', cuadroId: 'taza-de-te', fila: 0, columna: 1 },
    ],
  },
  {
    id: 'costa-de-espuma',
    nombre: 'Costa de Espuma',
    descripcion: 'Playas de arena rosada donde las olas traen botellas con mensajes.',
    color: '#45818E',
    filas: 2,
    columnas: 2,
    piezas: [
      { id: 'arrecife', cuadroId: 'pez-naranja', fila: 0, columna: 0 },
      // Las demás piezas se asignarán cuando haya más cuadros.
    ],
  },
];
