/**
 * Dibuja un cuadro con zoom y paneo: regiones pintadas con su color, el resto
 * en gris con su número; las regiones del color elegido que faltan se
 * resaltan.
 *
 * Gestos (react-native-gesture-handler 3, en el hilo de UI con Reanimated):
 *  - pellizcar: zoom, manteniendo fijo el punto bajo los dedos;
 *  - arrastrar con un dedo: mover el cuadro (cuando hay zoom);
 *  - tocar: pintar. El toque se convierte a coordenadas del viewBox y el
 *    motor (regionEnPunto) decide qué región es.
 * Botón "Encuadrar" para volver al zoom inicial.
 *
 * El SVG se dibuja una vez al tamaño base y el zoom es una transformación de
 * la vista. PENDIENTE de verificar en dispositivo: nitidez a zoom alto (si se
 * ve borroso, recalcular el viewBox al terminar cada gesto).
 */
import { memo, useEffect, useMemo, useState } from 'react';
import { type LayoutChangeEvent, Pressable, StyleSheet, Text, View } from 'react-native';
import {
  GestureDetector,
  useCompetingGestures,
  usePanGesture,
  usePinchGesture,
  useSimultaneousGestures,
  useTapGesture,
} from 'react-native-gesture-handler';
import Animated, { useAnimatedStyle, useSharedValue, withTiming } from 'react-native-reanimated';
import Svg, { Path, Text as SvgText } from 'react-native-svg';
import { scheduleOnRN } from 'react-native-worklets';

import {
  type Cuadro,
  type Punto,
  type Tamano,
  aplicarPellizco,
  escalaMaxima,
  factorBase,
  grisSinColor,
  limitarVista,
  pantallaACuadro,
  tamanoNumero,
  vistaInicial,
} from '@/engine';

type Props = {
  cuadro: Cuadro;
  pintadas: ReadonlySet<string>;
  /** Número de paleta elegido (para resaltar sus regiones). */
  numeroElegido: number | null;
  /** Toque en coordenadas del viewBox del cuadro. */
  onToque: (p: Punto) => void;
};

const RESALTE = '#9a9a9a';
const BORDE = '#555555';
/** Ancho del contorno en unidades del viewBox (~300 de lado mayor). */
const ANCHO_BORDE = 0.4;
const DURACION_ENCUADRE = 250;

