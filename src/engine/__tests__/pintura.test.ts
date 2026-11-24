import { construirCuadro } from '../cuadro';
import {
  estaCompleto,
  faltantesDeColor,
  intentarPintar,
  porcentajeCompletado,
  regionEnPunto,
  regionesPendientesDeColor,
  sanearPintadas,
} from '../pintura';
import type { MetaCuadro } from '../tipos';

// Fondo de 100x100 con un cuadrado encima (superpuesto) y un círculo de otro color.
const META: MetaCuadro = {
  id: 'prueba',
  titulo: 'Prueba',
  categoria: 'arte',
  dificultad: 1,
  mensajeMututu: '¡Listo!',
  paleta: [
    { numero: 1, nombre: 'Uno', hex: '#FF0000' },
    { numero: 2, nombre: 'Dos', hex: '#00FF00' },
  ],
};
const SVG = `<svg viewBox="0 0 100 100">
  <path id="fondo" data-numero="1" d="M0 0 H100 V100 H0 Z" />
  <path id="cuadrado" data-numero="2" d="M10 10 H40 V40 H10 Z" />
  <path id="otro" data-numero="2" d="M60 60 H90 V90 H60 Z" />
</svg>`;

const cuadro = construirCuadro(META, SVG);

describe('regionEnPunto', () => {
  test('devuelve la región de arriba cuando se superponen', () => {
    expect(regionEnPunto(cuadro, { x: 20, y: 20 })?.id).toBe('cuadrado');
    expect(regionEnPunto(cuadro, { x: 50, y: 20 })?.id).toBe('fondo');
  });

  test('fuera del cuadro no hay región', () => {
    expect(regionEnPunto(cuadro, { x: 150, y: 20 })).toBeNull();
  });
});

describe('intentarPintar', () => {
  test('color correcto', () => {
    const r = intentarPintar(cuadro, new Set(), { x: 20, y: 20 }, 2);
    expect(r).toEqual({
      tipo: 'correcto',
      regionId: 'cuadrado',
      cuadroCompleto: false,
      colorCompleto: false,
    });
  });

  test('color incorrecto informa el número esperado', () => {
    expect(intentarPintar(cuadro, new Set(), { x: 20, y: 20 }, 1)).toEqual({
      tipo: 'incorrecto',
      regionId: 'cuadrado',
      numeroEsperado: 2,
    });
  });

  test('región ya pintada', () => {
    expect(intentarPintar(cuadro, new Set(['cuadrado']), { x: 20, y: 20 }, 2).tipo).toBe(
      'ya-pintada',
    );
  });

  test('toque fuera', () => {
    expect(intentarPintar(cuadro, new Set(), { x: -5, y: 0 }, 1)).toEqual({ tipo: 'fuera' });
  });

  test('avisa cuando se completa un color y cuando se completa el cuadro', () => {
    const r1 = intentarPintar(cuadro, new Set(['cuadrado']), { x: 70, y: 70 }, 2);
    expect(r1).toMatchObject({ colorCompleto: true, cuadroCompleto: false });
    const r2 = intentarPintar(cuadro, new Set(['cuadrado', 'otro']), { x: 50, y: 50 }, 1);
    expect(r2).toMatchObject({ colorCompleto: true, cuadroCompleto: true });
  });
});

test('porcentaje, faltantes y pendientes', () => {
  const pintadas = new Set(['cuadrado']);
  expect(porcentajeCompletado(cuadro, pintadas)).toBe(33);
  expect(faltantesDeColor(cuadro, pintadas, 2)).toBe(1);
  expect(regionesPendientesDeColor(cuadro, pintadas, 2)).toEqual(['otro']);
  expect(estaCompleto(cuadro, new Set(['fondo', 'cuadrado', 'otro']))).toBe(true);
});

test('sanearPintadas descarta ids que ya no existen', () => {
  expect([...sanearPintadas(cuadro, ['fondo', 'borrada'])]).toEqual(['fondo']);
});

describe('construirCuadro', () => {
  test('ubica el número del fondo en una zona visible, no debajo del cuadrado', () => {
    const fondo = cuadro.regiones[0];
    expect(regionEnPunto(cuadro, fondo.etiqueta)?.id).toBe('fondo');
    expect(fondo.radioEtiqueta).toBeGreaterThan(5);
  });

  test('respeta la etiqueta fijada en el SVG', () => {
    const c = construirCuadro(META, SVG.replace('id="otro"', 'id="otro" data-etiqueta="61 62"'));
    expect(c.regiones[2].etiqueta).toEqual({ x: 61, y: 62 });
  });

  test('falla si una región usa un número fuera de la paleta', () => {
    expect(() => construirCuadro(META, SVG.replace('data-numero="2"', 'data-numero="9"'))).toThrow(
      /no está en la paleta/,
    );
  });

  test('falla si una región queda totalmente tapada', () => {
    const tapada = SVG.replace(
      '<path id="fondo"',
      '<path id="chiquito" data-numero="2" d="M70 70 H80 V80 H70 Z" />\n  <path id="fondo"',
    );
    expect(() => construirCuadro(META, tapada)).toThrow(/tapada/);
  });

  test('falla si un color de la paleta no se usa', () => {
    const meta = {
      ...META,
      paleta: [...META.paleta, { numero: 3, nombre: 'Tres', hex: '#0000FF' }],
    };
    expect(() => construirCuadro(meta, SVG)).toThrow(/no se usa/);
  });
});
