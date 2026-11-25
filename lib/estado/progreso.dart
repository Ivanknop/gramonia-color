/// Progreso del jugador, guardado en el teléfono entre sesiones.
///
/// Solo se guarda lo mínimo (regiones pintadas y fechas). Lo derivado
/// —porcentajes, piezas, biomas— se calcula con el motor.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/dificultad.dart';
import '../engine/genero.dart';
import '../engine/plumas.dart';
import '../engine/tutorial.dart';

class ProgresoCuadro {
  const ProgresoCuadro({
    this.pintadas = const [],
    this.actualizadoEn,
    this.completadoEn,
    this.dificultad,
  });

  factory ProgresoCuadro.desdeJson(Map<String, dynamic> j) => ProgresoCuadro(
    pintadas: [for (final id in j['pintadas'] as List) id as String],
    actualizadoEn: j['actualizadoEn'] as int?,
    completadoEn: j['completadoEn'] as int?,
    dificultad: j['dificultad'] as String?,
  );

  /// Ids de regiones pintadas, en el orden en que se pintaron.
  final List<String> pintadas;

  /// Momento (ms) de la última región pintada (para ordenar "Mis obras").
  final int? actualizadoEn;

  /// Momento (ms) en que se completó; null si no se terminó.
  final int? completadoEn;

  /// Obra de la historia que se rehizo en otra dificultad: se pinta la
  /// variante `<cuadro>--<dificultad>` (null = el cuadro de la historia).
  final String? dificultad;

  bool get terminado => completadoEn != null;

  ProgresoCuadro copiar({List<String>? pintadas, int? actualizadoEn, int? completadoEn}) =>
      ProgresoCuadro(
        pintadas: pintadas ?? this.pintadas,
        actualizadoEn: actualizadoEn ?? this.actualizadoEn,
        completadoEn: completadoEn ?? this.completadoEn,
        dificultad: dificultad,
      );

  Map<String, dynamic> aJson() => {
    'pintadas': pintadas,
    'actualizadoEn': ?actualizadoEn,
    'completadoEn': ?completadoEn,
    'dificultad': ?dificultad,
  };
}

/// Dónde se guarda el progreso (en tests se reemplaza por uno en memoria).
abstract class AlmacenProgreso {
  Future<String?> leer();
  Future<void> escribir(String datos);
}

class AlmacenPreferencias implements AlmacenProgreso {
  static const clave = 'colores-de-gramonia/progreso';

  @override
  Future<String?> leer() async => (await SharedPreferences.getInstance()).getString(clave);

  @override
  Future<void> escribir(String datos) async =>
      (await SharedPreferences.getInstance()).setString(clave, datos);
}

class AlmacenEnMemoria implements AlmacenProgreso {
  AlmacenEnMemoria([this.datos]);
  String? datos;

  @override
  Future<String?> leer() async => datos;

  @override
  Future<void> escribir(String d) async => datos = d;
}

class Progreso extends ChangeNotifier {
  Progreso._(this._almacen, this._reloj);

  /// Versión del formato guardado. v1 → v2: se agregan plumas e historia.
  /// v2 → v3: se agrega el género elegido (en un guardado viejo queda sin elegir).
  /// v3 → v4: obras desbloqueadas aparte (rehacer una obra no la vuelve a tapar)
  /// y dificultad de las obras rehechas. Las terminadas pasan a desbloqueadas.
  /// v4 → v5: lupas y bombas compradas (en un guardado viejo, ninguna).
  /// v5 → v6: tutorial pasado y premiado. En un guardado viejo con obras
  /// empezadas cuenta como pasado (salteado), con el premio pendiente.
  /// v6 → v7: nombre de quien juega (en un guardado viejo, sin nombre: se pide
  /// al entrar).
  static const version = 7;

  static Future<Progreso> cargar(AlmacenProgreso almacen, {int Function()? reloj}) async {
    final p = Progreso._(almacen, reloj ?? () => DateTime.now().millisecondsSinceEpoch);
    final texto = await almacen.leer();
    if (texto != null) {
      try {
        final j = jsonDecode(texto) as Map<String, dynamic>;
        for (final e in (j['cuadros'] as Map<String, dynamic>).entries) {
          p._cuadros[e.key] = ProgresoCuadro.desdeJson(e.value as Map<String, dynamic>);
        }
        // Campos de v2 (en un guardado v1 no existen y quedan en su valor inicial).
        p._plumas = (j['plumas'] as int?) ?? 0;
        p._ultimoDiaPlumas = j['ultimoDiaPlumas'] as String?;
        p._introVista = (j['introVista'] as bool?) ?? false;
        p._musicaSilenciada = (j['musicaSilenciada'] as bool?) ?? false;
        // Campo de v3.
        p._genero = Genero.values.asNameMap()[j['genero']];
        // Campos de v5.
        for (final h in Herramienta.values) {
          p._herramientas[h] = (j[h.name] as int?) ?? 0;
        }
        // Campo de v4 (en un guardado viejo, las terminadas).
        p._desbloqueadas.addAll([
          for (final c in (j['desbloqueadas'] as List?) ?? const []) c as String,
          for (final e in p._cuadros.entries)
            if (e.value.terminado && dificultadDe(e.key) == null) e.key,
        ]);
        // Campo de v7.
        p._nombre = j['nombre'] as String?;
        // Campos de v6.
        p._tutorialPasado = (j['tutorialPasado'] as bool?) ?? p._cuadros.isNotEmpty;
        p._tutorialPremiado = (j['tutorialPremiado'] as bool?) ?? false;
        p._capitulosVistos.addAll([
          for (final c in (j['capitulosVistos'] as List?) ?? []) c as String,
        ]);
      } on Object catch (e) {
        // Datos corruptos: se empieza de cero antes que no poder jugar.
        debugPrint('No se pudo leer el progreso guardado: $e');
      }
    }
    return p;
  }

