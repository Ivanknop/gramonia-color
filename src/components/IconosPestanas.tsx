/**
 * Íconos simples de la barra de pestañas, dibujados con react-native-svg
 * (así no sumamos una librería de íconos). Toman el color de la pestaña.
 */
import type { ColorValue } from 'react-native';
import Svg, { Circle, Path, Rect } from 'react-native-svg';

type Props = { color: ColorValue; tamano?: number };

/** Galería: un cuadro con montañas. */
export function IconoGaleria({ color, tamano = 26 }: Props) {
  return (
    <Svg width={tamano} height={tamano} viewBox="0 0 24 24" fill="none">
      <Rect x={3} y={4} width={18} height={16} rx={2} stroke={color} strokeWidth={2} />
      <Path d="M5 17 L10 11 L13 14 L15 12 L19 17 Z" fill={color} />
      <Circle cx={16} cy={8} r={1.6} fill={color} />
    </Svg>
  );
}

/** Mis obras: una paleta de pintor. */
export function IconoMisObras({ color, tamano = 26 }: Props) {
  return (
    <Svg width={tamano} height={tamano} viewBox="0 0 24 24" fill="none">
      <Path
        d="M12 3 C6.5 3 3 6.8 3 11.5 C3 16 6.5 20 11 20 C12.5 20 13 19 12.5 17.8 C12 16.6 12.8 15.5 14 15.5 L16.5 15.5 C19 15.5 21 13.8 21 11 C21 6.5 17 3 12 3 Z"
        stroke={color}
        strokeWidth={2}
      />
      <Circle cx={8} cy={10} r={1.5} fill={color} />
      <Circle cx={12} cy={7} r={1.5} fill={color} />
      <Circle cx={16} cy={9.5} r={1.5} fill={color} />
    </Svg>
  );
}

/** Mapa: un mapa plegado. */
export function IconoMapa({ color, tamano = 26 }: Props) {
  return (
    <Svg width={tamano} height={tamano} viewBox="0 0 24 24" fill="none">
      <Path
        d="M3 6 L9 4 L15 6 L21 4 L21 18 L15 20 L9 18 L3 20 Z M9 4 L9 18 M15 6 L15 20"
        stroke={color}
        strokeWidth={2}
        strokeLinejoin="round"
      />
    </Svg>
  );
}
