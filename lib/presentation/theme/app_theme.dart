import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Acento ámbar reservado exclusivamente para dos usos funcionales:
/// el indicador de artículo no leído y el estado de favorito. Vive fuera
/// de [ColorScheme] (en vez de `tertiary`/`secondary`) para que ningún
/// widget Material lo use implícitamente.
@immutable
class ReevoAccent extends ThemeExtension<ReevoAccent> {
  final Color unreadFavoriteAmber;

  const ReevoAccent({required this.unreadFavoriteAmber});

  static const ReevoAccent light = ReevoAccent(
    unreadFavoriteAmber: Color(0xFFD9A441),
  );

  // Ámbar más claro y saturado que el de light: el mismo #D9A441 se
  // calibró contra el fondo _paper claro y pierde contraste sobre el
  // fondo oscuro de _darkSurface.
  static const ReevoAccent dark = ReevoAccent(
    unreadFavoriteAmber: Color(0xFFF4BB55),
  );

  @override
  ReevoAccent copyWith({Color? unreadFavoriteAmber}) => ReevoAccent(
        unreadFavoriteAmber: unreadFavoriteAmber ?? this.unreadFavoriteAmber,
      );

  @override
  ReevoAccent lerp(ThemeExtension<ReevoAccent>? other, double t) {
    if (other is! ReevoAccent) return this;
    return ReevoAccent(
      unreadFavoriteAmber:
          Color.lerp(unreadFavoriteAmber, other.unreadFavoriteAmber, t)!,
    );
  }
}

class AppTheme {
  AppTheme._();

  static const _ink = Color(0xFF0A0A0A);
  static const _paper = Color(0xFFFAFAF8);
  static const _hairline = Color(0x1A0A0A0A);

  // Paleta dark diseñada a mano (no es la inversión matemática de
  // _ink/_paper): _darkSurface es gris muy oscuro en vez de negro puro, y
  // _darkOnSurface es un blanco cálido no puro -- negro/blanco puro es
  // peor para legibilidad sostenida en una app de lectura y da halo en
  // paneles OLED.
  static const _darkSurface = Color(0xFF121212);
  static const _darkOnSurface = Color(0xFFEDEBE7);
  static const _darkHairline = Color(0x1FEDEBE7);

  static ThemeData get light {
    final colorScheme = ColorScheme.light(
      primary: _ink,
      onPrimary: _paper,
      secondary: _ink,
      onSecondary: _paper,
      surface: _paper,
      onSurface: _ink,
      error: const Color(0xFFB3261E),
      onError: _paper,
    ).copyWith(
      surfaceContainerHighest: _hairline,
      outline: _hairline,
      // Sin esto, el indicador de selección del NavigationDrawer M3 (que
      // usa secondaryContainer por default) hereda el negro de `secondary`
      // de arriba, resultando en una pill oscura que domina la pantalla.
      secondaryContainer: _hairline,
      onSecondaryContainer: _ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _paper,
      textTheme: _textTheme(_ink),
      extensions: const [ReevoAccent.light],
      appBarTheme: AppBarTheme(
        backgroundColor: _paper,
        foregroundColor: _ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.dark(
      primary: _darkOnSurface,
      onPrimary: _darkSurface,
      secondary: _darkOnSurface,
      onSecondary: _darkSurface,
      surface: _darkSurface,
      onSurface: _darkOnSurface,
      error: const Color(0xFFCF6679),
      onError: _darkSurface,
    ).copyWith(
      surfaceContainerHighest: _darkHairline,
      outline: _darkHairline,
      // Mismo motivo que en light: sin esto el indicador de selección del
      // NavigationDrawer hereda `secondary` (blanco cálido) y queda una
      // pill clara dominante sobre fondo oscuro.
      secondaryContainer: _darkHairline,
      onSecondaryContainer: _darkOnSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _darkSurface,
      textTheme: _textTheme(_darkOnSurface),
      extensions: const [ReevoAccent.dark],
      appBarTheme: AppBarTheme(
        backgroundColor: _darkSurface,
        foregroundColor: _darkOnSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }

  // Google Fonts hornea su propio color (cercano a negro) en cada estilo
  // que devuelve, así que la resolución automática de color por brightness
  // de ThemeData nunca lo pisa (solo rellena campos nulos). Sin este
  // `.apply()`, todo headline/title queda oscuro también en dark.
  static TextTheme _textTheme(Color color) {
    final sans = GoogleFonts.ibmPlexSansTextTheme();
    final serif = GoogleFonts.newsreaderTextTheme();
    return sans
        .copyWith(
          headlineLarge: serif.headlineLarge,
          headlineMedium: serif.headlineMedium,
          headlineSmall: serif.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          titleLarge: serif.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          titleMedium: serif.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: sans.bodyLarge?.copyWith(fontSize: 18, height: 1.6),
          bodyMedium: sans.bodyMedium?.copyWith(fontSize: 15, height: 1.5),
        )
        .apply(bodyColor: color, displayColor: color, decorationColor: color);
  }
}
