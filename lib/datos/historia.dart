/// Historia principal, narrada por Gobi, el Lobito Guardián.
///
/// BORRADOR para revisar: está armada con el material de los cuentos
/// (docs/Cuentos.pdf y docs/Universo Gramonia.pdf). Se puede editar libremente
/// el texto sin tocar la lógica.
///
/// - [introduccion]: se muestra la primera vez que se abre el juego (y se puede
///   volver a ver desde la portada). La imagen inicial todavía no está
///   definida: mientras tanto se usa el mapa de Gramonia en gris.
/// - [capitulosDeNivel]: Gobi habla solo al completar cada nivel (el del nivel
///   8, la Isla Negra, es el final de la historia).
library;

class Escena {
  const Escena(this.texto, {this.imagen, this.titulo});

  /// Lo que dice Gobi (o el narrador).
  final String texto;

  /// Asset de la ilustración de la escena (null = imagen provisoria).
  final String? imagen;
  final String? titulo;
}

const imagenProvisoria = 'assets/mapa/gramonia.webp';

const introduccion = <Escena>[
  Escena(
    'En Gramonia todo nace del Árbol Mágico: sus raíces son el suelo de la isla '
    'y su copa es el mismísimo cielo. Y la memoria de Gramonia vive en sus '
    'habitantes y en cada rincón del mundo.',
    titulo: 'Gramonia a Color',
  ),
  Escena(
    'Pero una mañana todo amaneció en blanco y negro. Alguien se había '
    'llevado sus colores, uno por uno, rumbo al mar… Dicen que fue Mututu, el ser '
    'misterioso que vive más allá de las Islas Arcoíris, en la Isla Negra (buuuuu).',
  ),
  Escena(
    'Y Gramonia empezó a apagarse. El Bosque, la Ciudad, '
    'la Montaña Dragón… todo se fue poniendo gris.',
  ),
  Escena(
    '¡Hola! Me llamo Gobi. Soy el más chiquito de los Lobos guardianes, el que '
    'nació de un huevo carmesí con mariposas bordadas. No tenía bioma para cuidar… '
    '¡hasta hoy! Voy a devolverle los colores a Gramonia. ¿Me ayudás?',
    titulo: 'Gobi, el Lobito Guardián',
  ),
  Escena('Necesitamos devolver los colores a cada pedacito de Gramonia.'),
  Escena(
    'El Rocanón nos va a dar una mano desde allá arriba: cada día nos regala '
    'plumas, y más cuando terminás un cuadro. En la tienda las cambiás por lupas, '
    'para cuando te perdés, o por bombas de color, que pintan un montón de partes '
    'a la vez.',
  ),
  Escena(
    'Todos los caminos conducen al Árbol Mágico, así que empecemos por ahí. '
    'Primero te enseño a pintar con un dibujito del Árbol. ¡Vamos!',
  ),
];

