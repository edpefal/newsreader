## Context

`SettingsScreen` (`lib/features/settings/presentation/screens/settings_screen.dart`) es un `StatefulWidget` que hoy recibe `exportUserData`, `deleteAccount`, `clearLocalUserData` y `authClient` por constructor, y renderiza sus secciones (tema, cuenta) directo en `build()`. No usa Bloc/Cubit propio.

`SubscriptionStatusProvider` (`core/subscription/subscription_status_provider.dart`) ya expone `bool get isSubscribed` (cacheado localmente por el SDK de Superwall) y `Future<void> showPaywall({required Future<void> Function() onSubscribed})`. Ya se inyecta por constructor en `ReaderScreen`, `SummariesCubit` y `ArticleSummaryBottomSheet`, siguiendo el mismo patrón que se va a reusar acá. Ver proposal.md - Why.

## Goals / Non-Goals

**Goals:**
- Mostrar el estado Free/Premium como primera sección de Ajustes, leyendo `isSubscribed` sin agregar estado nuevo a la interfaz `SubscriptionStatusProvider`.
- Reusar el placement `daily_summary` ya configurado en Superwall para el botón de upgrade (decisión ya tomada en exploración previa — no se crea placement nuevo).
- Que la sección se actualice sola tras una compra completada desde Ajustes, sin salir de la pantalla.

**Non-Goals:**
- No se agrega un stream/getter nuevo a `SubscriptionStatusProvider` para reactividad en vivo ante cambios externos (ej. cancelación desde fuera de la app mientras Ajustes está abierto) — fuera de alcance, cubierto por el próximo `build()` al reingresar a la pantalla.
- No se muestra un estado de "cargando" mientras el stream de Superwall entrega su primer valor — se acepta mostrar "Free" por defecto en ese instante (ver Decisiones).
- No cambia nada del backend, de `entitlements`, ni de la tabla de Supabase (`subscription-entitlements` no se toca).

## Decisions

- **Reusar `SubscriptionStatusProvider.isSubscribed` como única fuente de verdad**, igual que en `ReaderScreen`/`SummariesCubit`. Alternativa descartada: consultar `entitlements` en Supabase desde Ajustes — más lento, y `subscription-entitlements` ya documenta que ese chequeo server-side es para otros flujos (ej. `daily-summaries`), no para reflejar UI instantánea.
- **`SettingsScreen` pasa a recibir `SubscriptionStatusProvider` por constructor** (mismo patrón que las otras pantallas) y su punto de instanciación (router) le pasa la instancia ya registrada en `core/di/injection.dart`. No se crea un provider nuevo.
- **Reactividad vía `setState` local, no un stream nuevo**: `SettingsScreen` ya es `StatefulWidget`. El botón de upgrade llama `showPaywall(onSubscribed: () => setState(() {}))` — tras completar la compra, `onSubscribed` corre y el siguiente `build()` lee `isSubscribed` ya actualizado. Alternativa descartada: exponer `Stream<bool>` en la interfaz — más superficie de cambio para un caso que ya se resuelve con el callback existente.
- **Reusar el placement `daily_summary`** en vez de crear uno nuevo en el dashboard de Superwall — decisión ya tomada en la fase de exploración para mantener el scope chico; el copy remoto del paywall no cambia por venir desde Ajustes en vez del flujo de resumen.
- **Estado inicial "Free" por defecto** mientras el stream interno de `SuperwallSubscriptionStatusProvider` no entregó su primer valor — mismo comportamiento que ya tienen `ReaderScreen`/`SummariesCubit` hoy (todos leen el mismo `isSubscribed` que arranca en `false`), así que no se introduce ninguna inconsistencia nueva.

## Risks / Trade-offs

- [Un usuario Premium que abre Ajustes justo después de un arranque en frío puede ver "Free" por una fracción de segundo hasta que el stream de Superwall emita] → Aceptado: mismo comportamiento que ya existe en el resto de la app; no se agrega un estado de carga para un caso borde de milisegundos.
- [Reusar el placement `daily_summary` mezcla en las analíticas de Superwall los taps de "quiero ser Premium desde Ajustes" con los gates reales del flujo de resumen diario] → Aceptado explícitamente en la exploración previa; si en el futuro hace falta separar esas métricas, se puede crear un placement dedicado sin tocar el resto de este diseño.
