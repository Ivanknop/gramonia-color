#!/usr/bin/env node
/**
 * Genera los tipos de rutas de expo-router (.expo/types/router.d.ts y
 * expo-env.d.ts) sin levantar Metro, para que `tsc` funcione en un clon
 * limpio o en CI. `npx expo start` hace lo mismo al arrancar.
 *
 * Usa una función interna de @expo/cli: si deja de existir en un SDK futuro,
 * alcanza con correr `npx expo start` una vez para generar los tipos.
 */
import { createRequire } from 'node:module';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const raiz = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const requerir = createRequire(path.join(raiz, 'package.json'));
const cli = path.dirname(
  requerir.resolve('@expo/cli/package.json', { paths: [requerir.resolve('expo')] }),
);
const { startTypescriptTypeGenerationAsync } = requerir(
  path.join(cli, 'build/src/start/server/type-generation/startTypescriptTypeGeneration'),
);

await startTypescriptTypeGenerationAsync({ projectRoot: raiz, metro: null, server: null });