/// Capítulo que cuenta Gobi al completar cada nivel (clave: el nivel
/// completado; 0 = el tutorial): qué se recuperó, cómo sigue y que hay que
/// estar atentos por si Mututu vuelve. `{nombre}` es el nombre de quien juega.
const capitulosDeNivel = <int, List<Escena>>{
  0: [
    Escena(
      '¡Ya sabés pintar, {nombre}! Con eso alcanza para devolverle los colores a '
      'Gramonia. Empezamos por el Árbol Mágico, que es donde empieza todo.',
      titulo: '¡Nivel 1!',
    ),
  ],
  1: [
    Escena(
      '¡Lo lograste, {nombre}! El Árbol Mágico brilla otra vez y el Rocanón está '
      'feliz en su nido. Ahora vamos al Bosque Mágico, que lo rodea.',
      titulo: '¡Nivel 2!',
    ),
    Escena(
      'Pero ojo: Mututu anda cerca. Si ves que algo se pone gris de golpe, avisame. '
      'Hay que estar {atento|atenta|con los ojos bien abiertos}.',
    ),
  ],
  2: [
    Escena(
      '¡El Bosque Mágico recuperó todos sus verdes! Las Hormiguitas bailan tres '
      'vueltas y un saltito: en hormigués, eso es "gracias".',
      titulo: '¡Nivel 3!',
    ),
    Escena(
      'Las Hormiguitas también bailaron otra cosa: vieron una sombra gris que se '
      'iba para el Reino Animal. ¿Será Mututu? Vamos con cuidado.',
    ),
  ],
  3: [
    Escena(
      '¡El Reino Animal tiene sus colores! León repartió todas las cartas y Cleo '
      'durmió como un tronco. Ahora nos esperan dos lugares: la Tierra de las '
      'Caperucitas y el Prado de las Hadas.',
      titulo: '¡Nivel 4!',
    ),
  ],
  4: [
    Escena(
      '¡Caperuzas de todos los colores y un Prado lleno de flores! Ahora subimos a '
      'la Montaña Dragón y al Reino Helado. Abrigate, {nombre}.',
      titulo: '¡Nivel 5!',
    ),
    Escena(
      'Las Hadas dicen que el viento del norte trae nubes grises. Puede ser Mututu '
      'buscando más colores. Quedate {atento|atenta|con los ojos bien abiertos}.',
    ),
  ],
  5: [
    Escena(
      '¡Las gemas de la Montaña brillan y el helado de menta volvió a ser verde! '
      'Ahora bajamos a la Ciudad y a la Costa.',
      titulo: '¡Nivel 6!',
    ),
    Escena(
      'Desde la cima, los dragones vieron una tormenta lejos, en el mar. Echaron un '
      'poquito de humo de la sorpresa. Mututu podría volver: vamos con cuidado.',
    ),
  ],
  6: [
    Escena(
      '¡La Ciudad y la Costa tienen sus colores! Desde el Muelle se ven siete islas '
      'en el horizonte: las Islas Arcoíris. ¡A navegar!',
      titulo: '¡Nivel 7!',
    ),
    Escena(
      'Y más lejos, un manchón negro. Llevemos una pluma del Rocanón por las dudas: '
      'dicen que calma a Mututu.',
    ),
  ],
  7: [
    Escena(
      '¡Las siete Islas Arcoíris brillan otra vez! Los duendecitos de todos los '
      'colores nos saludan desde la playa.',
      titulo: '¡Nivel 8!',
    ),
    Escena(
      'Ya no queda otra: el próximo lugar es la Isla Negra, donde vive Mututu. '
      'Vamos despacito, con la pluma del Rocanón y el corazón tranquilo.',
    ),
  ],
  // El final: lo que pasó en la Isla Negra y el cierre de Gobi.
  8: [
    ...finalIslas,
    Escena(
      '¡Gramonia tiene todos sus colores, {nombre}! Gracias por ayudarme a '
      'devolvérselos.',
      titulo: '¡Gramonia a todo color!',
    ),
    Escena(
      'Pero Mututu es dormilón y a veces se despierta con ganas de colores. Si '
      'algún día ves un cuadro gris, ya sabés qué hacer. FIN (por ahora).',
    ),
  ],
};

/// Id con el que se guarda que ya se contó el capítulo del nivel [n].
String idCapituloDeNivel(int n) => 'nivel-$n';

/// Final de la historia: se cuenta al completar la Isla Negra (nivel 8).
const finalIslas = <Escena>[
  Escena(
    'En la Isla Negra no había un monstruo, ni un extintor gigante, ni un pato. '
    'Había una Rocanón: Mututu, la primera de todas. Se había aburrido tanto de su '
    'isla toda negra que se llevó los colores de Gramonia para pintarla.',
    titulo: 'La Isla Negra',
  ),
  Escena(
    'Gobi no se enojó. Se acercó despacito y le dijo: "Tengo una colección enorme '
    'de abrazos. ¿Querés formar parte?". Y Mututu, que hacía miles de años que no '
    'recibía uno, dijo que sí.',
  ),
  Escena(
    'Desde ese día, Gramonia tiene todos sus colores… y la Isla Negra, un arcoíris '
    'propio que le pintaron entre todos.',
  ),
];
