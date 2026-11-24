#!/usr/bin/env node
/**
 * Empaqueta los cuadros de src/data/cuadros/<id>/{cuadro.json,cuadro.svg}
 * en src/data/cuadros/indice.generado.ts, para que la app los importe
 * (Metro no importa .svg como texto sin configuración extra).
 *
 * Uso:   npm run cuadros            (regenera el índice)
 *        npm run cuadros -- --check (falla si el índice está desactualizado)
 *
 * El orden de los cuadros en la galería es alfabético por id; para fijar
 * otro, agregar "orden" en el cuadro.json (menor primero).
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const raiz = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const dirCuadros = path.join(raiz, 'src/data/cuadros');
const salida = path.join(dirCuadros, 'indice.generado.ts');

export function generarIndice() {
  const entradas = fs
    .readdirSync(dirCuadros, { withFileTypes: true })
    .filter((e) => e.isDirectory())
    .map((e) => {
      const dir = path.join(dirCuadros, e.name);
      const meta = JSON.parse(fs.readFileSync(path.join(dir, 'cuadro.json'), 'utf8'));
      if (meta.id !== e.name) {
        throw new Error(`El id "${meta.id}" no coincide con la carpeta "${e.name}"`);
      }
      // El SVG se guarda sin saltos de línea sobrantes; el motor lo parsea al cargar.
      const svg = fs.readFileSync(path.join(dir, 'cuadro.svg'), 'utf8').trim();
      return { meta, svg };
    })
    .sort(
      (a, b) => (a.meta.orden ?? 0) - (b.meta.orden ?? 0) || a.meta.id.localeCompare(b.meta.id),
    );

  return [
    '// ARCHIVO GENERADO por scripts/compilar-cuadros.mjs — no editar a mano.',
    '// Para cambiar un cuadro, editá su carpeta y corré `npm run cuadros`.',
    "import type { MetaCuadro } from '@/engine';",
    '',
    'export const CUADROS_CRUDOS: { meta: MetaCuadro; svg: string }[] = ' +
      JSON.stringify(entradas, null, 2) +
      ';',
    '',
  ].join('\n');
}

const esPrincipal =
  process.argv[1] && fileURLToPath(import.meta.url) === path.resolve(process.argv[1]);
if (esPrincipal) {
  const contenido = generarIndice();
  if (process.argv.includes('--check')) {
    const actual = fs.existsSync(salida) ? fs.readFileSync(salida, 'utf8') : '';
    if (actual !== contenido) {
      console.error('indice.generado.ts está desactualizado: corré `npm run cuadros`.');
      process.exit(1);
    }
    console.log('Índice de cuadros al día.');
  } else {
    fs.writeFileSync(salida, contenido);
    console.log(`Generado ${path.relative(raiz, salida)}`);
  }
}
