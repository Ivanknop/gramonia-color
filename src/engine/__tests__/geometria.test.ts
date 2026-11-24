import { aplanarPath, cajaDe, distanciaABorde, puntoEnPoligonos } from '../geometria';

describe('aplanarPath', () => {
  test('un rectángulo con H/V da 4 puntos', () => {
    const [pol] = aplanarPath('M0 0 H10 V5 H0 Z');
    expect(pol).toEqual([
      { x: 0, y: 0 },
      { x: 10, y: 0 },
      { x: 10, y: 5 },
      { x: 0, y: 5 },
    ]);
  });

  test('comandos relativos y pares implícitos después de M', () => {
    const [pol] = aplanarPath('m10 10 10 0 0 10 z');
    expect(pol).toEqual([
      { x: 10, y: 10 },
      { x: 20, y: 10 },
      { x: 20, y: 20 },
    ]);
  });

  test('varios subpaths generan varios polígonos', () => {
    expect(aplanarPath('M0 0 H10 V10 H0 Z M2 2 H8 V8 H2 Z')).toHaveLength(2);
  });

  test('una curva cúbica termina en su punto final y pasa por el medio esperado', () => {
    const [pol] = aplanarPath('M0 0 C0 10 10 10 10 0 Z');
    expect(pol[pol.length - 1]).toEqual({ x: 10, y: 0 });
    const medio = pol[6]; // s = 0.5 con 12 pasos
    expect(medio.x).toBeCloseTo(5);
    expect(medio.y).toBeCloseTo(7.5);
  });

  test('S refleja el control anterior', () => {
    const [pol] = aplanarPath('M0 0 C0 10 10 10 10 0 S20 -10 20 0 Z');
    expect(pol[pol.length - 1]).toEqual({ x: 20, y: 0 });
    expect(pol[18].y).toBeCloseTo(-7.5);
  });

  test('números pegados con signo negativo y decimales', () => {
    const [pol] = aplanarPath('M0,0L10-5L.5.5Z');
    expect(pol).toEqual([
      { x: 0, y: 0 },
      { x: 10, y: -5 },
      { x: 0.5, y: 0.5 },
    ]);
  });

  test('rechaza cantidades de parámetros inválidas', () => {
    expect(() => aplanarPath('M0 0 L10')).toThrow();
  });
});

describe('puntoEnPoligonos', () => {
  const anillo = aplanarPath('M0 0 H10 V10 H0 Z M3 3 H7 V7 H3 Z');

  test('dentro del borde del anillo', () => {
    expect(puntoEnPoligonos({ x: 1, y: 1 }, anillo)).toBe(true);
  });

  test('en el agujero del anillo (regla evenodd)', () => {
    expect(puntoEnPoligonos({ x: 5, y: 5 }, anillo)).toBe(false);
  });

  test('afuera', () => {
    expect(puntoEnPoligonos({ x: 11, y: 5 }, anillo)).toBe(false);
  });
});

test('distanciaABorde y cajaDe', () => {
  const cuadrado = aplanarPath('M0 0 H10 V10 H0 Z');
  expect(distanciaABorde({ x: 5, y: 2 }, cuadrado)).toBeCloseTo(2);
  expect(cajaDe(cuadrado)).toEqual({ minX: 0, minY: 0, maxX: 10, maxY: 10 });
});
