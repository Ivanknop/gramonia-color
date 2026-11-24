/**
 * Ubicación automática de los números dentro de cada región.
 *
 * Las regiones se dibujan en orden y pueden superponerse (las últimas tapan a
 * las primeras), como en cualquier ilustración por capas. Por eso el número
 * se busca dentro de la parte VISIBLE de la región: un punto cuenta solo si
 * está dentro de la región y fuera de todas las que se dibujan encima.
 *
 * Se busca el punto visible más alejado de cualquier borde (una versión
 * simple del "polo de inaccesibilidad"): primero una grilla gruesa y después
 * un refinamiento alrededor del mejor candidato.
 */
import {
  type Caja,
  type Poligono,
  type Punto,
  cajasSeTocan,
  distanciaABorde,
  puntoEnCaja,
  puntoEnPoligonos,
} from './geometria';

export type FormaRegion = { poligonos: Poligono[]; caja: Caja };

const CELDAS = 24;
const REFINAMIENTOS = 3;

/**
 * Calcula la etiqueta de la región `indice` considerando las que están encima.
 * Devuelve null si la región queda totalmente tapada.
 */
export function calcularEtiqueta(
  formas: FormaRegion[],
  indice: number,
): { punto: Punto; radio: number } | null {
  const propia = formas[indice];
  const encima = formas.slice(indice + 1).filter((f) => cajasSeTocan(f.caja, propia.caja));

  const evaluar = (p: Punto): number => {
    if (!puntoEnPoligonos(p, propia.poligonos)) return -1;
    let radio = distanciaABorde(p, propia.poligonos);
    for (const f of encima) {
      if (puntoEnCaja(p, f.caja) && puntoEnPoligonos(p, f.poligonos)) return -1;
      radio = Math.min(radio, distanciaABorde(p, f.poligonos));
    }
    return radio;
  };

  const { minX, minY, maxX, maxY } = propia.caja;
  let pasoX = (maxX - minX) / CELDAS;
  let pasoY = (maxY - minY) / CELDAS;
  let mejor: { punto: Punto; radio: number } | null = null;

  const buscar = (x0: number, y0: number, x1: number, y1: number) => {
    for (let x = x0 + pasoX / 2; x < x1; x += pasoX) {
      for (let y = y0 + pasoY / 2; y < y1; y += pasoY) {
        const radio = evaluar({ x, y });
        if (radio > 0 && (!mejor || radio > mejor.radio)) mejor = { punto: { x, y }, radio };
      }
    }
  };

  buscar(minX, minY, maxX, maxY);
  for (let i = 0; i < REFINAMIENTOS && mejor; i++) {
    // Ventana de ±1 celda alrededor del mejor punto, con celdas 4 veces menores.
    const { x, y } = (mejor as { punto: Punto }).punto;
    const [ventanaX, ventanaY] = [pasoX, pasoY];
    pasoX /= 4;
    pasoY /= 4;
    buscar(x - ventanaX, y - ventanaY, x + ventanaX, y + ventanaY);
  }
  return mejor;
}
