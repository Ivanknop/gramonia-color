/**
 * Cuentas de la vista del lienzo: zoom, desplazamiento y conversión de
 * coordenadas de pantalla a coordenadas del cuadro.
 *
 * Modelo: el cuadro se dibuja ajustado al contenedor ("tamaño base", factor
 * `base` puntos por unidad del viewBox). Encima se aplica una transformación
 * con origen arriba a la izquierda:
 *
 *     pantalla = desplazamiento + escala * punto_en_contenido
 *
 * Las funciones llevan la directiva 'worklet' para poder llamarse desde los
 * gestos en el hilo de UI (Reanimated); en Jest y en JS común son funciones
 * normales.
 */

export type Vista = { escala: number; x: number; y: number };
export type Tamano = { ancho: number; alto: number };

/** Puntos de pantalla por unidad del viewBox con el cuadro ajustado (zoom 1). */
export function factorBase(contenedor: Tamano, cuadro: Tamano): number {
  'worklet';
  if (cuadro.ancho <= 0 || cuadro.alto <= 0) return 1;
  return Math.min(contenedor.ancho / cuadro.ancho, contenedor.alto / cuadro.alto);
}

/** Vista inicial: zoom 1 y el cuadro centrado. */
export function vistaInicial(contenedor: Tamano, cuadro: Tamano): Vista {
  'worklet';
  const f = factorBase(contenedor, cuadro);
  return {
    escala: 1,
    x: (contenedor.ancho - cuadro.ancho * f) / 2,
    y: (contenedor.alto - cuadro.alto * f) / 2,
  };
}

function limitarEje(pos: number, tamanoEscalado: number, contenedor: number): number {
  'worklet';
  // Si entra entero, centrado; si no, sin dejar ver "afuera" del cuadro.
  if (tamanoEscalado <= contenedor) return (contenedor - tamanoEscalado) / 2;
  return Math.min(0, Math.max(contenedor - tamanoEscalado, pos));
}

/** Ajusta escala y desplazamiento para no perder el cuadro de vista. */
export function limitarVista(
  v: Vista,
  contenedor: Tamano,
  cuadro: Tamano,
  escalaMax: number,
): Vista {
  'worklet';
  const escala = Math.min(escalaMax, Math.max(1, v.escala));
  const f = factorBase(contenedor, cuadro);
  return {
    escala,
    x: limitarEje(v.x, cuadro.ancho * f * escala, contenedor.ancho),
    y: limitarEje(v.y, cuadro.alto * f * escala, contenedor.alto),
  };
}

/**
 * Zoom con dos dedos: parte de la vista al comenzar el gesto y mantiene bajo
 * los dedos el mismo punto del cuadro (permite además arrastrar mientras se
 * pellizca, porque el foco puede moverse).
 */
export function aplicarPellizco(
  inicio: Vista,
  focoInicio: { x: number; y: number },
  foco: { x: number; y: number },
  factorEscala: number,
): Vista {
  'worklet';
  const escala = inicio.escala * factorEscala;
  // Punto del contenido que estaba bajo los dedos al empezar.
  const px = (focoInicio.x - inicio.x) / inicio.escala;
  const py = (focoInicio.y - inicio.y) / inicio.escala;
  return { escala, x: foco.x - escala * px, y: foco.y - escala * py };
}

/** Convierte un toque (coordenadas del contenedor) a coordenadas del viewBox. */
export function pantallaACuadro(
  v: Vista,
  toque: { x: number; y: number },
  contenedor: Tamano,
  cuadro: Tamano,
): { x: number; y: number } {
  'worklet';
  const f = factorBase(contenedor, cuadro);
  return { x: (toque.x - v.x) / (v.escala * f), y: (toque.y - v.y) / (v.escala * f) };
}

/**
 * Zoom máximo: el suficiente para que el número más chico del cuadro se lea
 * (al menos `tamanoLegible` puntos) y la región más chica se pueda tocar con
 * el dedo (radio de al menos `radioTocable` puntos). Entre 4x y 16x.
 */
export function escalaMaxima(
  tamanosNumero: readonly number[],
  radios: readonly number[],
  factor: number,
  tamanoLegible = 14,
  radioTocable = 10,
): number {
  if (tamanosNumero.length === 0 || factor <= 0) return 4;
  let menorNumero = Infinity;
  for (const t of tamanosNumero) menorNumero = Math.min(menorNumero, t);
  let menorRadio = Infinity;
  for (const r of radios) menorRadio = Math.min(menorRadio, r);
  const porNumero = tamanoLegible / (menorNumero * factor);
  const porRadio = menorRadio > 0 ? radioTocable / (menorRadio * factor) : 0;
  return Math.min(16, Math.max(4, porNumero, porRadio));
}

/**
 * Tamaño de fuente (en unidades del viewBox) del número de una región:
 * proporcional al espacio libre para que entre en la región, entre 1.2 y 18.
 * Los números chicos se leen con zoom (ver escalaMaxima).
 */
export function tamanoNumero(radioEtiqueta: number): number {
  return Math.max(1.2, Math.min(18, radioEtiqueta * 1.1));
}
