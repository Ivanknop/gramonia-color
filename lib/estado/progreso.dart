/// Progreso del jugador, guardado en el teléfono entre sesiones.
///
/// Solo se guarda lo mínimo (regiones pintadas y fechas). Lo derivado
/// —porcentajes, piezas, biomas— se calcula con el motor.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/plumas.dart';

class ProgresoCuadro {
  const ProgresoCuadro({this.pintadas = const [], this.actualizadoEn, this.completadoEn});

  factory ProgresoCuadro.desdeJson(Map<String, dynamic> j) => ProgresoCuadro(
    pintadas: [for (final id in j['pintadas'] as List) id as String],
    actualizadoEn: j['actualizadoEn'] as int?,
    completadoEn: j['completadoEn'] as int?,
  );

  /// Ids de regiones pintadas, en el orden en que se pintaron.
  final List<String> pintadas;

  /// Momento (ms) de la última región pintada (para ordenar "Mis obras").
  final int? actualizadoEn;

  /// Momento (ms) en que se completó; null si no se terminó.
  final int? completadoEn;

  bool get terminado => completadoEn != null;

  Map<String, dynamic> aJson() => {
    'pintadas': pintadas,
    if (actualizadoEn != null) 'actualizadoEn': actualizadoEn,
    if (completadoEn != null) 'completadoEn': completadoEn,
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
  static const version = 2;

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

  Map<String, ProgresoCuadro> get cuadros => Map.unmodifiable(_cuadros);

  ProgresoCuadro? de(String cuadroId) => _cuadros[cuadroId];

  /// Ids de los cuadros terminados (para la progresión de biomas).
  Set<String> get completados => {
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
    _cuadros[cuadroId] = ProgresoCuadro(
      pintadas: [
        ...actual.pintadas,
        ...{...nuevas},
      ],
      actualizadoEn: _reloj(),
      completadoEn: actual.completadoEn,
    );
    _cambio();
  }

  /// Registra una región pintada. Idempotente.
  void pintarRegion(String cuadroId, String regionId) => pintarRegiones(cuadroId, [regionId]);

  /// Marca la obra como terminada. Devuelve false si ya lo estaba.
  bool marcarCompletado(String cuadroId) {
    final actual = _cuadros[cuadroId] ?? const ProgresoCuadro();
    if (actual.terminado) return false;
    _cuadros[cuadroId] = ProgresoCuadro(
      pintadas: actual.pintadas,
      actualizadoEn: actual.actualizadoEn,
      completadoEn: _reloj(),
    );
    _cambio();
    return true;
  }

  void reiniciarCuadro(String cuadroId) {
    if (_cuadros.remove(cuadroId) != null) _cambio();
  }

  void reiniciarTodo() {
    _cuadros.clear();
    _plumas = 0;
    _ultimoDiaPlumas = null;
    _introVista = false;
    _capitulosVistos.clear();
    _cambio();
  }

  // ---- Plumas del Rocanón -----------------------------------------------

  int get plumas => _plumas;

  void sumarPlumas(int cantidad) {
    if (cantidad == 0) return;
    _plumas += cantidad;
    _cambio();
  }

  /// Cobra una herramienta. Con [ReglasPlumas.herramientasGratis] no descuenta
  /// nada. Devuelve false si no alcanza.
  bool gastarPlumas(int costo) {
    if (ReglasPlumas.herramientasGratis) return true;
    if (_plumas < costo) return false;
    _plumas -= costo;
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
    });
    // Se encadenan para que nunca una escritura vieja pise a una nueva.
    guardado = guardado.then((_) => _almacen.escribir(datos));
  }
}
