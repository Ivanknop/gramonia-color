/**
 * Progreso del jugador, persistido en AsyncStorage entre sesiones.
 *
 * Solo se guarda lo mínimo (qué regiones se pintaron y qué cuadros se
 * terminaron). Lo derivado —porcentajes, piezas de biomas destapadas,
 * biomas desbloqueados— se calcula con el motor a partir de esto.
 */
import AsyncStorage from '@react-native-async-storage/async-storage';
import { create } from 'zustand';
import { createJSONStorage, persist } from 'zustand/middleware';

export type ProgresoCuadro = {
  /** Ids de regiones pintadas, en el orden en que se pintaron. */
  pintadas: string[];
  /** Momento (ms) en que se completó; ausente si no se terminó. */
  completadoEn?: number;
};

type EstadoProgreso = {
  cuadros: Record<string, ProgresoCuadro>;
  /** Registra una región pintada. Idempotente. */
  pintarRegion: (cuadroId: string, regionId: string) => void;
  marcarCompletado: (cuadroId: string) => void;
  reiniciarCuadro: (cuadroId: string) => void;
  reiniciarTodo: () => void;
};

export const CLAVE_ALMACENAMIENTO = 'colores-de-gramonia/progreso';

export const useProgreso = create<EstadoProgreso>()(
  persist(
    (set) => ({
      cuadros: {},
      pintarRegion: (cuadroId, regionId) =>
        set((s) => {
          const actual = s.cuadros[cuadroId] ?? { pintadas: [] };
          if (actual.pintadas.includes(regionId)) return s;
          return {
            cuadros: {
              ...s.cuadros,
              [cuadroId]: { ...actual, pintadas: [...actual.pintadas, regionId] },
            },
          };
        }),
      marcarCompletado: (cuadroId) =>
        set((s) => {
          const actual = s.cuadros[cuadroId] ?? { pintadas: [] };
          if (actual.completadoEn) return s;
          return { cuadros: { ...s.cuadros, [cuadroId]: { ...actual, completadoEn: Date.now() } } };
        }),
      reiniciarCuadro: (cuadroId) =>
        set((s) => {
          const { [cuadroId]: _descartado, ...resto } = s.cuadros;
          return { cuadros: resto };
        }),
      reiniciarTodo: () => set({ cuadros: {} }),
    }),
    {
      name: CLAVE_ALMACENAMIENTO,
      storage: createJSONStorage(() => AsyncStorage),
      version: 1,
      // Solo los datos; las acciones no se guardan.
      partialize: (s) => ({ cuadros: s.cuadros }),
    },
  ),
);

/** Ids de los cuadros terminados (para la progresión de biomas). */
export function cuadrosCompletados(cuadros: Record<string, ProgresoCuadro>): Set<string> {
  return new Set(Object.keys(cuadros).filter((id) => cuadros[id].completadoEn !== undefined));
}