  final AlmacenProgreso _almacen;
  final int Function() _reloj;
  final Map<String, ProgresoCuadro> _cuadros = {};
  int _plumas = 0;
  String? _ultimoDiaPlumas;
  bool _introVista = false;
  final Set<String> _capitulosVistos = {};
  bool _musicaSilenciada = false;
  Genero? _genero;
  final Set<String> _desbloqueadas = {};
  final Map<Herramienta, int> _herramientas = {};
  bool _tutorialPasado = false;
  bool _tutorialPremiado = false;
  String? _nombre;

  Map<String, ProgresoCuadro> get cuadros => Map.unmodifiable(_cuadros);

  ProgresoCuadro? de(String cuadroId) => _cuadros[cuadroId];

  /// Ids de los cuadros terminados alguna vez (para la progresión de biomas):
  /// los que están terminados y los desbloqueados que se están rehaciendo.
  Set<String> get completados => {
    ..._desbloqueadas,
    for (final e in _cuadros.entries)
      if (e.value.terminado) e.key,
  };

  // ---- Pintura ----------------------------------------------------------

  /// Registra regiones pintadas (una o varias, por ejemplo con la bomba).
  void pintarRegiones(String cuadroId, Iterable<String> regionIds) {
    final actual = _cuadros[cuadroId] ?? const ProgresoCuadro();
    final nuevas = [
      for (final id in regionIds)
        if (!actual.pintadas.contains(id)) id,
    ];
    if (nuevas.isEmpty) return;
    _cuadros[cuadroId] = actual.copiar(
      pintadas: [
        ...actual.pintadas,
        ...{...nuevas},
      ],
      actualizadoEn: _reloj(),
    );
    _cambio();
  }

  /// Registra una región pintada. Idempotente.
  void pintarRegion(String cuadroId, String regionId) => pintarRegiones(cuadroId, [regionId]);

  /// Marca la obra como terminada. Devuelve false si ya lo estaba.
  bool marcarCompletado(String cuadroId) {
    final actual = _cuadros[cuadroId] ?? const ProgresoCuadro();
    if (actual.terminado) return false;
    _cuadros[cuadroId] = actual.copiar(completadoEn: _reloj());
    if (dificultadDe(cuadroId) == null && cuadroId != idTutorial) _desbloqueadas.add(cuadroId);
    _cambio();
    return true;
  }

  /// Rehacer una obra: la deja en blanco para pintarla de nuevo en la
  /// dificultad [dificultadId]. Lo desbloqueado en la historia no se pierde.
  /// Devuelve la clave con la que se pinta: la misma para una obra de la
  /// historia; para una del modo libre, la de la variante nueva.
  String rehacer(String clave, String dificultadId) {
    final base = cuadroBase(clave);
    final String nueva;
    if (dificultadDe(clave) != null) {
      _cuadros.remove(clave);
      nueva = idVariante(base, dificultadId);
      _cuadros.remove(nueva);
    } else {
      if (_cuadros[clave]?.terminado ?? false) _desbloqueadas.add(clave);
      nueva = clave;
      _cuadros[clave] = ProgresoCuadro(dificultad: dificultadId, actualizadoEn: _reloj());
    }
    _cambio();
    return nueva;
  }

  void reiniciarTodo() {
    _cuadros.clear();
    _plumas = 0;
    _ultimoDiaPlumas = null;
    _introVista = false;
    _capitulosVistos.clear();
    _genero = null;
    _desbloqueadas.clear();
    _herramientas.clear();
    _tutorialPasado = false;
    _tutorialPremiado = false;
    _nombre = null;
    _cambio();
  }

  // ---- Plumas del Rocanón -----------------------------------------------

  int get plumas => _plumas;

  void sumarPlumas(int cantidad) {
    if (cantidad == 0) return;
    _plumas += cantidad;
    _cambio();
  }

  // ---- Tienda ---------------------------------------------------------------

  /// Lupas o bombas que tiene quien juega.
  int cantidad(Herramienta h) => _herramientas[h] ?? 0;

