/**
 * Utilidades de color: el cuadro "robado por Mututu" se ve en grises claros
 * que conservan algo de la luminosidad original, para que se lea la forma
 * sin que tape los números.
 */

function aRgb(hex: string): [number, number, number] {
  const n = parseInt(hex.slice(1), 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}

function aHex(r: number, g: number, b: number): string {
  return '#' + [r, g, b].map((v) => Math.round(v).toString(16).padStart(2, '0')).join('');
}

/** Luminancia relativa (0 = negro, 1 = blanco), según WCAG. */
export function luminancia(hex: string): number {
  const [r, g, b] = aRgb(hex).map((v) => {
    const c = v / 255;
    return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
  });
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/**
 * Gris "sin color" para una región sin pintar. Comprime la luminosidad al
 * rango [minimo, maximo] para que siempre sea claro y los números se lean.
 */
export function grisSinColor(hex: string, minimo = 0.72, maximo = 0.95): string {
  const l = Math.sqrt(luminancia(hex)); // raíz: reparte mejor los tonos medios
  const v = (minimo + (maximo - minimo) * l) * 255;
  return aHex(v, v, v);
}

/** Color de texto (negro o blanco) que contrasta con el fondo dado. */
export function textoSobre(hex: string): '#000000' | '#ffffff' {
  // 0.179 es el punto donde negro y blanco dan el mismo contraste WCAG.
  return luminancia(hex) > 0.179 ? '#000000' : '#ffffff';
}
