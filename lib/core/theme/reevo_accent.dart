import 'package:flutter/material.dart';

/// Acento óxido de marca de Reevo: indicador de no leído, estado de
/// favorito, y placeholder de ícono de fuente sin imagen propia. Vive fuera
/// de [ColorScheme] (en vez de `tertiary`/`secondary`) para que ningún
/// widget Material lo use implícitamente -- los botones/CTA que sí lo usan
/// (`filledButtonTheme`/`floatingActionButtonTheme` en `AppTheme`) lo
/// referencian de forma explícita, no vía `colorScheme.primary`.
@immutable
class ReevoAccent extends ThemeExtension<ReevoAccent> {
  final Color unreadFavoriteAccent;

  const ReevoAccent({required this.unreadFavoriteAccent});

  static const ReevoAccent light = ReevoAccent(
    unreadFavoriteAccent: Color(0xFFC1401F),
  );

  // Óxido más claro y saturado que el de light: el mismo #C1401F se
  // calibró contra el fondo _paper claro y pierde contraste sobre el
  // fondo oscuro de _darkSurface.
  static const ReevoAccent dark = ReevoAccent(
    unreadFavoriteAccent: Color(0xFFE2794D),
  );

  @override
  ReevoAccent copyWith({Color? unreadFavoriteAccent}) => ReevoAccent(
        unreadFavoriteAccent: unreadFavoriteAccent ?? this.unreadFavoriteAccent,
      );

  @override
  ReevoAccent lerp(ThemeExtension<ReevoAccent>? other, double t) {
    if (other is! ReevoAccent) return this;
    return ReevoAccent(
      unreadFavoriteAccent:
          Color.lerp(unreadFavoriteAccent, other.unreadFavoriteAccent, t)!,
    );
  }
}