function LienzoBase({ cuadro, pintadas, numeroElegido, onToque }: Props) {
  const [contenedor, setContenedor] = useState<Tamano>({ ancho: 0, alto: 0 });
  // Solo datos planos dentro de los worklets (no el cuadro entero).
  const tamCuadro = useMemo(() => ({ ancho: cuadro.ancho, alto: cuadro.alto }), [cuadro]);
  const factor = factorBase(contenedor, tamCuadro);
  const maxEscala = useMemo(
    () =>
      escalaMaxima(
        cuadro.regiones.map((r) => tamanoNumero(r.radioEtiqueta)),
        cuadro.regiones.map((r) => r.radioEtiqueta),
        factor,
      ),
    [cuadro, factor],
  );

  // Estado de la vista en el hilo de UI.
  const escala = useSharedValue(1);
  const x = useSharedValue(0);
  const y = useSharedValue(0);
  const tam = useSharedValue<Tamano>({ ancho: 0, alto: 0 });
  const max = useSharedValue(maxEscala);
  useEffect(() => {
    max.set(maxEscala);
  }, [max, maxEscala]);
  // Datos al comenzar un pellizco.
  const inicio = useSharedValue({ escala: 1, x: 0, y: 0, focoX: 0, focoY: 0 });
  const pellizcando = useSharedValue(false);

  const [zoomeado, setZoomeado] = useState(false);

  const onLayout = (e: LayoutChangeEvent) => {
    const { width, height } = e.nativeEvent.layout;
    const nuevo = { ancho: width, alto: height };
    setContenedor(nuevo);
    tam.set(nuevo);
    const v = vistaInicial(nuevo, tamCuadro);
    escala.set(v.escala);
    x.set(v.x);
    y.set(v.y);
    setZoomeado(false);
  };

  const pellizco = usePinchGesture({
    onActivate: (e) => {
      'worklet';
      pellizcando.value = true;
      inicio.value = {
        escala: escala.value,
        x: x.value,
        y: y.value,
        focoX: e.focalX,
        focoY: e.focalY,
      };
    },
    onUpdate: (e) => {
      'worklet';
      const i = inicio.value;
      const v = limitarVista(
        aplicarPellizco(
          { escala: i.escala, x: i.x, y: i.y },
          { x: i.focoX, y: i.focoY },
          { x: e.focalX, y: e.focalY },
          e.scale,
        ),
        tam.value,
        tamCuadro,
        max.value,
      );
      escala.value = v.escala;
      x.value = v.x;
      y.value = v.y;
    },
    onFinalize: () => {
      'worklet';
      pellizcando.value = false;
      scheduleOnRN(setZoomeado, escala.value > 1.01);
    },
  });

  const arrastre = usePanGesture({
    maxPointers: 1,
    onUpdate: (e) => {
      'worklet';
      if (pellizcando.value) return; // el pellizco ya mueve la vista
      const v = limitarVista(
        { escala: escala.value, x: x.value + e.changeX, y: y.value + e.changeY },
        tam.value,
        tamCuadro,
        max.value,
      );
      x.value = v.x;
      y.value = v.y;
    },
  });

  // El toque corre en JS (runOnJS): solo convierte coordenadas y llama al
  // motor, no anima nada, así que no necesita el hilo de UI.
  const toque = useTapGesture({
    testID: 'lienzo-toque',
    runOnJS: true,
    onActivate: (e) => {
      onToque(
        pantallaACuadro(
          { escala: escala.get(), x: x.get(), y: y.get() },
          { x: e.x, y: e.y },
          contenedor,
          tamCuadro,
        ),
      );
    },
  });

  // Pellizco y arrastre a la vez; el toque compite con ellos (si el dedo se
  // mueve, gana el arrastre y no se pinta).
  const gestos = useCompetingGestures(useSimultaneousGestures(pellizco, arrastre), toque);

  const estiloVista = useAnimatedStyle(() => ({
    transform: [{ translateX: x.value }, { translateY: y.value }, { scale: escala.value }],
  }));

  const encuadrar = () => {
    const v = vistaInicial(contenedor, tamCuadro);
    escala.set(withTiming(v.escala, { duration: DURACION_ENCUADRE }));
    x.set(withTiming(v.x, { duration: DURACION_ENCUADRE }));
    y.set(withTiming(v.y, { duration: DURACION_ENCUADRE }));
    setZoomeado(false);
  };

  const colores = useMemo(
    () => new Map(cuadro.paleta.map((c) => [c.numero, c.hex] as const)),
    [cuadro],
  );
  const grisesPorColor = useMemo(
    () => new Map(cuadro.paleta.map((c) => [c.hex, grisSinColor(c.hex)] as const)),
    [cuadro],
  );
  const anchoBase = cuadro.ancho * factor;
  const altoBase = cuadro.alto * factor;

  return (
    <View style={styles.contenedor} onLayout={onLayout} testID="lienzo">
      <GestureDetector gesture={gestos}>
        <View style={StyleSheet.absoluteFill} accessibilityLabel={`Cuadro ${cuadro.titulo}`}>
          {factor > 0 && (
            <Animated.View
              style={[styles.contenido, { width: anchoBase, height: altoBase }, estiloVista]}
            >
              <Svg
                width={anchoBase}
                height={altoBase}
                viewBox={`0 0 ${cuadro.ancho} ${cuadro.alto}`}
              >
                {cuadro.regiones.map((r) => {
                  const hex = colores.get(r.numero) ?? '#000000';
                  const pintada = pintadas.has(r.id);
                  const resaltada = !pintada && r.numero === numeroElegido;
                  return (
                    <RegionDibujo
                      key={r.id}
                      d={r.d}
                      relleno={pintada ? hex : resaltada ? RESALTE : grisesPorColor.get(hex)!}
                      // Pintada: el borde toma su color y el cuadro terminado no
                      // queda cuadriculado.
                      borde={pintada ? hex : BORDE}
                    />
                  );
                })}
                {cuadro.regiones.map((r) =>
                  pintadas.has(r.id) ? null : (
                    <Numero
                      key={`n-${r.id}`}
                      x={r.etiqueta.x}
                      y={r.etiqueta.y}
                      tamano={tamanoNumero(r.radioEtiqueta)}
                      numero={r.numero}
                    />
                  ),
                )}
              </Svg>
            </Animated.View>
          )}
        </View>
      </GestureDetector>
      {zoomeado && (
        <Pressable
          style={styles.encuadrar}
          onPress={encuadrar}
          accessibilityRole="button"
          accessibilityLabel="Encuadrar el cuadro"
        >
          <Text style={styles.textoEncuadrar}>Encuadrar</Text>
        </Pressable>
      )}
    </View>
  );
}

export const Lienzo = memo(LienzoBase);

/*
 * Región y número memorizados: con cuadros de cientos de regiones, cada toque
 * solo vuelve a dibujar lo que cambió (la región pintada y el resaltado).
 */
const RegionDibujo = memo(function RegionDibujo({
  d,
  relleno,
  borde,
}: {
  d: string;
  relleno: string;
  borde: string;
}) {
  return <Path d={d} fill={relleno} fillRule="evenodd" stroke={borde} strokeWidth={ANCHO_BORDE} />;
});

const Numero = memo(function Numero({
  x,
  y,
  tamano,
  numero,
}: {
  x: number;
  y: number;
  tamano: number;
  numero: number;
}) {
  return (
    <SvgText
      x={x}
      y={y}
      fontSize={tamano}
      fill="#333333"
      textAnchor="middle"
      alignmentBaseline="central"
    >
      {numero}
    </SvgText>
  );
});

const styles = StyleSheet.create({
  contenedor: { flex: 1, overflow: 'hidden', backgroundColor: '#F4F1EA' },
  // La transformación se aplica desde la esquina superior izquierda, que es
  // lo que asumen las cuentas de src/engine/vista.ts.
  contenido: { position: 'absolute', left: 0, top: 0, transformOrigin: 'left top' },
  encuadrar: {
    position: 'absolute',
    right: 12,
    top: 12,
    backgroundColor: '#FFFFFFEE',
    borderRadius: 16,
    paddingHorizontal: 12,
    paddingVertical: 6,
    elevation: 2,
  },
  textoEncuadrar: { fontWeight: '700', color: '#3D2C5E' },
});
