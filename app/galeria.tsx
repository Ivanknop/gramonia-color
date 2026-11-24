/** Galería de cuadros con su avance. */
import { Link } from 'expo-router';
import { FlatList, Pressable, StyleSheet, Text, View } from 'react-native';

import { METAS_CUADROS, obtenerCuadro } from '@/data/cuadros';
import { porcentajeCompletado, sanearPintadas } from '@/engine';
import { useProgreso } from '@/store/progreso';

export default function Galeria() {
  const progreso = useProgreso((s) => s.cuadros);

  return (
    <FlatList
      data={METAS_CUADROS}
      keyExtractor={(m) => m.id}
      contentContainerStyle={styles.lista}
      renderItem={({ item }) => {
        const cuadro = obtenerCuadro(item.id);
        const p = progreso[item.id];
        const porcentaje =
          cuadro && p ? porcentajeCompletado(cuadro, sanearPintadas(cuadro, p.pintadas)) : 0;
        const terminado = p?.completadoEn !== undefined;
        return (
          <Link href={{ pathname: '/pintar/[id]', params: { id: item.id } }} asChild>
            <Pressable style={styles.tarjeta} accessibilityRole="button">
              <View style={styles.textos}>
                <Text style={styles.titulo}>{item.titulo}</Text>
                <Text style={styles.detalle}>
                  {item.categoria} · dificultad {item.dificultad}
                </Text>
              </View>
              <Text style={[styles.avance, terminado && styles.terminado]}>
                {terminado ? '¡Con color!' : `${porcentaje}%`}
              </Text>
            </Pressable>
          </Link>
        );
      }}
    />
  );
}

const styles = StyleSheet.create({
  lista: { padding: 16, gap: 12 },
  tarjeta: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 16,
    elevation: 2,
    shadowColor: '#000000',
    shadowOpacity: 0.08,
    shadowRadius: 6,
  },
  textos: { flex: 1 },
  titulo: { fontSize: 18, fontWeight: '700', color: '#3D2C5E' },
  detalle: { fontSize: 14, color: '#777777', marginTop: 2 },
  avance: { fontSize: 16, fontWeight: '700', color: '#999999' },
  terminado: { color: '#38761D' },
});
