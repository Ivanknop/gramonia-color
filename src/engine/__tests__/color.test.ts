import { grisSinColor, luminancia, textoSobre } from '../color';

test('luminancia de blanco y negro', () => {
  expect(luminancia('#FFFFFF')).toBeCloseTo(1);
  expect(luminancia('#000000')).toBeCloseTo(0);
});

test('el gris sin color siempre es claro y es gris', () => {
  for (const hex of ['#000000', '#FFFFFF', '#674EA7', '#FFD966']) {
    const gris = grisSinColor(hex);
    expect(gris.slice(1, 3)).toBe(gris.slice(3, 5));
    expect(luminancia(gris)).toBeGreaterThan(0.45);
  }
  // Un color oscuro queda más oscuro que uno claro.
  expect(luminancia(grisSinColor('#222222'))).toBeLessThan(luminancia(grisSinColor('#EEEEEE')));
});

test('textoSobre elige el contraste', () => {
  expect(textoSobre('#FFFFFF')).toBe('#000000');
  expect(textoSobre('#222222')).toBe('#ffffff');
});
