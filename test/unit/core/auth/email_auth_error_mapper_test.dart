import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:newsreader/core/auth/email_auth_error_mapper.dart';
import 'package:newsreader/core/errors/app_error_code.dart';

void main() {
  group('mapEmailAuthError', () {
    test('otp_expired (código incorrecto o expirado) -> invalidEmailCode', () {
      const error = sb.AuthApiException(
        'Token has expired or is invalid',
        statusCode: '403',
        code: 'otp_expired',
      );

      expect(mapEmailAuthError(error), AppErrorCode.invalidEmailCode);
    });

    test(
      'sin code pero con el mensaje de token inválido -> invalidEmailCode',
      () {
        const error = sb.AuthApiException(
          'Token has expired or is invalid',
          statusCode: '403',
        );

        expect(mapEmailAuthError(error), AppErrorCode.invalidEmailCode);
      },
    );

    test('límites de envío o de solicitudes -> tooManyAuthRequests', () {
      for (final code in [
        'over_email_send_rate_limit',
        'over_request_rate_limit',
      ]) {
        final error = sb.AuthApiException(
          'rate',
          statusCode: '429',
          code: code,
        );

        expect(mapEmailAuthError(error), AppErrorCode.tooManyAuthRequests);
      }
    });

    test('429 sin code -> tooManyAuthRequests', () {
      const error = sb.AuthApiException('slow down', statusCode: '429');

      expect(mapEmailAuthError(error), AppErrorCode.tooManyAuthRequests);
    });

    test('validation_failed y email_address_invalid -> invalidEmail', () {
      for (final code in ['validation_failed', 'email_address_invalid']) {
        final error = sb.AuthApiException('bad', statusCode: '400', code: code);

        expect(mapEmailAuthError(error), AppErrorCode.invalidEmail);
      }
    });

    test('fallo de red -> network', () {
      expect(
        mapEmailAuthError(sb.AuthRetryableFetchException(message: 'x')),
        AppErrorCode.network,
      );
      expect(
        mapEmailAuthError(const SocketException('sin red')),
        AppErrorCode.network,
      );
    });

    test('timeout -> timeout', () {
      expect(
        mapEmailAuthError(TimeoutException('lento')),
        AppErrorCode.timeout,
      );
    });

    test('cualquier otro error -> unknown', () {
      expect(mapEmailAuthError(StateError('x')), AppErrorCode.unknown);
      expect(
        mapEmailAuthError(const sb.AuthApiException('?', code: 'otra_cosa')),
        AppErrorCode.unknown,
      );
    });
  });
}
