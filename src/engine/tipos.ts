/**
 * Tipos del motor de pintar por números.
 */
import type { Caja, Poligono, Punto } from './geometria';

export type Categoria = 'paisaje' | 'animal' | 'objeto' | 'persona' | 'arte';

/** Un color de la paleta de un cuadro. El número es el que ve el jugador. */
export type ColorPaleta = {
  numero: number;
  nombre: string;
  /** Color objetivo en formato #RRGGBB. */
  hex: string;
};

/** Metadatos de un cuadro (archivo cuadro.json). */
export type MetaCuadro = {
  id: string;
  titulo: string;
  categoria: Categoria;
  /** 1 = muy fácil … 5 = muy difícil. */
  dificultad: number;
  paleta: ColorPaleta[];
  /** Frase que se muestra al devolverle los colores al cuadro. */
  mensajeMututu: string;
};

/** Una región pintable, ya procesada y lista para el motor. */
export type Region = {
  id: string;
  /** Número de la paleta que corresponde a esta región. */
  numero: number;
  /** El `d` original, para dibujarla con react-native-svg. */
  d: string;
  /** Geometría aplanada, para detección de toques. */
  poligonos: Poligono[];
  caja: Caja;
  /** Dónde va el número dentro de la región (zona visible). */
  etiqueta: Punto;
  /** Radio libre alrededor de la etiqueta: sirve para el tamaño del número. */
  radioEtiqueta: number;
};

/** Un cuadro completo: metadatos + geometría. */
export type Cuadro = MetaCuadro & {
  ancho: number;
  alto: number;
  /** En orden de dibujo: las últimas quedan arriba. */
  regiones: Region[];
};

/** Lo que pasó al tocar una región con un color. */
export type ResultadoPintar =
  | { tipo: 'correcto'; regionId: string; cuadroCompleto: boolean; colorCompleto: boolean }
  | { tipo: 'incorrecto'; regionId: string; numeroEsperado: number }
  | { tipo: 'ya-pintada'; regionId: string }
  | { tipo: 'fuera' };
