/// Perfil de quien juega: cómo se llama y cómo quiere que le hablen (chico,
/// chica o "prefiero no decir"). Se pide una vez, después de la introducción
/// (o al entrar, si falta algo), y se puede volver a editar desde el menú.
library;

import 'package:material_ui/material_ui.dart';

import '../../datos/textos.dart';
import '../../engine/genero.dart';
import '../comun.dart';

class PantallaPerfil extends StatefulWidget {
  /// Con [editar], se llega desde el menú y se puede volver sin cambiar nada;
  /// si no, es la primera vez y hay que completarlo para seguir.
  const PantallaPerfil({super.key, this.editar = false});
  final bool editar;

  @override
  State<PantallaPerfil> createState() => _PantallaPerfilState();
}

class _PantallaPerfilState extends State<PantallaPerfil> {
  late final _nombre = TextEditingController(text: Dependencias.of(context).progreso.nombre);
  late Genero? _genero = Dependencias.of(context).progreso.genero;

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  bool get _listo => _nombre.text.trim().isNotEmpty && _genero != null;

  void _guardar() {
    final progreso = Dependencias.of(context).progreso;
    progreso.cambiarNombre(_nombre.text);
    progreso.elegirGenero(_genero!);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    Widget opcion(String texto, Genero g) {
      final elegida = _genero == g;
      final contenido = Text(texto, style: const TextStyle(fontSize: 16));
      void elegir() => setState(() => _genero = g);
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: SizedBox(
          width: 240,
          child: elegida
              ? FilledButton(key: Key('genero-${g.name}'), onPressed: elegir, child: contenido)
              : OutlinedButton(key: Key('genero-${g.name}'), onPressed: elegir, child: contenido),
        ),
      );
    }

    return PopScope(
      canPop: widget.editar,
      child: Scaffold(
        appBar: widget.editar ? AppBar(title: const Text(Textos.perfil)) : null,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    Textos.perfilNombre,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Tema.morado),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 260,
                    child: TextField(
                      key: const Key('nombre'),
                      controller: _nombre,
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 20,
                      style: const TextStyle(fontSize: 18),
                      decoration: InputDecoration(
                        hintText: Textos.perfilNombreAyuda,
                        filled: true,
                        fillColor: Tema.celesteSuave,
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: Tema.celeste, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: Tema.celeste, width: 2),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    Textos.generoPregunta,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Tema.morado),
                  ),
                  opcion(Textos.generoChico, Genero.chico),
                  opcion(Textos.generoChica, Genero.chica),
                  opcion(Textos.generoNeutro, Genero.neutro),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('perfil-listo'),
                    onPressed: _listo ? _guardar : null,
                    child: const Text(Textos.perfilListo, style: TextStyle(fontSize: 17)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
