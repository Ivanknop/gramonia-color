/**
 * Progresión: cada cuadro terminado destapa una pieza de un bioma de
 * Gramonia; con todas sus piezas destapadas, el bioma se desbloquea entero.
 */

/** Una pieza del mapa de un bioma, ubicada en su grilla. */
export type Pieza = {
  id: string;
  /** Cuadro que hay que completar para destaparla. */
  cuadroId: string;
  fila: number;
  columna: number;
};

export type Bioma = {
  id: string;
  nombre: string;
  descripcion: string;
  /** Color dominante, para la vista provisoria del mapa. */
  color: string;
  filas: number;
  columnas: number;
  piezas: Pieza[];
};

export type EstadoBioma = {
  bioma: Bioma;
  reveladas: Set<string>;
  total: number;
  desbloqueado: boolean;
};

export function estadoBioma(bioma: Bioma, completados: ReadonlySet<string>): EstadoBioma {
  const reveladas = new Set(
    bioma.piezas.filter((p) => completados.has(p.cuadroId)).map((p) => p.id),
  );
  // El total son las celdas de la grilla: si faltan piezas por asignar
  // (todavía no hay cuadros para ellas), el bioma no puede desbloquearse.
  const total = bioma.filas * bioma.columnas;
  return { bioma, reveladas, total, desbloqueado: total > 0 && reveladas.size === total };
}

/** Qué pieza destapa un cuadro (o null si no destapa ninguna). */
export function piezaDeCuadro(
  biomas: readonly Bioma[],
  cuadroId: string,
): { bioma: Bioma; pieza: Pieza } | null {
  for (const bioma of biomas) {
    const pieza = bioma.piezas.find((p) => p.cuadroId === cuadroId);
    if (pieza) return { bioma, pieza };
  }
  return null;
}

/**
 * Revisa que los datos de biomas sean consistentes. Devuelve la lista de
 * problemas (vacía si está todo bien). Se usa en los tests de datos.
 */
export function validarBiomas(biomas: readonly Bioma[], cuadroIds: readonly string[]): string[] {
  const problemas: string[] = [];
  const existentes = new Set(cuadroIds);
  const cuadrosUsados = new Map<string, string>();
  const idsBioma = new Set<string>();

  for (const b of biomas) {
    if (idsBioma.has(b.id)) problemas.push(`Bioma repetido: ${b.id}`);
    idsBioma.add(b.id);
    const celdas = new Set<string>();
    const idsPieza = new Set<string>();
    for (const p of b.piezas) {
      const donde = `${b.id}/${p.id}`;
      if (idsPieza.has(p.id)) problemas.push(`Pieza repetida: ${donde}`);
      idsPieza.add(p.id);
      if (!existentes.has(p.cuadroId))
        problemas.push(`${donde} usa un cuadro inexistente: ${p.cuadroId}`);
      const previo = cuadrosUsados.get(p.cuadroId);
      if (previo)
        problemas.push(`El cuadro ${p.cuadroId} destapa dos piezas: ${previo} y ${donde}`);
      cuadrosUsados.set(p.cuadroId, donde);
      if (p.fila < 0 || p.fila >= b.filas || p.columna < 0 || p.columna >= b.columnas) {
        problemas.push(`${donde} está fuera de la grilla ${b.filas}x${b.columnas}`);
      }
      const celda = `${p.fila},${p.columna}`;
      if (celdas.has(celda)) problemas.push(`${donde} ocupa una celda ya usada (${celda})`);
      celdas.add(celda);
    }
  }
  return problemas;
}
