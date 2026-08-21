import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/core/errors/app_error_code_localizations.dart';
import 'package:newsreader/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'cada AppErrorCode resuelve a un string no vacío en los 3 idiomas',
    (tester) async {
      for (final locale in AppLocalizations.supportedLocales) {
        late AppLocalizations l10n;
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                l10n = AppLocalizations.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        for (final code in AppErrorCode.values) {
          final text = code.localize(l10n);
          expect(
            text,
            isNotEmpty,
            reason: '$code no resolvió texto para locale $locale',
          );
        }
      }
    },
  );
}
