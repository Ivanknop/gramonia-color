/// Progreso del jugador, guardado en el teléfono entre sesiones.
///
/// Solo se guarda lo mínimo (regiones pintadas y fechas). Lo derivado
/// —porcentajes, piezas, biomas— se calcula con el motor.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Progreso._(this._almacen, this._cuadros, this._reloj);

  static const version = 1;

  static Future<Progreso> cargar(AlmacenProgreso almacen, {int Function()? reloj}) async {
    final cuadros = <String, ProgresoCuadro>{};
    final texto = await almacen.leer();
    if (texto != null) {
      try {
        final j = jsonDecode(texto) as Map<String, dynamic>;
        for (final e in (j['cuadros'] as Map<String, dynamic>).entries) {
          cuadros[e.key] = ProgresoCuadro.desdeJson(e.value as Map<String, dynamic>);
        }
      } on Object catch (e) {
        // Datos corruptos: se empieza de cero antes que no poder jugar.
        debugPrint('No se pudo leer el progreso guardado: $e');
      }
    }
    return Progreso._(almacen, cuadros, reloj ?? () => DateTime.now().millisecondsSinceEpoch);
  }

  final AlmacenProgreso _almacen;
  final Map<String, ProgresoCuadro> _cuadros;
  final int Function() _reloj;

  Map<String, ProgresoCuadro> get cuadros => Map.unmodifiable(_cuadros);

  ProgresoCuadro? de(String cuadroId) => _cuadros[cuadroId];

  /// Ids de los cuadros terminados (para la progresión de biomas).
  Set<String> get completados => {
    for (final e in _cuadros.entries)
      if (e.value.terminado) e.key,
  };

  /// Registra una región pintada. Idempotente.
  void pintarRegion(String cuadroId, String regionId) {
    final actual = _cuadros[cuadroId] ?? const ProgresoCuadro();
    if (actual.pintadas.contains(regionId)) return;
    _cuadros[cuadroId] = ProgresoCuadro(
      pintadas: [...actual.pintadas, regionId],
      actualizadoEn: _reloj(),
      completadoEn: actual.completadoEn,
    );
    _cambio();
  }

  void marcarCompletado(String cuadroId) {
    final actual = _cuadros[cuadroId] ?? const ProgresoCuadro();
    if (actual.terminado) return;
    _cuadros[cuadroId] = ProgresoCuadro(
      pintadas: actual.pintadas,
      actualizadoEn: actual.actualizadoEn,
      completadoEn: _reloj(),
    );
    _cambio();
  }

  void reiniciarCuadro(String cuadroId) {
    if (_cuadros.remove(cuadroId) != null) _cambio();
  }

  void reiniciarTodo() {
    _cuadros.clear();
    _cambio();
  }

  /// Escritura en curso (los tests la esperan).
  Future<void> guardado = Future.value();

  void _cambio() {
    notifyListeners();
    final datos = jsonEncode({
      'version': version,
      'cuadros': {for (final e in _cuadros.entries) e.key: e.value.aJson()},
    });
    // Se encadenan para que nunca una escritura vieja pise a una nueva.
    guardado = guardado.then((_) => _almacen.escribir(datos));
  }
}
