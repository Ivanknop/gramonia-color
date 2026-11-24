/// Hoja para elegir la dificultad (modo libre y "rehacer obra").
library;

import 'package:material_ui/material_ui.dart';

import '../datos/textos.dart';
import '../engine/dificultad.dart';
import 'comun.dart';

/// Muestra las dificultades y devuelve la elegida (null si se cierra).
Future<Dificultad?> elegirDificultad(
  BuildContext context, {
  required String titulo,
  String? aviso,
  String? actual,
}) {
  final dificultades = Dependencias.of(context).catalogo.dificultades;
  return showModalBottomSheet<Dificultad>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Tema.morado,
                ),
              ),
            ),
            if (aviso != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(
                  aviso,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Tema.gris),
                ),
              ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final d in dificultades)
                    ListTile(
                      key: Key('dificultad-${d.id}'),
                      selected: d.id == actual,
                      selectedColor: Tema.morado,
                      leading: CircleAvatar(
                        backgroundColor: Tema.morado,
                        foregroundColor: Colors.white,
                        child: Text('${d.colores}'),
                      ),
                      title: Text(d.nombre, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(Textos.detalleDificultad(d.colores, d.regiones)),
                      trailing: d.id == actual ? const Icon(Icons.check) : null,
                      onTap: () => Navigator.of(context).pop(d),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
