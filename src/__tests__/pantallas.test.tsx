/**
 * Pruebas de las pantallas con el router de expo-router simulado.
 * Nota: en @testing-library/react-native 14, fireEvent es asíncrono (await).
 */
import { act, fireEvent, renderRouter, screen } from 'expo-router/testing-library';
import { createGestureController } from 'react-native-gesture-handler/jest-utils';

import LayoutPestanas from '../../app/(tabs)/_layout';
import Galeria from '../../app/(tabs)/galeria';
import Mapa from '../../app/(tabs)/mapa';
import MisObras from '../../app/(tabs)/mis-obras';
import LayoutRaiz from '../../app/_layout';
import Inicio from '../../app/index';
import Pintar from '../../app/pintar/[id]';
import { obtenerCuadro } from '@/data/cuadros';
import { useProgreso } from '@/store/progreso';

const RUTAS = {
  _layout: LayoutRaiz,
  index: Inicio,
  '(tabs)/_layout': LayoutPestanas,
  '(tabs)/galeria': Galeria,
  '(tabs)/mis-obras': MisObras,
  '(tabs)/mapa': Mapa,
  'pintar/[id]': Pintar,
};

beforeEach(() => useProgreso.getState().reiniciarTodo());

/**
 * Da al lienzo un tamaño de 300x300: como los cuadros miden 300x300, una
 * coordenada de pantalla coincide con una del viewBox (zoom 1).
 */
async function prepararLienzo() {
  await fireEvent(screen.getByTestId('lienzo'), 'layout', {
    nativeEvent: { layout: { x: 0, y: 0, width: 300, height: 300 } },
  });
}

/** Simula un toque (gesto de tap) en el lienzo. */
async function tocarLienzo(x: number, y: number) {
  await act(async () => {
    const tap = createGestureController('lienzo-toque');
    tap.begin({ x, y });
    tap.activate({ x, y });
    tap.end({ x, y });
  });
}

test('inicio → galería muestra los cuadros', async () => {
  await renderRouter(RUTAS, { initialUrl: '/' });
  expect(screen.getByText('Colores de Gramonia')).toBeTruthy();
  await fireEvent.press(screen.getByText('Pintar'));
  expect(await screen.findByText('Atardecer en el lago')).toBeTruthy();
  expect(screen.getByText('Taza de té')).toBeTruthy();
});

test('un color equivocado no pinta', async () => {
  await renderRouter(RUTAS, { initialUrl: '/pintar/pez-naranja' });
  const cuadro = obtenerCuadro('pez-naranja')!;
  const ojo = cuadro.regiones.find((r) => r.id === 'ojo')!;
  await fireEvent.press(screen.getByLabelText(/^Color 1, /));
  await prepararLienzo();
  await tocarLienzo(ojo.etiqueta.x, ojo.etiqueta.y);
  expect(useProgreso.getState().cuadros['pez-naranja']).toBeUndefined();
});

test('pintar todo un cuadro muestra el mensaje y destapa la pieza del bioma', async () => {
  const cuadro = obtenerCuadro('pez-naranja')!;
  await renderRouter(RUTAS, { initialUrl: '/pintar/pez-naranja' });
  expect(await screen.findByText('0% con color')).toBeTruthy();

  await prepararLienzo();

  // Pinta región por región tocando su número, eligiendo antes su color.
  for (const r of cuadro.regiones) {
    const boton = screen.queryByLabelText(new RegExp(`^Color ${r.numero}, `));
    if (boton) await fireEvent.press(boton);
    await tocarLienzo(r.etiqueta.x, r.etiqueta.y);
  }

  expect(await screen.findByText(cuadro.mensajeMututu)).toBeTruthy();
  expect(screen.getByText('Destapaste una pieza de Costa de Espuma.')).toBeTruthy();
  expect(useProgreso.getState().cuadros['pez-naranja'].completadoEn).toBeDefined();

  await fireEvent.press(screen.getByText('Ver el mapa'));
  expect(await screen.findByText('1 de 4 piezas destapadas')).toBeTruthy();
});

describe('Mis obras', () => {
  test('sin obras muestra el mensaje vacío', async () => {
    await renderRouter(RUTAS, { initialUrl: '/mis-obras' });
    expect(await screen.findByText('Todavía no hay obras')).toBeTruthy();
  });

  test('separa obras en progreso y terminadas, y permite retomarlas', async () => {
    const s = useProgreso.getState();
    s.pintarRegion('taza-de-te', 'pared');
    const pez = obtenerCuadro('pez-naranja')!;
    for (const r of pez.regiones) s.pintarRegion(pez.id, r.id);
    s.marcarCompletado(pez.id);

    await renderRouter(RUTAS, { initialUrl: '/mis-obras' });
    expect(await screen.findByText('En progreso (1)')).toBeTruthy();
    expect(screen.getByText('Terminadas (1)')).toBeTruthy();
    expect(screen.getByLabelText('Taza de té, 11%')).toBeTruthy();
    expect(screen.getByLabelText('Pez naranja, terminada')).toBeTruthy();
    expect(screen.queryByText('Atardecer en el lago')).toBeNull();

    await fireEvent.press(screen.getByLabelText('Taza de té, 11%'));
    expect(await screen.findByText('11% con color')).toBeTruthy();
  });
});
