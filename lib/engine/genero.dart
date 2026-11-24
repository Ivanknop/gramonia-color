/// Variantes de género de los textos, como pide el canon: quien juega elige
/// chico, chica o "prefiero no decir", y cada texto con género lleva tres
/// variantes `{chico|chica|neutro}` (por ejemplo `{Bienvenido|Bienvenida|Qué
/// alegría tenerte}`). La neutra reformula: no usa "o/a", "x" ni "e".
library;

enum Genero { chico, chica, neutro }

final _variantes = RegExp(r'\{([^{}|]*)\|([^{}|]*)\|([^{}|]*)\}');

/// Elige en [texto] la variante de cada `{chico|chica|neutro}` según [genero].
/// Las llaves que no tienen exactamente tres variantes se dejan como están.
String conGenero(String texto, Genero genero) =>
    texto.replaceAllMapped(_variantes, (m) => m.group(genero.index + 1)!);
