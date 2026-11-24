/// Niveles del modo historia: marcan el avance de la historia.
///
/// Cada nivel pide una cantidad de obras para pasar al siguiente, y las obras
/// de ese nivel tienen una cantidad fija de colores. Las dos cifras siguen la
/// misma regla: valor(n) = valor(n-1) + ⌊valor(n-1) / 2⌋, con el nivel 1 en
/// 2 obras y 10 colores (2/10, 3/15, 4/22, 6/33, 9/49…).
///
/// El nivel de cada obra sale de su lugar en el recorrido (las obras 1 y 2
/// son del nivel 1, de la 3 a la 5 del nivel 2, etc.); el conversor
/// (scripts/convertir_arte.py) genera cada obra con los colores de su nivel.
library;

/// Valor de la regla en el nivel [n] (desde 1), arrancando en [inicial].
int valorDelNivel(int n, int inicial) {
  if (n < 1) throw ArgumentError.value(n, 'n', 'los niveles empiezan en 1');
  var valor = inicial;
  for (var i = 1; i < n; i++) {
    valor += valor ~/ 2;
  }
  return valor;
}

const obrasDelNivel1 = 2;
const coloresDelNivel1 = 10;

/// Obras a completar en el nivel [n] para pasar al siguiente.
int obrasDelNivel(int n) => valorDelNivel(n, obrasDelNivel1);

/// Colores de cada obra del nivel [n].
int coloresDelNivel(int n) => valorDelNivel(n, coloresDelNivel1);

/// Nivel (desde 1) de la obra que está en la posición [indice] (desde 0)
/// del recorrido de la historia.
int nivelDeObra(int indice) {
  if (indice < 0) throw ArgumentError.value(indice, 'indice');
  var nivel = 1;
  var hasta = obrasDelNivel(1);
  while (indice >= hasta) {
    nivel++;
    hasta += obrasDelNivel(nivel);
  }
  return nivel;
}

/// Cuántos niveles se suben al pasar de [antes] a [despues] obras de la
/// historia completadas.
int nivelesSubidos(int antes, int despues) => nivelActual(despues).nivel - nivelActual(antes).nivel;

/// En qué nivel va quien juega: [hechas] de las [necesarias] obras del nivel.
typedef EstadoNivel = ({int nivel, int hechas, int necesarias});

/// Nivel actual según cuántas obras de la historia se completaron.
EstadoNivel nivelActual(int obrasCompletadas) {
  var nivel = 1;
  var restantes = obrasCompletadas;
  while (restantes >= obrasDelNivel(nivel)) {
    restantes -= obrasDelNivel(nivel);
    nivel++;
  }
  return (nivel: nivel, hechas: restantes, necesarias: obrasDelNivel(nivel));
}
