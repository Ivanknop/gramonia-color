/**
 * Geometría de paths SVG para el motor de pintar por números.
 *
 * Convierte el atributo `d` de un <path> en una lista de polígonos (uno por
 * subpath) aplanando las curvas. Con eso se resuelve la detección de toques
 * (punto dentro de región) y la ubicación de los números, sin depender del
 * sistema de toques de react-native-svg (que choca con zoom/paneo).
 *
 * Comandos soportados: M L H V C S Q T Z (absolutos y relativos).
 * El arco (A) se aproxima con una recta al punto final: conviene evitarlo en
 * los cuadros (los editores vectoriales permiten convertir arcos a curvas).
 */

export type Punto = { x: number; y: number };
/** Un polígono cerrado como lista de puntos. */
export type Poligono = Punto[];

export type Caja = { minX: number; minY: number; maxX: number; maxY: number };

/** Cantidad de segmentos rectos con que se aproxima cada curva. */
const PASOS_CURVA = 12;

const CANT_PARAMS: Record<string, number> = {
  M: 2,
  L: 2,
  H: 1,
  V: 1,
  C: 6,
  S: 4,
  Q: 4,
  T: 2,
  A: 7,
  Z: 0,
};

/** Separa el `d` en comandos con sus números. */
function tokenizar(d: string): { cmd: string; args: number[] }[] {
  const resultado: { cmd: string; args: number[] }[] = [];
  const re = /([MmLlHhVvCcSsQqTtAaZz])|(-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?)/g;
  let actual: { cmd: string; args: number[] } | null = null;
  let m: RegExpExecArray | null;
  while ((m = re.exec(d)) !== null) {
    if (m[1]) {
      actual = { cmd: m[1], args: [] };
      resultado.push(actual);
    } else if (actual) {
      actual.args.push(parseFloat(m[2]));
    } else {
      throw new Error(`Path inválido: número antes del primer comando en "${d.slice(0, 30)}"`);
    }
  }
  return resultado;
}

/** Aplana el `d` de un path SVG en polígonos (uno por subpath). */
export function aplanarPath(d: string): Poligono[] {
  const poligonos: Poligono[] = [];
  let actual: Poligono = [];
  let x = 0;
  let y = 0;
  let inicioX = 0;
  let inicioY = 0;
  // Último punto de control, para los comandos "suaves" S y T.
  let ctrlX = 0;
  let ctrlY = 0;
  let ultimoCmd = '';

  const cerrarSubpath = () => {
    if (actual.length >= 3) poligonos.push(actual);
    actual = [];
  };

  for (const { cmd, args } of tokenizar(d)) {
    const tipo = cmd.toUpperCase();
    const rel = cmd !== tipo;
    const n = CANT_PARAMS[tipo];

    if (tipo === 'Z') {
      cerrarSubpath();
      x = inicioX;
      y = inicioY;
      ultimoCmd = 'Z';
      continue;
    }

    if (args.length === 0 || args.length % n !== 0) {
      throw new Error(`Comando "${cmd}" con ${args.length} parámetros (esperaba múltiplo de ${n})`);
    }

    for (let i = 0; i < args.length; i += n) {
      const a = args.slice(i, i + n);
      const ox = rel ? x : 0;
      const oy = rel ? y : 0;
      // Tras el primer par, un M se interpreta como L (regla de SVG).
      const t = tipo === 'M' && i > 0 ? 'L' : tipo;

      switch (t) {
        case 'M':
          cerrarSubpath();
          x = ox + a[0];
          y = oy + a[1];
          inicioX = x;
          inicioY = y;
          actual.push({ x, y });
          break;
        case 'L':
          x = ox + a[0];
          y = oy + a[1];
          actual.push({ x, y });
          break;
        case 'H':
          x = (rel ? x : 0) + a[0];
          actual.push({ x, y });
          break;
        case 'V':
          y = (rel ? y : 0) + a[0];
          actual.push({ x, y });
          break;
        case 'C':
        case 'S': {
          let c1x: number;
          let c1y: number;
          let c2x: number;
          let c2y: number;
          let fx: number;
          let fy: number;
          if (t === 'C') {
            [c1x, c1y, c2x, c2y, fx, fy] = [
              ox + a[0],
              oy + a[1],
              ox + a[2],
              oy + a[3],
              ox + a[4],
              oy + a[5],
            ];
          } else {
            const reflejar = ultimoCmd === 'C' || ultimoCmd === 'S';
            c1x = reflejar ? 2 * x - ctrlX : x;
            c1y = reflejar ? 2 * y - ctrlY : y;
            [c2x, c2y, fx, fy] = [ox + a[0], oy + a[1], ox + a[2], oy + a[3]];
          }
          for (let p = 1; p <= PASOS_CURVA; p++) {
            const s = p / PASOS_CURVA;
            const u = 1 - s;
            actual.push({
              x: u * u * u * x + 3 * u * u * s * c1x + 3 * u * s * s * c2x + s * s * s * fx,
              y: u * u * u * y + 3 * u * u * s * c1y + 3 * u * s * s * c2y + s * s * s * fy,
            });
          }
          ctrlX = c2x;
          ctrlY = c2y;
          x = fx;
          y = fy;
          break;
        }
        case 'Q':
        case 'T': {
          let cx: number;
          let cy: number;
          let fx: number;
          let fy: number;
          if (t === 'Q') {
            [cx, cy, fx, fy] = [ox + a[0], oy + a[1], ox + a[2], oy + a[3]];
          } else {
            const reflejar = ultimoCmd === 'Q' || ultimoCmd === 'T';
            cx = reflejar ? 2 * x - ctrlX : x;
            cy = reflejar ? 2 * y - ctrlY : y;
            [fx, fy] = [ox + a[0], oy + a[1]];
          }
          for (let p = 1; p <= PASOS_CURVA; p++) {
            const s = p / PASOS_CURVA;
            const u = 1 - s;
            actual.push({
              x: u * u * x + 2 * u * s * cx + s * s * fx,
              y: u * u * y + 2 * u * s * cy + s * s * fy,
            });
          }
          ctrlX = cx;
          ctrlY = cy;
          x = fx;
          y = fy;
          break;
        }
        case 'A':
          // Aproximación: recta al punto final (ver comentario del módulo).
          x = ox + a[5];
          y = oy + a[6];
          actual.push({ x, y });
          break;
      }
      ultimoCmd = t;
    }
  }
  cerrarSubpath();
  return poligonos;
}

