/**
 * Reglas de pintar por números: qué región se tocó, si el color es el
 * correcto y cuánto falta. Funciones puras: el estado (regiones pintadas)
 * lo guarda el store.
 */
import { type Punto, puntoEnCaja, puntoEnPoligonos } from './geometria';
import type { Cuadro, Region, ResultadoPintar } from './tipos';

/** Región visible en el punto (coordenadas del viewBox), o null. */
export function regionEnPunto(cuadro: Cuadro, p: Punto): Region | null {
  // De arriba hacia abajo: la última dibujada es la que se ve.
  for (let i = cuadro.regiones.length - 1; i >= 0; i--) {
    const r = cuadro.regiones[i];
    if (puntoEnCaja(p, r.caja) && puntoEnPoligonos(p, r.poligonos)) return r;
  }
  return null;
}

/**
 * Intenta pintar el punto tocado con el número elegido.
 * No modifica nada: indica qué pasó para que la pantalla y el store actúen.
 */
export function intentarPintar(
  cuadro: Cuadro,
  pintadas: ReadonlySet<string>,
  p: Punto,
  numeroElegido: number,
): ResultadoPintar {
  const region = regionEnPunto(cuadro, p);
  if (!region) return { tipo: 'fuera' };
  if (pintadas.has(region.id)) return { tipo: 'ya-pintada', regionId: region.id };
  if (region.numero !== numeroElegido) {
    return { tipo: 'incorrecto', regionId: region.id, numeroEsperado: region.numero };
  }
  const despues = new Set(pintadas).add(region.id);
  return {
    tipo: 'correcto',
    regionId: region.id,
    cuadroCompleto: estaCompleto(cuadro, despues),
    colorCompleto: faltantesDeColor(cuadro, despues, numeroElegido) === 0,
  };
}

/** Porcentaje pintado (0 a 100), contando regiones. */
export function porcentajeCompletado(cuadro: Cuadro, pintadas: ReadonlySet<string>): number {
  if (cuadro.regiones.length === 0) return 100;
  const hechas = cuadro.regiones.filter((r) => pintadas.has(r.id)).length;
  return Math.round((hechas / cuadro.regiones.length) * 100);
}

export function estaCompleto(cuadro: Cuadro, pintadas: ReadonlySet<string>): boolean {
  return cuadro.regiones.every((r) => pintadas.has(r.id));
}

/** Cuántas regiones de ese número faltan pintar. */
export function faltantesDeColor(
  cuadro: Cuadro,
  pintadas: ReadonlySet<string>,
  numero: number,
): number {
  return cuadro.regiones.filter((r) => r.numero === numero && !pintadas.has(r.id)).length;
}

/** Ids de las regiones de un número que todavía no se pintaron (para resaltarlas). */
export function regionesPendientesDeColor(
  cuadro: Cuadro,
  pintadas: ReadonlySet<string>,
  numero: number,
): string[] {
  return cuadro.regiones.filter((r) => r.numero === numero && !pintadas.has(r.id)).map((r) => r.id);
}

/** Descarta ids que ya no existen (por ejemplo, si un cuadro se editó). */
export function sanearPintadas(cuadro: Cuadro, ids: readonly string[]): Set<string> {
  const validos = new Set(cuadro.regiones.map((r) => r.id));
  return new Set(ids.filter((id) => validos.has(id)));
}
