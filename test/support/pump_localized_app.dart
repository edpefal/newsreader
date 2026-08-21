import 'package:flutter/widgets.dart';

import 'package:newsreader/l10n/app_localizations.dart';

/// Configuración de localización compartida para widget tests.
///
/// Cada test que arma su propio `MaterialApp`/`MaterialApp.router` agrega
/// estas constantes como parámetros nombrados (`locale:
/// testLocale, localizationsDelegates: testLocalizationsDelegates,
/// supportedLocales: testSupportedLocales`) en vez de reimplementar la
/// configuración de localización en cada archivo. El locale de test fijo en
/// español evita que las aserciones de texto dependan del locale de la
/// máquina/CI que corre los tests.
const testLocale = Locale('es');

const testLocalizationsDelegates = AppLocalizations.localizationsDelegates;

const testSupportedLocales = AppLocalizations.supportedLocales;
