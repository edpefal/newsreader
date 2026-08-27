## Context

`SummariesCubit.generateTodaySummary` (`lib/features/summaries/presentation/cubit/summaries_cubit.dart`) delega en `SubscriptionStatusProvider.showPaywall({onSubscribed})`, implementado por `SuperwallSubscriptionStatusProvider.showPaywall` (`lib/core/subscription/superwall_subscription_status_provider.dart`) como:

```dart
Superwall.shared.registerPlacement(_dailySummaryPlacement, feature: onSubscribed);
```

Por diseño del SDK de Superwall, `feature` corre si el usuario ya tenía acceso, o si completa la compra desde el paywall mostrado. El bug reportado ocurría porque el paywall `255848` tenía configurado `feature_gating: "non_gated"` en el dashboard de Superwall (corregido a `"gated"` fuera de este change, vía API, como fix inmediato de causa raíz) — con esa config, `feature` se ejecuta siempre que se muestra el paywall, sin importar si el usuario compra o lo cierra.

El backend (`supabase/functions/summarize-articles`, ver `entitlement.ts`) ya valida la suscripción de forma independiente y rechaza solicitudes sin entitlement activo, así que el bug nunca permitió generar un resumen gratis — pero sí disparaba una solicitud innecesaria al backend y una mala UX (pantalla de error apareciendo justo al cerrar el paywall).

## Goals / Non-Goals

**Goals:**
- Que el código de la app nunca dispare la generación del resumen tras un `showPaywall` a menos que la suscripción esté efectivamente activa en ese momento, sin depender de que la configuración remota de Superwall esté correcta.

**Non-Goals:**
- No cambia el backend (`summarize-articles`), que ya está correctamente gateado.
- No cambia la configuración de Superwall en sí (ya corregida directamente vía API como parte de este trabajo, pero fuera del alcance de las tasks de código).
- No agrega un mecanismo de retry ni de reintento automático si la verificación falla.

## Decisions

### Re-verificar `isSubscribed` dentro del callback `onSubscribed`, no cambiar la interfaz de `SubscriptionStatusProvider`
`SummariesCubit.generateTodaySummary` ya recibe `onSubscribed` como el callback que `showPaywall` invoca. La forma más simple y menos invasiva de blindar esto es que ese mismo callback, antes de llamar a `_generate`, vuelva a chequear `_subscriptionStatusProvider.isSubscribed` y no haga nada si sigue siendo `false`:

```dart
Future<void> generateTodaySummary(String language) async {
  if (!_subscriptionStatusProvider.isSubscribed) {
    await _subscriptionStatusProvider.showPaywall(
      onSubscribed: () async {
        if (!_subscriptionStatusProvider.isSubscribed) return;
        await _generate(language);
      },
    );
    return;
  }
  await _generate(language);
}
```

Alternativa descartada: cambiar la interfaz `SubscriptionStatusProvider.showPaywall` para que devuelva explícitamente si la compra se completó (en vez de un callback "feature"). Se descarta porque no es necesario tocar la abstracción ni la implementación de Superwall para resolver esto -- el chequeo adicional es suficiente y más simple, y mantiene el mismo contrato ya usado en el resto de la app.

### No depender de eventos/streams de Superwall para detectar "paywall cerrado sin comprar"
Se consideró escuchar `Superwall.shared.subscriptionStatus` o los eventos de presentación del paywall para distinguir "cerrado sin comprar" de "compra completada" de forma explícita. Se descarta: `isSubscribed` ya es exactamente ese estado (cacheado por el SDK, actualizado por el mismo stream que ya escucha `SuperwallSubscriptionStatusProvider`), así que consultarlo de nuevo alcanza sin agregar más superficie de listeners.

## Risks / Trade-offs

- [Riesgo] `isSubscribed` es un estado cacheado localmente por el SDK de Superwall (`SubscriptionStatus` stream); si tarda en actualizarse tras una compra recién completada, el re-chequeo podría fallar falsos negativos (compra real, pero `isSubscribed` todavía en `false`) y no generar cuando sí debería. → Mitigación: el flujo normal de Superwall ya actualiza `subscriptionStatus` como parte de completar la compra antes de invocar `feature`/`onSubscribed`, así que en la práctica el estado ya está actualizado en ese punto; este era además el mismo estado que ya se usaba para decidir si mostrar el paywall en primer lugar.

## Migration Plan

Cambio de comportamiento puramente en memoria, sin migración de datos. Se despliega como cualquier otro cambio de la app.
