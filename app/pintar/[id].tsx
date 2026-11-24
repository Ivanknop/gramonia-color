/**
 * Pantalla de pintar. Versión inicial: tocar para pintar, resaltado del color
 * elegido y un panel simple al completar. La animación de devolver el color,
 * el sonido, la vibración y el zoom/paneo llegan en las etapas siguientes.
 */
import { Link, Stack, useLocalSearchParams } from 'expo-router';
import { useCallback, useMemo, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';

import { Lienzo } from '@/components/Lienzo';
import { Paleta } from '@/components/Paleta';
import { BIOMAS } from '@/data/biomas';
import { obtenerCuadro } from '@/data/cuadros';
import {
  type Punto,
  faltantesDeColor,
  intentarPintar,
  piezaDeCuadro,
  porcentajeCompletado,
  sanearPintadas,
} from '@/engine';
import { useProgreso } from '@/store/progreso';

export default function Pintar() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const cuadro = useMemo(() => obtenerCuadro(id), [id]);
  const ids = useProgreso((s) => s.cuadros[id]?.pintadas);
  const completadoEn = useProgreso((s) => s.cuadros[id]?.completadoEn);
  const pintarRegion = useProgreso((s) => s.pintarRegion);
  const marcarCompletado = useProgreso((s) => s.marcarCompletado);

  const pintadas = useMemo(
    () => (cuadro ? sanearPintadas(cuadro, ids ?? []) : new Set<string>()),
    [cuadro, ids],
  );
  const completos = useMemo(
    () =>
      new Set(
        (cuadro?.paleta ?? [])
          .filter((c) => cuadro && faltantesDeColor(cuadro, pintadas, c.numero) === 0)
          .map((c) => c.numero),
      ),
    [cuadro, pintadas],
  );
  const [elegido, setElegido] = useState<number | null>(cuadro?.paleta[0]?.numero ?? null);

  const onToque = useCallback(
    (p: Punto) => {
      if (!cuadro || elegido === null) return;
      const r = intentarPintar(cuadro, pintadas, p, elegido);
      if (r.tipo !== 'correcto') return; // TODO etapa 3: feedback háptico/sonoro al errar
      pintarRegion(cuadro.id, r.regionId);
      if (r.cuadroCompleto) marcarCompletado(cuadro.id);
      else if (r.colorCompleto) {
        // Pasar solo al siguiente color con regiones pendientes.
        const siguiente = cuadro.paleta.find(
          (c) => c.numero !== elegido && !completos.has(c.numero),
        );
        if (siguiente) setElegido(siguiente.numero);
      }
    },
    [cuadro, elegido, pintadas, completos, pintarRegion, marcarCompletado],
  );

  if (!cuadro) {
    return (
      <View style={styles.centro}>
        <Text>No encontramos ese cuadro.</Text>
      </View>
    );
  }

  const terminado = completadoEn !== undefined;
  const destapa = piezaDeCuadro(BIOMAS, cuadro.id);

  return (
    <View style={styles.pantalla}>
      <Stack.Screen options={{ title: cuadro.titulo }} />
      <ScrollView contentContainerStyle={styles.contenido}>
        <Text style={styles.avance}>{porcentajeCompletado(cuadro, pintadas)}% con color</Text>
        <Lienzo cuadro={cuadro} pintadas={pintadas} numeroElegido={elegido} onToque={onToque} />
        {terminado && (
          <View style={styles.panelFinal}>
            <Text style={styles.mensaje}>{cuadro.mensajeMututu}</Text>
            {destapa && (
              <Text style={styles.pieza}>Destapaste una pieza de {destapa.bioma.nombre}.</Text>
            )}
            <Link href="/mapa" asChild>
              <Pressable style={styles.boton} accessibilityRole="button">
                <Text style={styles.textoBoton}>Ver el mapa</Text>
              </Pressable>
            </Link>
          </View>
        )}
      </ScrollView>
      {!terminado && (
        <Paleta
          paleta={cuadro.paleta}
          elegido={elegido}
          completos={completos}
          onElegir={setElegido}
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  pantalla: { flex: 1, backgroundColor: '#FFFFFF' },
  contenido: { padding: 12, gap: 12 },
  centro: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  avance: { fontSize: 14, color: '#777777', textAlign: 'center' },
  panelFinal: { backgroundColor: '#FFF8EC', borderRadius: 12, padding: 16, gap: 10 },
  mensaje: { fontSize: 16, color: '#3D2C5E', textAlign: 'center' },
  pieza: { fontSize: 15, fontWeight: '700', color: '#38761D', textAlign: 'center' },
  boton: {
    alignSelf: 'center',
    backgroundColor: '#3D2C5E',
    paddingVertical: 10,
    paddingHorizontal: 24,
    borderRadius: 20,
  },
  textoBoton: { color: '#FFFFFF', fontWeight: '700' },
});
