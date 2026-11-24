/**
 * Mis obras: cuadros empezados (para retomarlos) y terminados (colección).
 */
import { Link } from 'expo-router';
import { Pressable, SectionList, StyleSheet, Text, View } from 'react-native';

import { Miniatura } from '@/components/Miniatura';
import { METAS_CUADROS, obtenerCuadro } from '@/data/cuadros';
import { porcentajeCompletado, sanearPintadas } from '@/engine';
import { type Obra, clasificarObras } from '@/store/obras';
import { useProgreso } from '@/store/progreso';

const IDS = new Set(METAS_CUADROS.map((m) => m.id));

export default function MisObras() {
  const cuadros = useProgreso((s) => s.cuadros);
  const { enProgreso, terminadas } = clasificarObras(cuadros, IDS);

  if (enProgreso.length === 0 && terminadas.length === 0) {
    return (
      <View style={styles.vacio}>
        <Text style={styles.vacioTitulo}>Todavía no hay obras</Text>
        <Text style={styles.vacioTexto}>
          Elegí un cuadro en la Galería y empezá a devolverle sus colores.
        </Text>
        <Link href="/galeria" asChild>
          <Pressable style={styles.boton} accessibilityRole="button">
            <Text style={styles.textoBoton}>Ir a la Galería</Text>
          </Pressable>
        </Link>
      </View>
    );
  }

  const secciones = [
    { titulo: 'En progreso', data: enProgreso },
    { titulo: 'Terminadas', data: terminadas },
  ].filter((s) => s.data.length > 0);

  return (
    <SectionList
      sections={secciones}
      keyExtractor={(o) => o.cuadroId}
      contentContainerStyle={styles.lista}
      stickySectionHeadersEnabled={false}
      renderSectionHeader={({ section }) => (
        <Text style={styles.seccion}>
          {section.titulo} ({section.data.length})
        </Text>
      )}
      renderItem={({ item }) => <TarjetaObra obra={item} />}
    />
  );
}

function TarjetaObra({ obra }: { obra: Obra }) {
  const cuadro = obtenerCuadro(obra.cuadroId);
  if (!cuadro) return null;
  const pintadas = sanearPintadas(cuadro, obra.progreso.pintadas);
  const terminada = obra.progreso.completadoEn !== undefined;
  const fecha = new Date(
    (terminada ? obra.progreso.completadoEn : obra.progreso.actualizadoEn) ?? 0,
  ).toLocaleDateString('es-AR');

  return (
    <Link href={{ pathname: '/pintar/[id]', params: { id: cuadro.id } }} asChild>
      <Pressable
        style={styles.tarjeta}
        accessibilityRole="button"
        accessibilityLabel={`${cuadro.titulo}, ${terminada ? 'terminada' : `${porcentajeCompletado(cuadro, pintadas)}%`}`}
      >
        <Miniatura cuadro={cuadro} pintadas={pintadas} tamano={72} />
        <View style={styles.textos}>
          <Text style={styles.titulo}>{cuadro.titulo}</Text>
          <Text style={styles.detalle}>
            {terminada ? `Terminada el ${fecha}` : `Última pincelada: ${fecha}`}
          </Text>
          {!terminada && (
            <View style={styles.barra}>
              <View
                style={[styles.relleno, { width: `${porcentajeCompletado(cuadro, pintadas)}%` }]}
              />
            </View>
          )}
        </View>
        <Text style={[styles.estado, terminada && styles.terminada]}>
          {terminada ? '¡Con color!' : `${porcentajeCompletado(cuadro, pintadas)}%`}
        </Text>
      </Pressable>
    </Link>
  );
}

const styles = StyleSheet.create({
  lista: { padding: 16, gap: 12 },
  seccion: { fontSize: 18, fontWeight: '800', color: '#3D2C5E', marginTop: 8 },
  tarjeta: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 12,
    elevation: 2,
    shadowColor: '#000000',
    shadowOpacity: 0.08,
    shadowRadius: 6,
  },
  textos: { flex: 1, gap: 4 },
  titulo: { fontSize: 17, fontWeight: '700', color: '#3D2C5E' },
  detalle: { fontSize: 13, color: '#777777' },
  barra: { height: 6, borderRadius: 3, backgroundColor: '#EEEEEE', overflow: 'hidden' },
  relleno: { height: 6, backgroundColor: '#8E7CC3' },
  estado: { fontSize: 15, fontWeight: '700', color: '#999999' },
  terminada: { color: '#38761D' },
  vacio: { flex: 1, alignItems: 'center', justifyContent: 'center', padding: 32, gap: 12 },
  vacioTitulo: { fontSize: 20, fontWeight: '800', color: '#3D2C5E' },
  vacioTexto: { fontSize: 15, color: '#666666', textAlign: 'center' },
  boton: {
    backgroundColor: '#3D2C5E',
    paddingVertical: 10,
    paddingHorizontal: 24,
    borderRadius: 20,
    marginTop: 8,
  },
  textoBoton: { color: '#FFFFFF', fontWeight: '700' },
});
