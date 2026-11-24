/**
 * Vista chica de un cuadro tal como lo dejó el jugador: regiones pintadas con
 * su color y el resto en gris, sin números. Para "Mis obras" y la galería.
 */
import { memo } from 'react';
import Svg, { Path } from 'react-native-svg';

import { type Cuadro, grisSinColor } from '@/engine';

type Props = {
  cuadro: Cuadro;
  pintadas: ReadonlySet<string>;
  /** Lado mayor en puntos. */
  tamano: number;
};

function MiniaturaBase({ cuadro, pintadas, tamano }: Props) {
  const colores = new Map(cuadro.paleta.map((c) => [c.numero, c.hex] as const));
  const escala = tamano / Math.max(cuadro.ancho, cuadro.alto);
  return (
    <Svg
      width={cuadro.ancho * escala}
      height={cuadro.alto * escala}
      viewBox={`0 0 ${cuadro.ancho} ${cuadro.alto}`}
      accessibilityElementsHidden
      importantForAccessibility="no-hide-descendants"
    >
      {cuadro.regiones.map((r) => {
        const hex = colores.get(r.numero) ?? '#000000';
        return (
          <Path
            key={r.id}
            d={r.d}
            fill={pintadas.has(r.id) ? hex : grisSinColor(hex)}
            fillRule="evenodd"
            stroke="#555555"
            strokeWidth={1 / escala}
          />
        );
      })}
    </Svg>
  );
}

export const Miniatura = memo(MiniaturaBase);
