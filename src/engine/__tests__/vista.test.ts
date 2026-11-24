import {
  aplicarPellizco,
  escalaMaxima,
  factorBase,
  limitarVista,
  pantallaACuadro,
  tamanoNumero,
  vistaInicial,
} from '../vista';

const CUADRO = { ancho: 300, alto: 300 };
const CONTENEDOR = { ancho: 400, alto: 600 };

test('factorBase ajusta el cuadro al lado más chico del contenedor', () => {
  expect(factorBase(CONTENEDOR, CUADRO)).toBeCloseTo(400 / 300);
});

test('la vista inicial centra el cuadro', () => {
  expect(vistaInicial(CONTENEDOR, CUADRO)).toEqual({ escala: 1, x: 0, y: 100 });
});

test('pantallaACuadro invierte la transformación', () => {
  const v = { escala: 2, x: -100, y: 50 };
  const f = factorBase(CONTENEDOR, CUADRO);
  // El punto (150, 150) del cuadro se dibuja en x = -100 + 2 * 150 * f.
  const toque = { x: -100 + 2 * 150 * f, y: 50 + 2 * 150 * f };
  const p = pantallaACuadro(v, toque, CONTENEDOR, CUADRO);
  expect(p.x).toBeCloseTo(150);
  expect(p.y).toBeCloseTo(150);
});

test('el pellizco mantiene fijo el punto bajo los dedos', () => {
  const inicio = vistaInicial(CONTENEDOR, CUADRO);
  const foco = { x: 200, y: 300 };
  const antes = pantallaACuadro(inicio, foco, CONTENEDOR, CUADRO);
  const despues = aplicarPellizco(inicio, foco, foco, 3);
  expect(despues.escala).toBe(3);
  const p = pantallaACuadro(despues, foco, CONTENEDOR, CUADRO);
  expect(p.x).toBeCloseTo(antes.x);
  expect(p.y).toBeCloseTo(antes.y);
});

test('el pellizco acompaña el movimiento del foco', () => {
  const inicio = { escala: 2, x: -50, y: -50 };
  const v = aplicarPellizco(inicio, { x: 100, y: 100 }, { x: 130, y: 90 }, 1);
  expect(v).toEqual({ escala: 2, x: -20, y: -60 });
});

describe('limitarVista', () => {
  test('acota la escala entre 1 y el máximo', () => {
    expect(limitarVista({ escala: 0.3, x: 0, y: 0 }, CONTENEDOR, CUADRO, 8).escala).toBe(1);
    expect(limitarVista({ escala: 20, x: 0, y: 0 }, CONTENEDOR, CUADRO, 8).escala).toBe(8);
  });

  test('si el cuadro entra en un eje, lo centra en ese eje', () => {
    const v = limitarVista({ escala: 1, x: 37, y: -80 }, CONTENEDOR, CUADRO, 8);
    expect(v).toEqual({ escala: 1, x: 0, y: 100 });
  });

  test('con zoom no deja ver afuera del cuadro', () => {
    // Escalado: 400 * 2 = 800 de ancho y de alto.
    expect(limitarVista({ escala: 2, x: 50, y: 50 }, CONTENEDOR, CUADRO, 8)).toEqual({
      escala: 2,
      x: 0,
      y: 0,
    });
    expect(limitarVista({ escala: 2, x: -900, y: -900 }, CONTENEDOR, CUADRO, 8)).toEqual({
      escala: 2,
      x: -400,
      y: -200,
    });
  });
});

test('escalaMaxima permite leer el número más chico, entre 4x y 16x', () => {
  expect(escalaMaxima([18, 10], 1)).toBe(4); // ya se leen: mínimo 4x
  expect(escalaMaxima([4], 0.5, 14)).toBe(7); // 4 * 0.5 = 2 pt → 7x
  expect(escalaMaxima([4], 0.1, 14)).toBe(16); // tope
});

test('tamanoNumero se acota entre 4 y 18', () => {
  expect(tamanoNumero(1)).toBe(4);
  expect(tamanoNumero(10)).toBeCloseTo(11);
  expect(tamanoNumero(100)).toBe(18);
});
