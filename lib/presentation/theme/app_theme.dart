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
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _paper,
      textTheme: _textTheme,
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

  // El rediseño de la Dirección C es explícitamente light-mode (ver
  // design.md - Non-Goals / Risks). Dark se mantiene con el theme
  // Material 3 anterior hasta que se aborde en un change futuro.
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.dark,
        ),
        textTheme: _textTheme,
      );

  static TextTheme get _textTheme {
    final sans = GoogleFonts.ibmPlexSansTextTheme();
    final serif = GoogleFonts.newsreaderTextTheme();
    return sans.copyWith(
      headlineLarge: serif.headlineLarge,
      headlineMedium: serif.headlineMedium,
      headlineSmall: serif.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleLarge: serif.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: serif.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: sans.bodyLarge?.copyWith(fontSize: 18, height: 1.6),
      bodyMedium: sans.bodyMedium?.copyWith(fontSize: 15, height: 1.5),
    );
  }
}
