import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:newsreader/core/utils/localized_date_formatter.dart';
import 'package:newsreader/l10n/app_localizations.dart';

Widget _wrap(Locale locale, Widget Function(BuildContext) builder) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(builder: builder),
  );
}

void main() {
  group('LocalizedDateFormatter.dayLabel', () {
    testWidgets('devuelve la etiqueta de "hoy" en el idioma activo', (
      tester,
    ) async {
      final results = <Locale, String>{};
      for (final locale in const [Locale('en'), Locale('es'), Locale('fr')]) {
        await tester.pumpWidget(
          _wrap(locale, (context) {
            results[locale] =
                LocalizedDateFormatter.dayLabel(context, DateTime.now());
            return const SizedBox.shrink();
          }),
        );
      }

      expect(results[const Locale('en')], 'Today');
      expect(results[const Locale('es')], 'Hoy');
      expect(results[const Locale('fr')], 'Today'); // placeholder fr = en
    });

    testWidgets('devuelve la etiqueta de "ayer" en español', (tester) async {
      String? result;
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await tester.pumpWidget(
        _wrap(const Locale('es'), (context) {
          result = LocalizedDateFormatter.dayLabel(context, yesterday);
          return const SizedBox.shrink();
        }),
      );

      expect(result, 'Ayer');
    });

    testWidgets('usa mes abreviado y localizado para fechas del año actual', (
      tester,
    ) async {
      final now = DateTime.now();
      final sameYearOldDate = DateTime(now.year, 1, 1);
      String? esResult;
      String? enResult;

      await tester.pumpWidget(
        _wrap(const Locale('es'), (context) {
          esResult =
              LocalizedDateFormatter.dayLabel(context, sameYearOldDate);
          return const SizedBox.shrink();
        }),
      );
      await tester.pumpWidget(
        _wrap(const Locale('en'), (context) {
          enResult =
              LocalizedDateFormatter.dayLabel(context, sameYearOldDate);
          return const SizedBox.shrink();
        }),
      );

      expect(esResult, isNot(contains(now.year.toString())));
      expect(enResult, isNot(contains(now.year.toString())));
      expect(esResult, isNot(equals(enResult)));
    });

    testWidgets('incluye el año para fechas de otro año', (tester) async {
      String? result;
      await tester.pumpWidget(
        _wrap(const Locale('es'), (context) {
          result = LocalizedDateFormatter.dayLabel(
            context,
            DateTime(2020, 6, 15),
          );
          return const SizedBox.shrink();
        }),
      );

      expect(result, contains('2020'));
    });
  });

  group('LocalizedDateFormatter.articleTileDate', () {
    testWidgets('muestra hora HH:mm para hoy', (tester) async {
      String? result;
      final now = DateTime.now();
      await tester.pumpWidget(
        _wrap(const Locale('es'), (context) {
          result = LocalizedDateFormatter.articleTileDate(context, now);
          return const SizedBox.shrink();
        }),
      );

      expect(result, matches(RegExp(r'^\d{2}:\d{2}$')));
    });

    testWidgets('muestra "{n}d" para artículos de esta semana', (
      tester,
    ) async {
      String? result;
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      await tester.pumpWidget(
        _wrap(const Locale('es'), (context) {
          result =
              LocalizedDateFormatter.articleTileDate(context, threeDaysAgo);
          return const SizedBox.shrink();
        }),
      );

      expect(result, '3d');
    });
  });

  group('LocalizedDateFormatter.longDate', () {
    testWidgets('formatea con mes abreviado y año, localizado', (
      tester,
    ) async {
      final date = DateTime(2024, 3, 15);
      String? esResult;
      String? frResult;

      await tester.pumpWidget(
        _wrap(const Locale('es'), (context) {
          esResult = LocalizedDateFormatter.longDate(context, date);
          return const SizedBox.shrink();
        }),
      );
      await tester.pumpWidget(
        _wrap(const Locale('fr'), (context) {
          frResult = LocalizedDateFormatter.longDate(context, date);
          return const SizedBox.shrink();
        }),
      );

      expect(esResult, contains('2024'));
      expect(esResult, contains('15'));
      expect(frResult, contains('2024'));
    });
  });
}
