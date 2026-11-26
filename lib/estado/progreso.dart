/// Progreso guardado en el teléfono: solo lo mínimo (regiones pintadas y fechas). Lo derivado se
/// calcula con el motor.
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

  /// Al cambiar lo guardado: subirla, migrar en [cargar] y sumar el test de migración.
  static const version = 9;

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
        // Campos de v8.
        p._regaloInicial = (j['regaloInicial'] as bool?) ?? false;
        p._plumasTiendaDadas = (j['plumasTienda'] as bool?) ?? false;
        p._tutorialTiendaHecho = (j['tutorialTienda'] as bool?) ?? false;
        // v9: sin las variantes de las dificultades retiradas.
        p._cuadros.removeWhere(
          (id, c) =>
              dificultadesRetiradas.contains(dificultadDe(id)) ||
              dificultadesRetiradas.contains(c.dificultad),
        );
        // Upgrade: quien ya estaba en el nivel 1 o más recibe el regalo ahora.
        if (p._darRegaloInicial()) p._cambio();
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
  bool _regaloInicial = false;
  bool _plumasTiendaDadas = false;
  bool _tutorialTiendaHecho = false;

  Map<String, ProgresoCuadro> get cuadros => Map.unmodifiable(_cuadros);

  ProgresoCuadro? de(String cuadroId) => _cuadros[cuadroId];

  /// Ids de los cuadros terminados alguna vez (para la progresión de biomas):
  /// los que están terminados y los desbloqueados que se están rehaciendo.
  Set<String> get completados => {
    ..._desbloqueadas,
    for (final e in _cuadros.entries)
      if (e.value.terminado) e.key,
  };

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

  int get plumas => _plumas;

  void sumarPlumas(int cantidad) {
    if (cantidad == 0) return;
    _plumas += cantidad;
    _cambio();
  }

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

  bool get tutorialPasado => _tutorialPasado;
  bool get tutorialPremiado => _tutorialPremiado;

  /// Saltear el tutorial: se pasa al nivel 1; el premio queda pendiente.
  void saltarTutorial() {
    if (_tutorialPasado) return;
    _tutorialPasado = true;
    _darRegaloInicial();
    _cambio();
  }

  bool get regaloInicial => _regaloInicial;

  /// Al llegar al nivel 1 (una sola vez): [herramientasIniciales]. Devuelve
  /// si se dio ahora (sin guardar: lo guarda quien llama).
  bool _darRegaloInicial() {
    if (_regaloInicial || !_tutorialPasado) return false;
    _regaloInicial = true;
    for (final MapEntry(key: h, value: n) in herramientasIniciales.entries) {
      _herramientas[h] = cantidad(h) + n;
    }
    return true;
  }

  bool get tutorialTiendaHecho => _tutorialTiendaHecho;

  /// Empieza el tutorial de la tienda: la primera vez regala las plumas para
  /// la lupa. Devuelve las plumas regaladas.
  int empezarTutorialTienda() {
    if (_plumasTiendaDadas || _tutorialTiendaHecho) return 0;
    _plumasTiendaDadas = true;
    _plumas += plumasTutorialTienda;
    _cambio();
    return plumasTutorialTienda;
  }

  void terminarTutorialTienda() {
    if (_tutorialTiendaHecho) return;
    _tutorialTiendaHecho = true;
    _cambio();
  }

  /// Terminar el tutorial: pasa al nivel 1 y, la primera vez, da las plumas.
  /// Devuelve las plumas ganadas.
  int terminarTutorial() {
    final ganadas = _tutorialPremiado ? 0 : ReglasPlumas.porTutorial;
    _tutorialPasado = true;
    _tutorialPremiado = true;
    _plumas += ganadas;
    _darRegaloInicial();
    _cambio();
    return ganadas;
  }

  /// Volver a hacer el tutorial: se borra lo pintado (el nivel no se pierde).
  void reiniciarTutorial() {
    if (_cuadros.remove(idTutorial) != null) _cambio();
  }

  bool get introVista => _introVista;

  void marcarIntroVista() {
    if (_introVista) return;
    _introVista = true;
    _cambio();
  }

  Set<String> get capitulosVistos => Set.unmodifiable(_capitulosVistos);

  void marcarCapituloVisto(String id) {
    if (_capitulosVistos.add(id)) _cambio();
  }

  String? get nombre => _nombre;
  bool get perfilCompleto => _nombre != null && _genero != null;

  /// Guarda el nombre (sin espacios de más; uno vacío no se guarda).
  void cambiarNombre(String nombre) {
    final limpio = nombre.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (limpio.isEmpty || limpio == _nombre) return;
    _nombre = limpio;
    _cambio();
  }

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

  bool get musicaSilenciada => _musicaSilenciada;

  void silenciarMusica(bool silenciada) {
    if (_musicaSilenciada == silenciada) return;
    _musicaSilenciada = silenciada;
    _cambio();
  }

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
      'regaloInicial': _regaloInicial,
      'plumasTienda': _plumasTiendaDadas,
      'tutorialTienda': _tutorialTiendaHecho,
    });
    // Se encadenan para que nunca una escritura vieja pise a una nueva.
    guardado = guardado.then((_) => _almacen.escribir(datos));
  }
}
