import { render, screen } from '@testing-library/react-native';

import Inicio from '../../app/index';

// Prueba de humo: la pantalla de inicio renderiza.
test('la pantalla de inicio muestra el título', async () => {
  await render(<Inicio />);
  expect(screen.getByText('Colores de Gramonia')).toBeTruthy();
});
