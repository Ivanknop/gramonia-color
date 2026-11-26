/// Textos visibles del juego. Los que tienen género llevan `{chico|chica|neutro}` y se resuelven
/// con `Progreso.texto`.
library;

import 'biomas.dart';

abstract final class Textos {
  // Perfil: nombre y género (después de la introducción)
  static const perfil = 'Mi perfil';
  static const perfilNombre = '¿Cómo te llamás?';
  static const perfilNombreAyuda = 'Tu nombre o un apodo';
  static const perfilListo = 'Listo';
  static const generoPregunta = '¿Cómo querés que te hable?';
  static const generoChico = 'Chico';
  static const generoChica = 'Chica';
  static const generoNeutro = 'Prefiero no decir';

  // Niveles (modo historia)
  static String nivel(int n) => n == 0 ? tutorial : ['Nivel $n', ?nombresDeNivel[n]].join(' · ');
  static String tituloNivel(int n) => n == 0 ? 'Nivel 0 · $tutorial' : nivel(n);
  static String paraElNivel(int hechas, int necesarias, int siguiente) =>
      '$hechas de $necesarias obras para llegar al nivel $siguiente';
  static String nivelCompleto(int n) => '¡Nivel $n completo! Pronto llegan más obras.';
  static const bloqueadoPorNivel = 'Se desbloquea al terminar el nivel anterior';

  // Tutorial (nivel 0)
  static const tutorial = 'Tutorial';
  static const tutorialSaltar = saltar;
  static const tutorialElegirColor = 'Elegí un color de la paleta de abajo.';
  static const tutorialCompletarColor =
      'Tocá las partes del dibujo que tienen ese número hasta pintarlas todas. '
      'Así completás un color.';
  static const tutorialLupa =
      '¡Muy bien! ¿Y si no encontrás una parte? Tocá la lupa (se enciende) y '
      'después un color: te muestra una parte que falta. Acá es gratis.';
  static const tutorialBomba =
      'Ahora la bomba de color: tocala y después tocá el dibujo. Pinta un montón '
      'de partes de una vez. Acá también es gratis.';
  static const tutorialTerminar = '¡Muy bien! Terminá de pintar el Árbol.';
  static const tutorialListo = '¡Ya sabés pintar! Ahora empieza la historia.';
  static const tutorialRepaso = '¡Muy bien! Ya te acordás de todo.';
  static const tutorialSeguir = '¡A la historia!';
  static const tutorialVolverAHacer = 'Volver a hacer';
  static const tutorialHacer = 'Hacer el tutorial';
  static const tutorialDetalle = 'Aprendé a pintar con un Árbol Mágico sencillito.';
  static String tutorialPremio(int n) => 'La primera vez que lo terminás, ganás $n plumas.';

  // Créditos
  static const creditos = 'Créditos';
  static const creditosTitulo = 'Gramonia a Color';
  static const creditosIntro =
      'Estas son las personas (y las ayudas mágicas) que hicieron Gramonia a Color.';

  static const realizadores = <(String, String)>[
    ('Guion y desarrollo', 'Iván y Regina Knopoff'),
    ('Imágenes y Música', 'Gemini'),
    ('Colaboración Código', 'Claude'),
  ];
  static const creditosCuentosAntes = 'Los cuentos se leen en';
  static const creditosCuentosEnlace = 'cuentosdegramonia.substack.com';
  static const creditosSinNavegador = 'No pudimos abrir el navegador.';
  static const creditosGobi = '¡Gracias por devolverle los colores a Gramonia!';

  // Al terminar una obra de la historia (uno al azar)
  // {lugar}: el lugar con artículo ("el Árbol Mágico"); {Lugar}: igual, con
  // mayúscula; {n}: obras que le faltan. "a el" queda "al".
  static const mensajesObra = (
    faltan: [
      '¡Falta menos! Ya casi le devolvemos el color a {lugar}.',
      'Un cuadro menos. Quedan {n} para que {lugar} vuelva a brillar.',
      '¡Muy bien! Cada cuadro le devuelve un poquito de color a {lugar}.',
      'Mututu se va a quedar con las ganas: a {lugar} le faltan solo {n} cuadros.',
      'Gobi mueve la cola: ¡quedan {n} cuadros de {lugar}!',
    ],
    faltaUna: [
      '¡Falta uno solo! Ya casi le devolvemos todo el color a {lugar}.',
      '¡Queda el último cuadro de {lugar}! Gobi ya prepara el festejo.',
    ],
    completo: [
      '¡Listo! Le devolviste todos los colores a {lugar}.',
      '¡{Lugar} brilla otra vez, con todos sus colores!',
      '¡Lo lograste! Cada rincón de {lugar} tiene su color.',
    ],
  );
  static String destapaste(String lugarConArticulo) =>
      'Destapaste una parte de $lugarConArticulo.'.replaceAll('de el ', 'del ');

  // Festejo
  static const festejo = '¡Terminaste!';

  // Timelapse
  static const timelapse = 'Así lo pintaste';
  static const saltear = 'Saltear';
  static const repetir = 'Repetir';
  static const verComoLoPinte = 'Ver cómo lo pinté';

  // Dificultades
  static String plumasDificultad(int n) => '+$n';
  static String detalleDificultad(int colores, int regiones) =>
      '$colores colores · unas $regiones partes para pintar';

