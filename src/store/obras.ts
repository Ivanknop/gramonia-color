/**
 * "Mis obras": los cuadros que el jugador ya empezó o terminó.
 * Función pura a partir del progreso guardado (sin tocar el store).
 */
import type { ProgresoCuadro } from './progreso';

export type Obra = {
  cuadroId: string;
  progreso: ProgresoCuadro;
};

export type MisObras = {
  /** Con al menos una región pintada y sin terminar; la más reciente primero. */
  enProgreso: Obra[];
  /** Terminadas; la terminada más recientemente primero. */
  terminadas: Obra[];
};

/**
 * Clasifica el progreso en obras en progreso y terminadas. Ignora cuadros que
 * ya no existen en el catálogo (por ejemplo, si se quitó uno en una versión).
 */
export function clasificarObras(
  cuadros: Record<string, ProgresoCuadro>,
  idsExistentes: ReadonlySet<string>,
): MisObras {
  const enProgreso: Obra[] = [];
  const terminadas: Obra[] = [];
  for (const [cuadroId, progreso] of Object.entries(cuadros)) {
    if (!idsExistentes.has(cuadroId)) continue;
    if (progreso.completadoEn !== undefined) terminadas.push({ cuadroId, progreso });
    else if (progreso.pintadas.length > 0) enProgreso.push({ cuadroId, progreso });
  }
  enProgreso.sort((a, b) => (b.progreso.actualizadoEn ?? 0) - (a.progreso.actualizadoEn ?? 0));
  terminadas.sort((a, b) => (b.progreso.completadoEn ?? 0) - (a.progreso.completadoEn ?? 0));
  return { enProgreso, terminadas };
}
