import 'dart:async';

import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:newsreader/core/observability/telemetry_client.dart';

class DefaultTelemetryClient implements TelemetryClient {
  /// `Posthog().reset()` (ver [setUserId]) borra todas las super properties,
  /// incluida `environment` -- se guarda acá para poder re-registrarla justo
  /// después del reset, o la propiedad queda en `null` en todos los eventos
  /// posteriores al primer logout de la sesión.
  static String? _environment;

  /// Inicializa el SDK de PostHog. Se llama por separado de [init] (y antes
  /// que cualquier `trackEvent`/`setUserId`), porque `init` recién arranca
  /// Sentry al final de `main()`, envolviendo `runApp` en su zona -- si
  /// PostHog se inicializara ahí también, cualquier `setUserId` disparado
  /// antes (por ejemplo al identificar la sesión ya activa) llamaría a
  /// `Posthog().identify` antes de que el SDK esté listo.
  ///
  /// Dev y prod comparten el mismo proyecto de PostHog (el plan free solo
  /// permite 1 Project); se distinguen registrando `environment` como super
  /// property, que queda adjunta a todos los eventos siguientes.
  static Future<void> initPostHog(String apiKey, {required bool isProd}) async {
    await Posthog().setup(
      PostHogConfig(apiKey)
        ..host = 'https://us.i.posthog.com'
        // Autocapture apagado: solo se registran los eventos instrumentados
        // a mano (ver capability `product-analytics`), sin lifecycle events
        // ni rage-clicks automáticos.
        ..captureApplicationLifecycleEvents = false
        ..rageClickConfig = (PostHogRageClickConfig()..enabled = false)
        ..personProfiles = PostHogPersonProfiles.identifiedOnly,
    );
    _environment = isProd ? 'production' : 'development';
    await Posthog().register('environment', _environment!);
  }

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
  void captureMessage(String message, {TelemetryLevel level = TelemetryLevel.info}) {
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
    unawaited(
      Posthog().capture(
        eventName: name,
        properties: _withoutNullValues(properties),
      ),
    );
  }

  @override
  void setUserId(String? userId) {
    Sentry.configureScope((scope) {
      scope.setUser(userId == null ? null : SentryUser(id: userId));
    });
    if (userId == null) {
      unawaited(
        Posthog().reset().then((_) {
          final environment = _environment;
          if (environment != null) {
            unawaited(Posthog().register('environment', environment));
          }
        }),
      );
    } else {
      unawaited(Posthog().identify(userId: userId));
    }
  }

  /// El cliente de PostHog no acepta valores `null` en propiedades; el
  /// contrato de `TelemetryClient.trackEvent` sí los permite para no atar la
  /// interfaz a esa restricción de un proveedor concreto.
  Map<String, Object>? _withoutNullValues(Map<String, Object?>? properties) {
    if (properties == null) return null;
    final result = <String, Object>{};
    for (final entry in properties.entries) {
      final value = entry.value;
      if (value != null) result[entry.key] = value;
    }
    return result;
  }

  SentryLevel _toSentryLevel(TelemetryLevel level) {
    switch (level) {
      case TelemetryLevel.debug:
        return SentryLevel.debug;
      case TelemetryLevel.info:
        return SentryLevel.info;
      case TelemetryLevel.warning:
        return SentryLevel.warning;
      case TelemetryLevel.error:
        return SentryLevel.error;
      case TelemetryLevel.fatal:
        return SentryLevel.fatal;
    }
  }
}
