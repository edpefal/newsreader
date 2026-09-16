import 'dart:ui' as ui;

/// Códigos de idioma soportados por `AppLocalizations`, mismo orden que
/// `App.supportedLocales` (inglés primero, es el fallback).
const _supportedLanguageCodes = ['en', 'es', 'fr'];

/// Resuelve el código de idioma activo de la app sin depender de un
/// `BuildContext` -- `SyncUserData` no tiene uno, a diferencia de los
/// widgets que llaman a `Localizations.localeOf(context)`. Replica el mismo
/// criterio que usa Flutter para resolver `MaterialApp.supportedLocales`
/// contra el locale del sistema: si el idioma del dispositivo está
/// soportado se usa ese, si no cae a inglés.
class ActiveLocaleResolver {
  const ActiveLocaleResolver._();

  static String resolve() {
    final deviceLanguageCode =
        ui.PlatformDispatcher.instance.locale.languageCode;
    return _supportedLanguageCodes.contains(deviceLanguageCode)
        ? deviceLanguageCode
        : 'en';
  }
}
