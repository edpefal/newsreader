import 'dart:async';

import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:newsreader/core/observability/observability_client.dart';

class SentryObservabilityClient implements ObservabilityClient {
  /// Inicializa el SDK de Sentry y arranca la app dentro de la zona que
  /// instala. `SentryFlutter.init` ya registra `FlutterError.onError` y
  /// `PlatformDispatcher.instance.onError` — no hace falta setearlos a mano.
  static Future<void> init({
    required String dsn,
    required bool isProd,
    required FutureOr<void> Function() appRunner,
  }) {
    return SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.environment = isProd ? 'production' : 'development';
        // Explícito aunque ya sea el default del SDK: nunca se manda email
        // ni otra PII del dispositivo/usuario a Sentry.
        options.sendDefaultPii = false;
      },
      appRunner: appRunner,
    );
  }

  @override
  void captureException(
    Object error,
    StackTrace stackTrace, {
    Map<String, Object?>? context,
  }) {
    Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: context == null
          ? null
          : (scope) => scope.setContexts('extra', context),
    );
  }

  @override
  void captureMessage(String message, {ObservabilityLevel level = ObservabilityLevel.info}) {
    Sentry.captureMessage(message, level: _toSentryLevel(level));
  }

  @override
  void addBreadcrumb(String message, {String? category, Map<String, Object?>? data}) {
    Sentry.addBreadcrumb(
      Breadcrumb(message: message, category: category, data: data),
    );
  }

  @override
  void trackEvent(String name, {Map<String, Object?>? properties}) {
    Sentry.addBreadcrumb(
      Breadcrumb(message: name, category: 'event', data: properties),
    );
  }

  @override
  void setUserId(String? userId) {
    Sentry.configureScope((scope) {
      scope.setUser(userId == null ? null : SentryUser(id: userId));
    });
  }

  SentryLevel _toSentryLevel(ObservabilityLevel level) {
    switch (level) {
      case ObservabilityLevel.debug:
        return SentryLevel.debug;
      case ObservabilityLevel.info:
        return SentryLevel.info;
      case ObservabilityLevel.warning:
        return SentryLevel.warning;
      case ObservabilityLevel.error:
        return SentryLevel.error;
      case ObservabilityLevel.fatal:
        return SentryLevel.fatal;
    }
  }
}
