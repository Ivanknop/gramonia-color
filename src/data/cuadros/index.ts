/**
 * Catálogo de cuadros. Los metadatos están disponibles al instante; la
 * geometría (aplanado de paths y ubicación de números) se calcula la primera
 * vez que se pide cada cuadro y queda en memoria.
 */
import { type Cuadro, type MetaCuadro, construirCuadro } from '@/engine';

import { CUADROS_CRUDOS } from './indice.generado';

export const METAS_CUADROS: MetaCuadro[] = CUADROS_CRUDOS.map((c) => c.meta);

const cache = new Map<string, Cuadro>();

export function obtenerCuadro(id: string): Cuadro | null {
  const enCache = cache.get(id);
  if (enCache) return enCache;
  const crudo = CUADROS_CRUDOS.find((c) => c.meta.id === id);
  if (!crudo) return null;
  const cuadro = construirCuadro(crudo.meta, crudo.svg);
  cache.set(id, cuadro);
  return cuadro;
}