  // Modo libre
  static const modoLibre = 'Modo libre';
  static const libreIntro =
      'Acá no hay historia ni mapa: elegí un dibujo y pintalo como quieras, '
      'tan fácil o tan difícil como te guste. Los que colorees en la historia '
      'también aparecen acá.';
  static const libreElegir = '¿Qué tan difícil lo querés?';
  static const libreTerminado = '¡Obra terminada! Quedó hermosa.';
  static const libreOtro = 'Elegir otro dibujo';
  static const libreVacio =
      'Todavía no hay dibujos para el modo libre. Coloreá dibujos en la historia y aparecen acá.';
  static String etiquetaLibre(String dificultad) => 'Modo libre · $dificultad';

  // Rehacer obra
  static const rehacer = 'Rehacer';
  static const rehacerElegir = '¿En qué dificultad la volvés a pintar?';
  static const rehacerAviso =
      'Se borra lo pintado y empezás de nuevo. Lo que destapaste en Gramonia queda destapado.';
  static String etiquetaRehecha(String dificultad) => 'Rehecha · $dificultad';

  // Tienda y herramientas
  static const tienda = 'Tienda';
  static const tiendaLobo = 'El Lobo de la tienda';
  static const tiendaFrase = 'No explico mucho. Vendo.';
  static const tiendaPlumas = 'Tus plumas';
  static const lupa = 'Lupa';
  static const bomba = 'Bomba de color';
  static const lupaDetalle = 'Te lleva a una parte que falta pintar.';
  static const bombaDetalle = 'Pinta un montón de partes de una vez.';
  static String tenes(int n) => 'Tenés $n';
  static String compraste(String que, int n) => '¡Listo! Compraste una $que. Ahora tenés $n.';
  static String confirmarCompra(String que, int precio) => '¿Comprás una $que por $precio plumas?';
  static const compraSi = '¡Sí, comprar!';
  static const compraNo = 'Mejor no';
  static const tiendaFraseTutorial = 'Tomá. Regalo. Comprá una lupa.';
  static String tutorialTienda(int plumas) =>
      'El Lobo te regaló $plumas plumas. Comprá una lupa: te muestra dónde '
      'faltan partes de un color.';
  static const irALaTienda = '¡A la tienda!';
  static const tutorialTiendaPrimero = 'Primero comprá la lupa (o tocá Saltar).';
  static const faltanPlumas = 'Te faltan plumas. Terminá cuadros para juntar más.';
  static const sinLupas = 'No te quedan lupas. Conseguí más en la Tienda.';
  static const sinBombas = 'No te quedan bombas. Conseguí más en la Tienda.';
  static const lupaArmada = 'Tocá un color y la lupa te muestra una parte que falta.';
  static const lupaColorCompleto = 'Ese color ya está completo. Tocá otro.';
  static const bombaArmada = 'Tocá el dibujo donde quieras tirar la bomba de color.';
  static String subisteDeNivel(int n) => '¡Llegaste al nivel $n!';

  // Portada
  static const tituloGramonia = 'Gramonia...';
  static const tituloColor = 'a Color';

  /// Versión de la app (la misma que `version` en pubspec.yaml; lo verifica un test).
  static const version = 'v1.0.0';
  static const modoHistoria = 'Modo historia';
  static const empezar = '¡Empezar!';
  static const portada = 'Portada';
  static const galeria = 'Galería';
  static const misObras = 'Mis obras';
  static const mapa = 'Mapa de Gramonia';
  static const mapaCorto = 'Mapa';
  static const laHistoria = 'La historia';

  // Comunes
  static const saltar = 'Saltar';
  static const siguiente = 'Siguiente';
  static const seguir = 'Seguir';
  static const listo = 'Listo';
  static const vamos = '¡Vamos!';
  static const encuadrar = 'Encuadrar';
  static const proximamente = 'Próximamente';
  static String colorDePaleta(int numero, String nombre, {required bool completo}) =>
      'Color $numero, $nombre${completo ? ', completo' : ''}';

  // Historia
  static const introduccion = 'Introducción';
  static const capituloCerrado = 'Se cuenta al completar el nivel';

  // Mapa
  static const lugarBloqueado = 'Bloqueado: primero recuperá el lugar anterior';
  static String partesRecuperadas(int hechas, int total, {required int proximamente}) =>
      '$hechas de $total partes recuperadas'
      '${proximamente > 0 ? ' ($proximamente próximamente)' : ''}';

  // Mis obras
  static String enProgreso(int n) => 'En progreso ($n)';
  static String terminadas(int n) => 'Terminadas ($n)';
  static String terminadaEl(String fecha) => 'Terminada el $fecha';
  static String ultimaPincelada(String fecha) => 'Última pincelada: $fecha';
  static const obraConColor = '¡Con color!';
  static const sinObras = 'Todavía no hay obras';
  static const sinObrasDetalle = 'Elegí un cuadro en la Galería y empezá a devolverle sus colores.';
  static const irALaGaleria = 'Ir a la Galería';

  // Pintar
  static String conColor(int porcentaje) => '$porcentaje% con color';
  static String plumasGanadas(int n) => ' +$n plumas del Rocanón';
  static const verElMapa = 'Ver el mapa';
  static const cuadroNoEncontrado = 'No encontramos ese cuadro.';
  static const cambiarMusica = 'Cambiar música';
  static const silenciar = 'Silenciar';
  static const activarSonido = 'Activar sonido';
  static String sonando(String tema) => 'Sonando: $tema';
  static String plumasDelDia(int n) => 'Gobi te trae $n plumas del Rocanón. ¡Buen día!';
}
