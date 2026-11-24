/**
 * Paleta de colores numerados. Los colores ya terminados se muestran con ✓.
 */
import { Pressable, ScrollView, StyleSheet, Text } from 'react-native';

import { type ColorPaleta, textoSobre } from '@/engine';

type Props = {
  paleta: ColorPaleta[];
  elegido: number | null;
  /** Números de color que ya no tienen regiones pendientes. */
  completos: ReadonlySet<number>;
  onElegir: (numero: number) => void;
};

export function Paleta({ paleta, elegido, completos, onElegir }: Props) {
  return (
    <ScrollView
      horizontal
      contentContainerStyle={styles.fila}
      showsHorizontalScrollIndicator={false}
    >
      {paleta.map((c) => {
        const completo = completos.has(c.numero);
        return (
          <Pressable
            key={c.numero}
            accessibilityRole="button"
            accessibilityLabel={`Color ${c.numero}, ${c.nombre}${completo ? ', completo' : ''}`}
            accessibilityState={{ selected: elegido === c.numero }}
            onPress={() => onElegir(c.numero)}
            style={[
              styles.color,
              { backgroundColor: c.hex },
              elegido === c.numero && styles.elegido,
              completo && styles.completo,
            ]}
          >
            <Text style={[styles.numero, { color: textoSobre(c.hex) }]}>
              {completo ? '✓' : c.numero}
            </Text>
          </Pressable>
        );
      })}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  fila: { gap: 10, paddingHorizontal: 16, paddingVertical: 12 },
  color: {
    width: 52,
    height: 52,
    borderRadius: 26,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 2,
    borderColor: '#00000022',
  },
  elegido: { borderWidth: 4, borderColor: '#222222', transform: [{ scale: 1.1 }] },
  completo: { opacity: 0.45 },
  numero: { fontSize: 18, fontWeight: '700' },
});
