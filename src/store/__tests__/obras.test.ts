import { clasificarObras } from '../obras';

const existentes = new Set(['a', 'b', 'c', 'd']);

test('separa en progreso y terminadas, ordenadas por fecha más reciente', () => {
  const obras = clasificarObras(
    {
      a: { pintadas: ['r1'], actualizadoEn: 100 },
      b: { pintadas: ['r1', 'r2'], actualizadoEn: 300 },
      c: { pintadas: ['r1'], actualizadoEn: 50, completadoEn: 60 },
      d: { pintadas: ['r1'], actualizadoEn: 400, completadoEn: 500 },
    },
    existentes,
  );
  expect(obras.enProgreso.map((o) => o.cuadroId)).toEqual(['b', 'a']);
  expect(obras.terminadas.map((o) => o.cuadroId)).toEqual(['d', 'c']);
});

test('ignora cuadros sin pintar y cuadros que ya no existen', () => {
  const obras = clasificarObras(
    {
      a: { pintadas: [] },
      viejo: { pintadas: ['r1'], actualizadoEn: 1 },
    },
    existentes,
  );
  expect(obras).toEqual({ enProgreso: [], terminadas: [] });
});
