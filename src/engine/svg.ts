/**
 * Lector mínimo del formato SVG de los cuadros.
 *
 * Formato esperado (ver docs/formato-cuadros.md):
 *   <svg viewBox="0 0 ANCHO ALTO">
 *     <path id="cielo" data-numero="1" d="..." />
 *     <path id="sol" data-numero="2" data-etiqueta="230 50" d="..." />
 *   </svg>
 *
 * Solo se leen elementos <path>; el resto (grupos, estilos) se ignora.
 * No es un parser XML general: alcanza para los archivos que generamos.
 */

export type PathCrudo = {
  id: string;
  numero: number;
  d: string;
  /** Posición del número fijada a mano o por el conversor (opcional). */
  etiqueta?: { x: number; y: number };
};

export type SvgCrudo = {
  ancho: number;
  alto: number;
  paths: PathCrudo[];
};

function atributos(tag: string): Record<string, string> {
  const attrs: Record<string, string> = {};
  const re = /([\w:-]+)\s*=\s*"([^"]*)"/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(tag)) !== null) attrs[m[1]] = m[2];
  return attrs;
}

export function leerSvg(texto: string): SvgCrudo {
  const svgTag = texto.match(/<svg\b[^>]*>/);
  if (!svgTag) throw new Error('No se encontró la etiqueta <svg>');
  const viewBox = atributos(svgTag[0]).viewBox;
  if (!viewBox) throw new Error('El <svg> necesita un atributo viewBox');
  const [, , ancho, alto] = viewBox
    .trim()
    .split(/[\s,]+/)
    .map(Number);

  const paths: PathCrudo[] = [];
  const ids = new Set<string>();
  for (const m of texto.matchAll(/<path\b[^>]*>/g)) {
    const a = atributos(m[0]);
    if (!a.id) throw new Error(`Path sin id: ${m[0].slice(0, 60)}`);
    if (ids.has(a.id)) throw new Error(`Id repetido: "${a.id}"`);
    ids.add(a.id);
    const numero = Number(a['data-numero']);
    if (!Number.isInteger(numero) || numero < 1) {
      throw new Error(`El path "${a.id}" necesita data-numero entero >= 1`);
    }
    if (!a.d) throw new Error(`El path "${a.id}" no tiene atributo d`);
    let etiqueta: PathCrudo['etiqueta'];
    if (a['data-etiqueta']) {
      const [x, y] = a['data-etiqueta'].split(/[\s,]+/).map(Number);
      etiqueta = { x, y };
    }
    paths.push({ id: a.id, numero, d: a.d, etiqueta });
  }
  return { ancho, alto, paths };
}
