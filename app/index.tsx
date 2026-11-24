/** Pantalla de inicio. */
import { Link } from 'expo-router';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

export default function Inicio() {
  return (
    <SafeAreaView style={styles.pantalla}>
      <View style={styles.centro}>
        <Text style={styles.titulo}>Colores de Gramonia</Text>
        <Text style={styles.historia}>
          Mututu se llevó los colores de un montón de cuadros. Pintalos número por número y
          devolvéselos.
        </Text>
        <Link href="/galeria" asChild>
          <Pressable style={styles.boton} accessibilityRole="button">
            <Text style={styles.textoBoton}>Pintar</Text>
          </Pressable>
        </Link>
        <Link href="/mapa" asChild>
          <Pressable style={styles.botonSecundario} accessibilityRole="button">
            <Text style={[styles.textoBoton, styles.textoSecundario]}>Mapa de biomas</Text>
          </Pressable>
        </Link>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  pantalla: { flex: 1, backgroundColor: '#FFF8EC' },
  centro: { flex: 1, alignItems: 'center', justifyContent: 'center', padding: 24, gap: 16 },
  titulo: { fontSize: 32, fontWeight: '800', textAlign: 'center', color: '#3D2C5E' },
  historia: { fontSize: 16, textAlign: 'center', color: '#555555', marginBottom: 16 },
  boton: {
    backgroundColor: '#3D2C5E',
    paddingVertical: 14,
    borderRadius: 28,
    width: 240,
    alignItems: 'center',
  },
  botonSecundario: {
    paddingVertical: 12,
    borderRadius: 28,
    width: 240,
    alignItems: 'center',
    borderWidth: 2,
    borderColor: '#3D2C5E',
  },
  textoBoton: { color: '#FFFFFF', fontSize: 18, fontWeight: '700' },
  textoSecundario: { color: '#3D2C5E' },
});
