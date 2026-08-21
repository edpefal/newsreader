import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guarda contra la regresión que motivó este change: `app_fr.arb` empezó
/// como una copia literal de `app_en.arb` (placeholder). Compara clave por
/// clave y falla si alguna quedó sin traducir, para detectarlo apenas se
/// agregue una clave nueva sin su traducción al francés.
void main() {
  test('app_fr.arb no tiene valores idénticos a app_en.arb sin traducir', () {
    final enFile = File('lib/l10n/app_en.arb');
    final frFile = File('lib/l10n/app_fr.arb');
    final en = jsonDecode(enFile.readAsStringSync()) as Map;
    final fr = jsonDecode(frFile.readAsStringSync()) as Map;

    // Claves donde es correcto que el valor sea igual en inglés y francés:
    // nombre de marca, o palabras que se escriben igual en ambos idiomas
    // (cognados reales, no traducciones olvidadas).
    const allowedIdentical = {
      'appTitle', // nombre de marca
      'navInbox', // se mantiene igual en los 3 idiomas
      'navSources', // "Sources" se escribe igual en francés
      'summaryListArticleCount', // "article"/"articles" es igual en francés
    };

    final untranslated = <String>[];
    for (final entry in fr.entries) {
      final key = entry.key as String;
      if (key.startsWith('@')) continue; // metadata, no contenido
      if (allowedIdentical.contains(key)) continue;
      final frValue = entry.value;
      final enValue = en[key];
      if (frValue is! String || enValue is! String) continue;
      if (frValue == enValue) {
        untranslated.add('$key: "$frValue"');
      }
    }

    expect(
      untranslated,
      isEmpty,
      reason: 'Claves de app_fr.arb idénticas a app_en.arb (sin traducir):\n'
          '${untranslated.join('\n')}',
    );
  });
}
