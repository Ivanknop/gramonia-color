import AsyncStorage from '@react-native-async-storage/async-storage';

import { CLAVE_ALMACENAMIENTO, cuadrosCompletados, useProgreso } from '../progreso';

beforeEach(() => useProgreso.getState().reiniciarTodo());

test('pintar es idempotente y respeta el orden', () => {
  const { pintarRegion } = useProgreso.getState();
  pintarRegion('c1', 'a');
  pintarRegion('c1', 'b');
  pintarRegion('c1', 'a');
  expect(useProgreso.getState().cuadros.c1.pintadas).toEqual(['a', 'b']);
});

test('completar y reiniciar un cuadro', () => {
  const s = useProgreso.getState();
  s.pintarRegion('c1', 'a');
  s.marcarCompletado('c1');
  expect(cuadrosCompletados(useProgreso.getState().cuadros)).toEqual(new Set(['c1']));
  useProgreso.getState().reiniciarCuadro('c1');
  expect(useProgreso.getState().cuadros.c1).toBeUndefined();
});

test('el progreso se guarda en AsyncStorage', async () => {
  useProgreso.getState().pintarRegion('c2', 'x');
  // persist escribe de forma asíncrona.
  await new Promise((r) => setTimeout(r, 0));
  const guardado = JSON.parse((await AsyncStorage.getItem(CLAVE_ALMACENAMIENTO)) ?? '{}');
  expect(guardado.state.cuadros.c2.pintadas).toEqual(['x']);
  expect(guardado.state).not.toHaveProperty('pintarRegion');
});
