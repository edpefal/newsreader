import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/feature_flags/feature_flag_client.dart';
import 'package:newsreader/core/feature_flags/feature_flag_keys.dart';

/// Si el login ofrece el acceso con correo: `true` solo cuando el flag
/// `email-login` está activo (ver capability `feature-flags`). Arranca en
/// `false` -- oculto por defecto -- y se actualiza sin bloquear la pantalla
/// cuando el flag se lee o cambia.
///
/// Vive aparte de `LoginCubit` a propósito: solo decide si se *ofrece* la
/// entrada al flujo. Un flujo de correo ya iniciado no lo consulta, así que
/// apagar el flag a mitad no lo interrumpe.
class EmailLoginAvailabilityCubit extends Cubit<bool> {
  final FeatureFlagClient _featureFlags;
  late final StreamSubscription<void> _subscription;

  EmailLoginAvailabilityCubit(this._featureFlags) : super(false) {
    _subscription = _featureFlags.changes.listen((_) => _refresh());
    _refresh();
  }

  Future<void> _refresh() async {
    final enabled = await _featureFlags.isEnabled(FeatureFlagKeys.emailLogin);
    if (!isClosed && enabled != state) emit(enabled);
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
