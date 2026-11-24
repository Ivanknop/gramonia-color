/**
 * Dibuja un cuadro: regiones pintadas con su color, el resto en gris con su
 * número. Las regiones del color elegido que faltan se resaltan.
 *
 * Versión inicial: el toque se resuelve con Pressable y el motor
 * (regionEnPunto). En la etapa de gestos se reemplaza por zoom/paneo con
 * react-native-gesture-handler + reanimated, manteniendo la misma API.
 */
import { memo, useMemo, useState } from 'react';
import { type LayoutChangeEvent, Pressable, StyleSheet, View } from 'react-native';
import Svg, { Path, Text as SvgText } from 'react-native-svg';

import { type Cuadro, type Punto, grisSinColor } from '@/engine';

type Props = {
  cuadro: Cuadro;
  pintadas: ReadonlySet<string>;
  /** Número de paleta elegido (para resaltar sus regiones). */
  numeroElegido: number | null;
  /** Toque en coordenadas del viewBox del cuadro. */
  onToque: (p: Punto) => void;
};

const RESALTE = '#9a9a9a';

function LienzoBase({ cuadro, pintadas, numeroElegido, onToque }: Props) {
  const [ancho, setAncho] = useState(0);
  const escala = ancho > 0 ? cuadro.ancho / ancho : 1;

  const colores = useMemo(
    () => new Map(cuadro.paleta.map((c) => [c.numero, c.hex] as const)),
    [cuadro],
  );

  const onLayout = (e: LayoutChangeEvent) => setAncho(e.nativeEvent.layout.width);

  return (
    <View style={styles.contenedor} onLayout={onLayout}>
      <Pressable
        accessibilityLabel={`Cuadro ${cuadro.titulo}`}
        onPress={(e) =>
          onToque({ x: e.nativeEvent.locationX * escala, y: e.nativeEvent.locationY * escala })
        }
      >
        <Svg
          width={ancho}
          height={(ancho * cuadro.alto) / cuadro.ancho}
          viewBox={`0 0 ${cuadro.ancho} ${cuadro.alto}`}
        >
          {cuadro.regiones.map((r) => {
            const hex = colores.get(r.numero) ?? '#000000';
            const pintada = pintadas.has(r.id);
            const resaltada = !pintada && r.numero === numeroElegido;
            return (
              <Path
                key={r.id}
                d={r.d}
                fill={pintada ? hex : resaltada ? RESALTE : grisSinColor(hex)}
                fillRule="evenodd"
                stroke="#444444"
                strokeWidth={0.8}
              />
            );
          })}
          {cuadro.regiones
            .filter((r) => !pintadas.has(r.id))
            .map((r) => (
              <SvgText
                key={`n-${r.id}`}
                x={r.etiqueta.x}
                y={r.etiqueta.y}
                fontSize={Math.max(4, Math.min(18, r.radioEtiqueta * 1.1))}
                fill="#333333"
                textAnchor="middle"
                alignmentBaseline="central"
              >
                {r.numero}
              </SvgText>
            ))}
        </Svg>
      </Pressable>
    </View>
  );
}

export const Lienzo = memo(LienzoBase);

const styles = StyleSheet.create({
  contenedor: { width: '100%' },
});
