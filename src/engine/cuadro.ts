/**
 * Arma un Cuadro listo para jugar a partir de su JSON de metadatos y su SVG.
 */
import { calcularEtiqueta } from './etiquetas';
import { aplanarPath, cajaDe } from './geometria';
import { leerSvg } from './svg';
import type { Cuadro, MetaCuadro, Region } from './tipos';

const HEX = /^#[0-9a-fA-F]{6}$/;

export function construirCuadro(meta: MetaCuadro, svgTexto: string): Cuadro {
  const svg = leerSvg(svgTexto);
  const error = (msg: string) => new Error(`Cuadro "${meta.id}": ${msg}`);

  const numeros = new Set<number>();
  for (const c of meta.paleta) {
    if (numeros.has(c.numero)) throw error(`número de paleta repetido: ${c.numero}`);
    if (!HEX.test(c.hex)) throw error(`color inválido "${c.hex}" (usar #RRGGBB)`);
    numeros.add(c.numero);
  }

  const formas = svg.paths.map((p) => {
    if (!numeros.has(p.numero)) {
      throw error(`la región "${p.id}" usa el número ${p.numero}, que no está en la paleta`);
    }
    const poligonos = aplanarPath(p.d);
    if (poligonos.length === 0) throw error(`la región "${p.id}" no tiene superficie`);
    return { poligonos, caja: cajaDe(poligonos) };
  });

  const regiones: Region[] = svg.paths.map((p, i) => {
    const calculada = calcularEtiqueta(formas, i);
    if (!calculada) throw error(`la región "${p.id}" queda totalmente tapada por otras`);
    return {
      id: p.id,
      numero: p.numero,
      d: p.d,
      poligonos: formas[i].poligonos,
      caja: formas[i].caja,
      etiqueta: p.etiqueta ?? calculada.punto,
      radioEtiqueta: calculada.radio,
    };
  });

  const usados = new Set(regiones.map((r) => r.numero));
  for (const n of numeros) {
    if (!usados.has(n)) throw error(`el color ${n} de la paleta no se usa en ninguna región`);
  }

  return { ...meta, ancho: svg.ancho, alto: svg.alto, regiones };
}
