import 'package:flutter/material.dart';

/// Resuelve el dato necesario para una pantalla de detalle a partir de
/// `state.extra` de go_router cuando está disponible (camino rápido, sin
/// loading), o de forma asíncrona vía [resolve] cuando no lo está -- por
/// ejemplo, si el proceso fue recreado y la navegación se restauró sin el
/// objeto en memoria. Si [resolve] no encuentra nada, llama [onNotFound] en
/// vez de mostrar una pantalla vacía o crashear.
class RouteExtraResolver<T> extends StatelessWidget {
  final Object? extra;
  final Future<T?> Function() resolve;
  final Widget Function(BuildContext context, T value) builder;
  final void Function(BuildContext context) onNotFound;

  const RouteExtraResolver({
    super.key,
    required this.extra,
    required this.resolve,
    required this.builder,
    required this.onNotFound,
  });

  @override
  Widget build(BuildContext context) {
    final value = extra;
    if (value is T) return builder(context, value);

    return FutureBuilder<T?>(
      future: resolve(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final resolved = snapshot.data;
        if (resolved == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) onNotFound(context);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return builder(context, resolved);
      },
    );
  }
}
