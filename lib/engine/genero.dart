/// Cada texto con género lleva `{chico|chica|neutro}`, por ejemplo `{Bienvenido|Bienvenida|Qué
/// alegría tenerte}`. La neutra reformula: no usa "o/a", "x" ni "e".
library;

enum Genero { chico, chica, neutro }

final _variantes = RegExp(r'\{([^{}|]*)\|([^{}|]*)\|([^{}|]*)\}');

/// Las llaves que no tienen exactamente tres variantes se dejan como están.
String conGenero(String texto, Genero genero) =>
    texto.replaceAllMapped(_variantes, (m) => m.group(genero.index + 1)!);
