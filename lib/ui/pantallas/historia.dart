/// Pantallas de la historia narrada por Gobi: escenas (introducción o
/// capítulos) y el índice para volver a leerlas.
library;

import 'package:material_ui/material_ui.dart';

import '../../datos/biomas.dart';
import '../../datos/historia.dart';
import '../../engine/intro.dart';
import '../../engine/niveles.dart';
import '../../datos/textos.dart';
import '../comun.dart';

/// Cómo cambian los colores del dibujo a lo largo de las escenas.
enum ColoresDeEscenas {
  /// De todos los colores a blanco y negro (la introducción: Mututu se los lleva).
  seApagan,

  /// De blanco y negro a todos los colores (los capítulos: se recuperan).
  seEncienden,
}

/// Muestra una serie de escenas, una por página. Al terminar (o saltear)
/// llama a [alTerminar] (por defecto, vuelve atrás).
class PantallaHistoria extends StatefulWidget {
  const PantallaHistoria({
    super.key,
    required this.escenas,
    this.textoFinal = '¡Vamos!',
    this.alTerminar,
    this.colores = ColoresDeEscenas.seEncienden,
  });

  final List<Escena> escenas;
  final String textoFinal;
  final VoidCallback? alTerminar;
  final ColoresDeEscenas colores;

  /// Saturación del dibujo en la página [pagina] (puede ser fraccionaria,
  /// mientras se desliza) de [total].
  static double saturacion(ColoresDeEscenas colores, double pagina, int total) {
    final avance = total <= 1 ? 1.0 : (pagina / (total - 1)).clamp(0.0, 1.0);
    return colores == ColoresDeEscenas.seApagan ? 1 - avance : avance;
  }

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
              child: TextButton(onPressed: _terminar, child: const Text('Saltar')),
            ),
            Expanded(
              child: PageView(
                controller: _paginas,
                onPageChanged: (i) => setState(() => _actual = i),
                children: [
                  for (final e in widget.escenas)
                    AnimatedBuilder(
                      animation: _paginas,
                      builder: (context, _) => _VistaEscena(
                        escena: e,
                        saturacion: PantallaHistoria.saturacion(
                          widget.colores,
                          _paginas.hasClients && _paginas.position.haveDimensions
                              ? _paginas.page ?? 0
                              : _actual.toDouble(),
                          widget.escenas.length,
                        ),
                      ),
                    ),
                ],
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
  const _VistaEscena({required this.escena, required this.saturacion});
  final Escena escena;

  /// 1 = todos los colores; 0 = blanco y negro.
  final double saturacion;

  @override
  Widget build(BuildContext context) {
    final progreso = Dependencias.of(context).progreso;
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
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix(matrizSaturacion(saturacion)),
                child: imagen,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      if (escena.titulo case final titulo?) ...[
                        Text(
                          progreso.texto(titulo),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Tema.morado,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        progreso.texto(escena.texto),
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
    void abrir(List<Escena> escenas) => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaHistoria(escenas: escenas, textoFinal: 'Listo'),
      ),
    );
    Widget nivel(int n) {
      final escenas = capitulosDeNivel[n];
      if (escenas == null) return const SizedBox.shrink();
      return _Capitulo(
        titulo: progreso.texto(escenas.first.titulo ?? Textos.nivel(n + 1)),
        abierto: progreso.capitulosVistos.contains(idCapituloDeNivel(n)),
        alTocar: () => abrir(escenas),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('La historia')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Capitulo(
            titulo: 'Introducción',
            abierto: true,
            alTocar: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PantallaHistoria(
                  escenas: introduccion,
                  textoFinal: 'Listo',
                  colores: ColoresDeEscenas.seApagan,
                ),
              ),
            ),
          ),
          // Un capítulo por nivel: Gobi habla al completar cada uno.
          for (final n in {nivelTutorial, for (final b in biomas) b.nivel}) nivel(n),
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
      subtitle: abierto ? null : const Text('Se cuenta al completar el nivel'),
      enabled: abierto,
      onTap: abierto ? alTocar : null,
    ),
  );
}
