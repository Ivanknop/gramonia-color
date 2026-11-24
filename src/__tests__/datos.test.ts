/** Verifica que los datos del juego (cuadros y biomas) sean válidos. */
import { execFileSync } from 'node:child_process';
import path from 'node:path';

import { BIOMAS } from '@/data/biomas';
import { METAS_CUADROS, obtenerCuadro } from '@/data/cuadros';
import { regionEnPunto, validarBiomas } from '@/engine';

test('el índice generado de cuadros está al día', () => {
  const script = path.join(__dirname, '../../scripts/compilar-cuadros.mjs');
  expect(() => execFileSync('node', [script, '--check'], { stdio: 'pipe' })).not.toThrow();
});

test('hay al menos 3 cuadros', () => {
  expect(METAS_CUADROS.length).toBeGreaterThanOrEqual(3);
});

describe.each(METAS_CUADROS.map((m) => [m.id]))('cuadro %s', (id) => {
  const cuadro = obtenerCuadro(id)!;

  test('se construye sin errores', () => {
    expect(cuadro.regiones.length).toBeGreaterThan(0);
  });

  test('cada número queda sobre su propia región', () => {
    for (const r of cuadro.regiones) {
      expect(regionEnPunto(cuadro, r.etiqueta)?.id).toBe(r.id);
    }
  });
});

test('los biomas son consistentes con los cuadros', () => {
  expect(
    validarBiomas(
      BIOMAS,
      METAS_CUADROS.map((m) => m.id),
    ),
  ).toEqual([]);
});

test('cada cuadro destapa una pieza', () => {
  const usados = new Set(BIOMAS.flatMap((b) => b.piezas.map((p) => p.cuadroId)));
  for (const m of METAS_CUADROS) expect(usados.has(m.id)).toBe(true);
});
