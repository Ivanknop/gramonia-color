/// Pantallas de la historia narrada por Gobi: escenas (introducción o
/// capítulos) y el índice para volver a leerlas.
library;

import 'package:material_ui/material_ui.dart';

import '../../datos/biomas.dart';
import '../../datos/historia.dart';
import '../../engine/motor.dart';
import '../comun.dart';

/// Muestra una serie de escenas, una por página. Al terminar (o saltear)
/// llama a [alTerminar] (por defecto, vuelve atrás).
class PantallaHistoria extends StatefulWidget {
  const PantallaHistoria({
    super.key,
    required this.escenas,
    this.textoFinal = '¡Vamos!',
    this.alTerminar,
  });

  final List<Escena> escenas;
  final String textoFinal;
  final VoidCallback? alTerminar;

  @override
  State<PantallaHistoria> createState() => _PantallaHistoriaState();
}

class _PantallaHistoriaState extends State<PantallaHistoria> {
  final _paginas = PageController();
  int _actual = 0;

  @override
  void dispose() {
    _paginas.dispose();
    super.dispose();
  }

  void _terminar() {
    final alTerminar = widget.alTerminar;
    if (alTerminar != null) {
      alTerminar();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ultima = _actual == widget.escenas.length - 1;
    return Scaffold(
      backgroundColor: const Color(0xFF1E1830),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _terminar,
                child: const Text('Saltar', style: TextStyle(color: Colors.white70)),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _paginas,
                onPageChanged: (i) => setState(() => _actual = i),
                children: [for (final e in widget.escenas) _VistaEscena(escena: e)],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  for (var i = 0; i < widget.escenas.length; i++)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _actual ? Colors.white : Colors.white24,
                      ),
                    ),
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE8A33D)),
                    onPressed: ultima
                        ? _terminar
                        : () => _paginas.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          ),
                    child: Text(ultima ? widget.textoFinal : 'Siguiente'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VistaEscena extends StatelessWidget {
  const _VistaEscena({required this.escena});
  final Escena escena;

  @override
  Widget build(BuildContext context) {
    final provisoria = escena.imagen == null;
    final imagen = Image.asset(
      escena.imagen ?? imagenProvisoria,
      fit: BoxFit.cover,
      width: double.infinity,
      cacheWidth: 800,
    );
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              // Imagen inicial todavía no definida: el mapa de Gramonia en gris.
              child: provisoria
                  ? ColorFiltered(
                      colorFilter: const ColorFilter.matrix(<double>[
                        0.2126, 0.7152, 0.0722, 0, 0, //
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0, 0, 0, 1, 0,
                      ]),
                      child: imagen,
                    )
                  : imagen,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AvatarGobi(),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Tema.crema,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (escena.titulo != null) ...[
                        Text(
                          escena.titulo!,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Tema.morado,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        escena.texto,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.35,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Índice de la historia: la introducción y los capítulos ya desbloqueados.
class IndiceHistoria extends StatelessWidget {
  const IndiceHistoria({super.key});

  @override
  Widget build(BuildContext context) {
    final progreso = Dependencias.of(context).progreso;
    final estados = estadoBiomas(biomas, progreso.completados);
    void abrir(List<Escena> escenas) => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaHistoria(escenas: escenas, textoFinal: 'Listo'),
      ),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('La historia')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Capitulo(titulo: 'Introducción', abierto: true, alTocar: () => abrir(introduccion)),
          for (final e in estados)
            if (capitulos[e.bioma.id] case final escena?)
              _Capitulo(
                titulo: escena.titulo ?? e.bioma.nombre,
                abierto: e.completoDisponible && e.bioma.cuadroIds.isNotEmpty,
                alTocar: () => abrir([escena]),
              ),
        ],
      ),
    );
  }
}

class _Capitulo extends StatelessWidget {
  const _Capitulo({required this.titulo, required this.abierto, required this.alTocar});
  final String titulo;
  final bool abierto;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    child: ListTile(
      leading: Icon(abierto ? Icons.menu_book : Icons.lock_outline, color: Tema.morado),
      title: Text(abierto ? titulo : '???'),
      subtitle: abierto ? null : const Text('Se cuenta al completar este lugar'),
      enabled: abierto,
      onTap: abierto ? alTocar : null,
    ),
  );
}