  /// Compra una herramienta con plumas. Devuelve false si no alcanzan.
  bool comprar(Herramienta h) {
    if (!puedeComprar(_plumas, h)) return false;
    _plumas -= h.precio;
    _herramientas[h] = cantidad(h) + 1;
    _cambio();
    return true;
  }

  /// Usa una herramienta del inventario. Devuelve false si no queda ninguna.
  bool usar(Herramienta h) {
    if (cantidad(h) == 0) return false;
    _herramientas[h] = cantidad(h) - 1;
    _cambio();
    return true;
  }

  /// Da la recompensa del día si todavía no se dio hoy. Devuelve lo sumado.
  int reclamarRecompensaDiaria() {
    final ahora = DateTime.fromMillisecondsSinceEpoch(_reloj());
    if (!tocaRecompensaDiaria(_ultimoDiaPlumas, ahora)) return 0;
    _ultimoDiaPlumas = diaDe(ahora);
    _plumas += ReglasPlumas.porDia;
    _cambio();
    return ReglasPlumas.porDia;
  }

  // ---- Tutorial -------------------------------------------------------------

  /// Ya se terminó o se salteó el tutorial (quien juega está del nivel 1 en adelante).
  bool get tutorialPasado => _tutorialPasado;

  /// Ya se dieron las plumas del tutorial.
  bool get tutorialPremiado => _tutorialPremiado;

  /// Saltear el tutorial: se pasa al nivel 1; el premio queda pendiente.
  void saltarTutorial() {
    if (_tutorialPasado) return;
    _tutorialPasado = true;
    _cambio();
  }

  /// Terminar el tutorial: pasa al nivel 1 y, la primera vez, da las plumas.
  /// Devuelve las plumas ganadas.
  int terminarTutorial() {
    final ganadas = _tutorialPremiado ? 0 : ReglasPlumas.porTutorial;
    _tutorialPasado = true;
    _tutorialPremiado = true;
    _plumas += ganadas;
    _cambio();
    return ganadas;
  }

  /// Volver a hacer el tutorial: se borra lo pintado (el nivel no se pierde).
  void reiniciarTutorial() {
    if (_cuadros.remove(idTutorial) != null) _cambio();
  }

  // ---- Historia -----------------------------------------------------------

  bool get introVista => _introVista;

  void marcarIntroVista() {
    if (_introVista) return;
    _introVista = true;
    _cambio();
  }

  /// Capítulos de la historia ya mostrados (uno por bioma completado).
  Set<String> get capitulosVistos => Set.unmodifiable(_capitulosVistos);

  void marcarCapituloVisto(String id) {
    if (_capitulosVistos.add(id)) _cambio();
  }

  // ---- Perfil: nombre y género ---------------------------------------------

  /// Nombre de quien juega (null = todavía no lo dijo).
  String? get nombre => _nombre;

  /// Ya dijo cómo se llama y cómo quiere que le hablen.
  bool get perfilCompleto => _nombre != null && _genero != null;

  /// Guarda el nombre (sin espacios de más; uno vacío no se guarda).
  void cambiarNombre(String nombre) {
    final limpio = nombre.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (limpio.isEmpty || limpio == _nombre) return;
    _nombre = limpio;
    _cambio();
  }

  /// Cómo prefiere que le hablen quien juega (null = todavía no eligió).
  Genero? get genero => _genero;

  void elegirGenero(Genero genero) {
    if (_genero == genero) return;
    _genero = genero;
    _cambio();
  }

  /// [texto] con las variantes `{chico|chica|neutro}` resueltas (sin elección,
  /// la neutra) y `{nombre}` cambiado por el nombre de quien juega.
  String texto(String texto) =>
      conGenero(texto, _genero ?? Genero.neutro).replaceAll('{nombre}', _nombre ?? '');

  // ---- Música -------------------------------------------------------------

  bool get musicaSilenciada => _musicaSilenciada;

  void silenciarMusica(bool silenciada) {
    if (_musicaSilenciada == silenciada) return;
    _musicaSilenciada = silenciada;
    _cambio();
  }

  // ---- Guardado -----------------------------------------------------------

  /// Escritura en curso (los tests la esperan).
  Future<void> guardado = Future.value();

  void _cambio() {
    notifyListeners();
    final datos = jsonEncode({
      'version': version,
      'cuadros': {for (final e in _cuadros.entries) e.key: e.value.aJson()},
      'plumas': _plumas,
      'ultimoDiaPlumas': ?_ultimoDiaPlumas,
      'introVista': _introVista,
      'capitulosVistos': _capitulosVistos.toList(),
      'musicaSilenciada': _musicaSilenciada,
      'genero': ?_genero?.name,
      'desbloqueadas': _desbloqueadas.toList(),
      for (final h in Herramienta.values) h.name: cantidad(h),
      'tutorialPasado': _tutorialPasado,
      'tutorialPremiado': _tutorialPremiado,
      'nombre': ?_nombre,
    });
    // Se encadenan para que nunca una escritura vieja pise a una nueva.
    guardado = guardado.then((_) => _almacen.escribir(datos));
  }
}
