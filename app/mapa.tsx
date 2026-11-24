/**
 * Mapa de biomas. Versión provisoria: cada bioma es una grilla de piezas;
 * las destapadas se ven con el color del bioma. El arte real de cada pieza
 * llega en la etapa del mapa.
 */
import { ScrollView, StyleSheet, Text, View } from 'react-native';

import { BIOMAS } from '@/data/biomas';
import { estadoBioma } from '@/engine';
import { cuadrosCompletados, useProgreso } from '@/store/progreso';

export default function Mapa() {
  const cuadros = useProgreso((s) => s.cuadros);
  const completados = cuadrosCompletados(cuadros);

  return (
    <ScrollView contentContainerStyle={styles.contenido}>
      {BIOMAS.map((bioma) => {
        const estado = estadoBioma(bioma, completados);
        const celdas = Array.from({ length: bioma.filas * bioma.columnas }, (_, i) => {
          const fila = Math.floor(i / bioma.columnas);
          const columna = i % bioma.columnas;
          const pieza = bioma.piezas.find((p) => p.fila === fila && p.columna === columna);
          return {
            clave: `${fila}-${columna}`,
            revelada: !!pieza && estado.reveladas.has(pieza.id),
          };
        });
        return (
          <View key={bioma.id} style={styles.bioma}>
            <Text style={styles.nombre}>
              {bioma.nombre} {estado.desbloqueado ? '★' : ''}
            </Text>
            <Text style={styles.detalle}>
              {estado.desbloqueado
                ? bioma.descripcion
                : `${estado.reveladas.size} de ${estado.total} piezas destapadas`}
            </Text>
            <View style={styles.grilla}>
              {celdas.map((c) => (
                <View
                  key={c.clave}
                  style={[
                    styles.celda,
                    { width: `${100 / bioma.columnas}%` },
                    c.revelada ? { backgroundColor: bioma.color } : styles.oculta,
                  ]}
                >
                  {!c.revelada && <Text style={styles.signo}>?</Text>}
                </View>
              ))}
            </View>
          </View>
        );
      })}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  contenido: { padding: 16, gap: 20 },
  bioma: { gap: 6 },
  nombre: { fontSize: 20, fontWeight: '800', color: '#3D2C5E' },
  detalle: { fontSize: 14, color: '#666666' },
  grilla: { flexDirection: 'row', flexWrap: 'wrap', borderRadius: 12, overflow: 'hidden' },
  celda: {
    aspectRatio: 1,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: '#FFFFFF',
  },
  oculta: { backgroundColor: '#D9D9D9' },
  signo: { fontSize: 28, color: '#999999', fontWeight: '800' },
});
