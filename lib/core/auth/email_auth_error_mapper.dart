import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:newsreader/core/errors/app_error_code.dart';

/// Traduce un error de Supabase Auth durante el login con correo y código a
/// un [AppErrorCode]. Es el único lugar que conoce los códigos de error de
/// Supabase para este flujo.
///
/// Un código incorrecto y uno expirado llegan igual (`otp_expired`, "Token
/// has expired or is invalid"), por eso comparten [AppErrorCode.invalidEmailCode].
AppErrorCode mapEmailAuthError(Object error) {
  if (error is sb.AuthRetryableFetchException || error is SocketException) {
    return AppErrorCode.network;
  }
  if (error is TimeoutException) return AppErrorCode.timeout;

  if (error is sb.AuthException) {
    switch (error.code) {
      case 'otp_expired':
        return AppErrorCode.invalidEmailCode;
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
        return AppErrorCode.tooManyAuthRequests;
      case 'validation_failed':
      case 'email_address_invalid':
        return AppErrorCode.invalidEmail;
    }
    // Respuestas sin `code` (servidores o versiones más viejas).
    if (error.statusCode == '429') return AppErrorCode.tooManyAuthRequests;
    if (error.message.toLowerCase().contains('expired or is invalid')) {
      return AppErrorCode.invalidEmailCode;
    }
  }

  return AppErrorCode.unknown;
}
