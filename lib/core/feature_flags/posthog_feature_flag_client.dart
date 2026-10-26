import 'dart:async';

import 'package:posthog_flutter/posthog_flutter.dart';

import 'package:newsreader/core/feature_flags/feature_flag_client.dart';

/// [FeatureFlagClient] respaldado por el SDK de PostHog, que ya persiste en
/// disco el último valor recibido de cada flag.
///
/// El SDK de Flutter solo permite fijar el callback de "flags cargados" al
/// configurarlo (`DefaultTelemetryClient.initPostHog`), no suscribirse en
/// runtime: por eso [notifyChanged] es público y lo conecta `main.dart`, pero
/// no forma parte de la interfaz [FeatureFlagClient].
class PostHogFeatureFlagClient implements FeatureFlagClient {
  final Future<Object?> Function(String key) _readFlag;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// [readFlag] existe para poder probar la clase sin el SDK.
  PostHogFeatureFlagClient({Future<Object?> Function(String key)? readFlag})
    : _readFlag = readFlag ?? ((key) => Posthog().getFeatureFlag(key));

  @override
  Future<bool> isEnabled(String key) async {
    try {
      return await _readFlag(key) == true;
    } catch (_) {
      // Un flag no se resuelve => apagado (ver capability `feature-flags`).
      return false;
    }
  }

  @override
  Stream<void> get changes => _changes.stream;

  /// Avisa a los suscriptores de [changes] que los flags se (re)cargaron.
  void notifyChanged() {
    if (!_changes.isClosed) _changes.add(null);
  }
}