/**
 * ¿El punto está dentro del conjunto de polígonos? Usa la regla par-impar
 * (evenodd), así un subpath dentro de otro funciona como agujero.
 */
export function puntoEnPoligonos(p: Punto, poligonos: Poligono[]): boolean {
  let dentro = false;
  for (const pol of poligonos) {
    for (let i = 0, j = pol.length - 1; i < pol.length; j = i++) {
      const a = pol[i];
      const b = pol[j];
      if (a.y > p.y !== b.y > p.y && p.x < ((b.x - a.x) * (p.y - a.y)) / (b.y - a.y) + a.x) {
        dentro = !dentro;
      }
    }
  }
  return dentro;
}

/** Distancia del punto al borde más cercano de los polígonos. */
export function distanciaABorde(p: Punto, poligonos: Poligono[]): number {
  let minimo = Infinity;
  for (const pol of poligonos) {
    for (let i = 0, j = pol.length - 1; i < pol.length; j = i++) {
      minimo = Math.min(minimo, distanciaASegmento(p, pol[j], pol[i]));
    }
  }
  return minimo;
}

function distanciaASegmento(p: Punto, a: Punto, b: Punto): number {
  const dx = b.x - a.x;
  const dy = b.y - a.y;
  const largo2 = dx * dx + dy * dy;
  let t = largo2 === 0 ? 0 : ((p.x - a.x) * dx + (p.y - a.y) * dy) / largo2;
  t = Math.max(0, Math.min(1, t));
  return Math.hypot(p.x - (a.x + t * dx), p.y - (a.y + t * dy));
}

export function cajaDe(poligonos: Poligono[]): Caja {
  const caja = { minX: Infinity, minY: Infinity, maxX: -Infinity, maxY: -Infinity };
  for (const pol of poligonos) {
    for (const { x, y } of pol) {
      caja.minX = Math.min(caja.minX, x);
      caja.minY = Math.min(caja.minY, y);
      caja.maxX = Math.max(caja.maxX, x);
      caja.maxY = Math.max(caja.maxY, y);
    }
  }
  return caja;
}

export function cajasSeTocan(a: Caja, b: Caja): boolean {
  return a.minX <= b.maxX && b.minX <= a.maxX && a.minY <= b.maxY && b.minY <= a.maxY;
}

export function puntoEnCaja(p: Punto, c: Caja): boolean {
  return p.x >= c.minX && p.x <= c.maxX && p.y >= c.minY && p.y <= c.maxY;
}
