/// Colores del juego y acceso al catálogo y al progreso desde los widgets.
library;

import 'package:material_ui/material_ui.dart';

import '../datos/catalogo.dart';
import '../estado/progreso.dart';

abstract final class Tema {
  static const morado = Color(0xFF3D2C5E);
  static const crema = Color(0xFFFFF8EC);
  static const fondoLienzo = Color(0xFFF4F1EA);
  static const verde = Color(0xFF38761D);
  static const gris = Color(0xFF777777);

  static ThemeData get datos => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: morado),
    scaffoldBackgroundColor: crema,
  );
}

/// Catálogo y progreso disponibles para toda la app.
class Dependencias extends InheritedWidget {
  const Dependencias({
    super.key,
    required this.catalogo,
    required this.progreso,
    required super.child,
  });

  final Catalogo catalogo;
  final Progreso progreso;

  static Dependencias of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Dependencias>()!;

  @override
  bool updateShouldNotify(Dependencias old) => catalogo != old.catalogo || progreso != old.progreso;
}

/// Formato de fecha corto (dd/mm/aaaa) sin depender de paquetes de i18n.
String fechaCorta(int? ms) {
  if (ms == null) return '';
  final f = DateTime.fromMillisecondsSinceEpoch(ms);
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(f.day)}/${dos(f.month)}/${f.year}';
}
