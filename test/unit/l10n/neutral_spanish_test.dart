import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guarda contra la regresión que motivó este change: mezcla de voseo
/// rioplatense y tuteo en el español de la app. Lee `app_es.arb` directo
/// (no la clase generada) para cubrir automáticamente cualquier clave
/// nueva sin tener que mantener una lista de getters a mano.
void main() {
  test('app_es.arb no contiene conjugaciones de voseo', () {
    final arbFile = File('lib/l10n/app_es.arb');
    final content = jsonDecode(arbFile.readAsStringSync()) as Map;

    // Formas de voseo detectadas en el código original (imperativo/presente
    // de 2da persona singular con "vos" en vez de "tú") más otras comunes.
    final voseoPattern = RegExp(
      r'\b('
      r'tocá|tocás|agregá|agregás|mirá|mirás|'
      r'suscribí|suscribís|iniciá|iniciás|creá|creás|'
      r'traé|traés|tené|tenés|podés|querés|sabés|'
      r'intentá|intentás|dejá|dejás|'
      r'vos|sos'
      r')\b',
      caseSensitive: false,
    );

    final offenders = <String>[];
    for (final entry in content.entries) {
      final key = entry.key as String;
      if (key.startsWith('@')) continue; // metadata, no contenido
      final value = entry.value;
      if (value is! String) continue;
      if (voseoPattern.hasMatch(value)) {
        offenders.add('$key: "$value"');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Se detectó voseo en app_es.arb (debe ser tuteo neutro):\n'
          '${offenders.join('\n')}',
    );
  });
}
