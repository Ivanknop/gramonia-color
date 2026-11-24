/// Historia principal, narrada por Gobi, el Lobito Guardián.
///
/// BORRADOR para revisar: está armada con el material de los cuentos
/// (docs/Cuentos.pdf y docs/Universo Gramonia.pdf). Se puede editar libremente
/// el texto sin tocar la lógica.
///
/// - [introduccion]: se muestra la primera vez que se abre el juego (y se puede
///   volver a ver desde la portada). La imagen inicial todavía no está
///   definida: mientras tanto se usa el mapa de Gramonia en gris.
/// - [capitulos]: uno por bioma, se muestra al completar todas sus obras.
/// - [finalIslas]: cuando se completen las siete Islas Arcoíris.
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
    'y su copa es el mismísimo cielo. Y la memoria de Gramonia vive en sus cuadros: '
    'pinturas de cada rincón, de cada ser y de cada historia.',
    titulo: 'Colores de Gramonia',
  ),
  Escena(
    'Pero una mañana los cuadros amanecieron en blanco y negro. Alguien se había '
    'llevado sus colores, uno por uno, rumbo al mar… Dicen que fue Mututu, el ser '
    'misterioso que vive más allá de las Islas Arcoíris, en la Isla Negra (buuuuu).',
  ),
  Escena(
    'Y sin sus cuadros, Gramonia empezó a apagarse. El Bosque, la Ciudad, '
    'la Montaña Dragón… todo se fue poniendo gris.',
  ),
  Escena(
    '¡Hola! Me llamo Gobi. Soy el más chiquito de los Lobos guardianes, el que '
    'nació de un huevo carmesí con mariposas bordadas. No tenía bioma para cuidar… '
    '¡hasta hoy! Voy a devolverle los colores a Gramonia. ¿Me ayudás?',
    titulo: 'Gobi, el Lobito Guardián',
  ),
  Escena(
    'Cada cuadro tiene números. Elegí un color de abajo y tocá las partes con ese '
    'número: el color vuelve, con todas sus luces y sombras. Cuando terminás un '
    'cuadro, un pedacito de Gramonia vuelve a brillar en el mapa.',
  ),
  Escena(
    'El Rocanón nos va a dar una mano desde allá arriba: cada día nos regala '
    'plumas. Con ellas podés usar la lupa cuando te perdés, o tirar una bomba de '
    'color que pinta un montón de partes a la vez.',
  ),
  Escena(
    'Todos los caminos conducen al Árbol Mágico, así que empecemos por ahí. '
    '¡Vamos!',
  ),
];

/// Capítulo que se cuenta al completar cada bioma (por id de bioma).
const capitulos = <String, Escena>{
  'arbol-magico': Escena(
    '¡El Árbol Mágico vuelve a tener sus hojas celestes y blancas! Desde la copa, '
    'el Rocanón nos saluda con una pluma brillante. Ahora sigamos por el Bosque que '
    'lo rodea… ojo, que ahí un árbol se parece demasiado a otro árbol.',
    titulo: 'El Árbol Mágico',
  ),
  'bosque-magico': Escena(
    'Las Hormiguitas ya ven sus senderos de colores. Juana, o quizás Raúl, te manda '
    'saludos (y un granito de azúcar). Todos los caminos conducen al Árbol… y '
    'también a la Ciudad. ¡Vamos!',
    titulo: 'El Bosque Mágico',
  ),
  'ciudad': Escena(
    'La Ciudad brilla de nuevo: sus trenes, sus plazas y la carpeta de dibujos de '
    'Tomás. Sofía dice que vio una sombra con plumas cruzando hacia el Reino Animal…',
    titulo: 'La Ciudad',
  ),
  'reino-animal': Escena(
    'En el Reino Animal, León vuelve a ver su queso bien amarillo (y Kiribiki '
    'también, claro). Ahora hay que subir a la Montaña Dragón, la más alta '
    'después del Árbol.',
    titulo: 'El Reino Animal',
  ),
  'montana-dragon': Escena(
    '¡Las gemas de la Montaña Dragón brillan otra vez! Alma, la dragona de escamas '
    'violetas, vuela feliz a nuestro lado. Desde acá arriba ya se ve el Prado de '
    'las Hadas.',
    titulo: 'La Montaña Dragón',
  ),
  'prado-de-las-hadas': Escena(
    'Las flores del Prado recuperaron sus colores y Anastasia ya puede ordenar sus '
    'tréboles por color, olor y nivel de cosquillas. Las Caperucitas nos esperan.',
    titulo: 'El Prado de las Hadas',
  ),
  'tierra-de-las-caperucitas': Escena(
    '¡Caperuzas rojas, azules, a lunares y una que cambia de color cuando alguien '
    'dice "panqueque"! Caperucita Naranja Clarito Casi Mandarina te regaló un '
    'retacito. Ahora, a abrigarse: vamos al Reino Helado.',
    titulo: 'La Tierra de las Caperucitas',
  ),
  'reino-helado': Escena(
    'El Reino Helado vuelve a tener su helado de menta granizada… ¡bien verde! '
    'Alma ya se pidió dos. Solo nos queda la Costa.',
    titulo: 'El Reino Helado',
  ),
  'costa': Escena(
    'La Costa brilla y Loana, la SirenHada, señala el horizonte: los colores que '
    'faltan se fueron por el mar, hacia las Islas Arcoíris. Una Caperucita pirata '
    'de parche morado nos presta su barco. ¡A navegar!',
    titulo: 'La Costa',
  ),
  'isla-roja': Escena(
    'La Isla Roja recuperó su rojo y los duendecitos rojos bailan en la playa. '
    'Faltan seis islas.',
    titulo: 'La Isla Roja',
  ),
  'isla-naranja': Escena(
    'La Isla Naranja vuelve a ser naranja, como un atardecer de verano. Los '
    'duendecitos naranjas nos convidan jugo. Faltan cinco.',
    titulo: 'La Isla Naranja',
  ),
  'isla-amarilla': Escena(
    'La Isla Amarilla brilla como el Rocanón al mediodía. Los duendecitos amarillos '
    'nos cantan una canción. Faltan cuatro.',
    titulo: 'La Isla Amarilla',
  ),
  'isla-verde': Escena(
    'La Isla Verde volvió a ser verde, verde sapo educado. Los duendecitos verdes '
    'nos regalan un trébol. Faltan tres.',
    titulo: 'La Isla Verde',
  ),
  'isla-azul': Escena(
    'La Isla Azul es otra vez azul charquito. Los duendecitos azules nos salpican '
    'para saludar. Faltan dos.',
    titulo: 'La Isla Azul',
  ),
  'isla-anil': Escena(
    'La Isla Añil recuperó su color de noche clara. Los duendecitos añiles nos '
    'avisan que el mar está cada vez más agitado. Falta una.',
    titulo: 'La Isla Añil',
  ),
  'isla-morada': Escena(
    'La Isla Morada es morada arándano otra vez. Los duendecitos morados señalan '
    'un manchón negro en el horizonte: la Isla Negra. Ahí está Mututu.',
    titulo: 'La Isla Morada',
  ),
};

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
    'propio que le pintaron entre todos. Gracias por ayudarme. FIN (por ahora).',
  ),
];
