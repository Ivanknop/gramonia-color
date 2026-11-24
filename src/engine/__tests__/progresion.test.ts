import { type Bioma, estadoBioma, piezaDeCuadro, validarBiomas } from '../progresion';

const bosque: Bioma = {
  id: 'bosque',
  nombre: 'Bosque',
  descripcion: '',
  color: '#00FF00',
  filas: 1,
  columnas: 2,
  piezas: [
    { id: 'a', cuadroId: 'c1', fila: 0, columna: 0 },
    { id: 'b', cuadroId: 'c2', fila: 0, columna: 1 },
  ],
};

test('se desbloquea al destapar todas las piezas', () => {
  expect(estadoBioma(bosque, new Set(['c1'])).desbloqueado).toBe(false);
  const estado = estadoBioma(bosque, new Set(['c1', 'c2']));
  expect(estado.desbloqueado).toBe(true);
  expect([...estado.reveladas]).toEqual(['a', 'b']);
});

test('un bioma con celdas sin pieza asignada no se desbloquea', () => {
  const incompleto = { ...bosque, columnas: 3 };
  expect(estadoBioma(incompleto, new Set(['c1', 'c2']))).toMatchObject({
    total: 3,
    desbloqueado: false,
  });
});

test('piezaDeCuadro', () => {
  expect(piezaDeCuadro([bosque], 'c2')?.pieza.id).toBe('b');
  expect(piezaDeCuadro([bosque], 'nada')).toBeNull();
});

test('validarBiomas detecta problemas', () => {
  expect(validarBiomas([bosque], ['c1', 'c2'])).toEqual([]);
  const roto: Bioma = {
    ...bosque,
    piezas: [
      { id: 'a', cuadroId: 'c1', fila: 0, columna: 0 },
      { id: 'b', cuadroId: 'c1', fila: 0, columna: 0 },
      { id: 'c', cuadroId: 'zz', fila: 3, columna: 0 },
    ],
  };
  const problemas = validarBiomas([roto], ['c1']);
  expect(problemas.join('\n')).toMatch(/dos piezas/);
  expect(problemas.join('\n')).toMatch(/celda ya usada/);
  expect(problemas.join('\n')).toMatch(/inexistente/);
  expect(problemas.join('\n')).toMatch(/fuera de la grilla/);
});
