## Context

Ver `proposal.md` (Why) para la motivación. Estado actual relevante:

- `posthog_flutter ^5.38.1` ya se inicializa en `main.dart` (`DefaultTelemetryClient.initPostHog`) antes de `runApp`, con un solo proyecto de PostHog compartido entre dev y prod. El entorno hoy solo viaja como super property (`register('environment', ...)`), que afecta a los eventos pero **no** a la evaluación de flags.
- `TelemetryClient` es solo telemetría (Sentry + PostHog para eventos). No expone flags.
- El SDK de Flutter fija el callback `onFeatureFlags` en `PostHogConfig` (al configurar), no como suscripción en runtime, y `getFeatureFlag`/`getFeatureFlagResult` son asíncronos. `setPersonPropertiesForFlags` existe desde 5.28 y por defecto recarga los flags al terminar.
- `LoginOptionsView` dibuja siempre Google, Apple, el separador y `TextButton` de correo. `LoginCubit` (factory en `injection.dart`, provisto en `router.dart`) tiene un `sealed class LoginState`; la vista inicial se muestra para `LoginIdle`, `LoginInProgress` y `LoginError`.
- Regla de arquitectura: ninguna librería de infraestructura se importa en `domain/` o `presentation/`; `get_it` solo en `injection.dart`.

## Goals / Non-Goals

**Goals:**
- Una abstracción reutilizable de feature flags en `core/`, de modo que el siguiente flag no requiera tocar el SDK.
- Que la opción de correo del login dependa de `email-login`, con falla segura (oculto).
- Que ningún flujo de correo en curso se interrumpa por un cambio de flag.

**Non-Goals:**
- Experimentos A/B, variantes multivariante o payloads: solo flags booleanos.
- Un flag distinto para cada método de login, o gating de Google/Apple.
- Ocultar el correo en clientes ya publicados (`<= 1.10.0+11`); no es posible desde el servidor.
- Bloquear el login en el servidor cuando el flag está apagado (un cliente viejo o un script que llame a Supabase Auth directo no pasa por el flag; ver Riesgos).

## Decisions

### 1. `FeatureFlagClient` en `core/feature_flags/`, separado de `TelemetryClient`
Interfaz con `Future<bool> isEnabled(String key)` y `Stream<void> get changes`, más una implementación `PostHogFeatureFlagClient`. Una constante `FeatureFlagKeys.emailLogin = 'email-login'` evita strings sueltos.

- **Por qué separado:** `TelemetryClient` está documentado como telemetría (errores y eventos) y su fake lo usan muchos tests; mezclar flags lo infla y lo acopla a un concern distinto.
- **Alternativa descartada:** agregar `isFeatureEnabled` a `TelemetryClient`. Más corto, pero rompe la separación y obliga a actualizar todos los mocks existentes.

### 2. Puente del callback `onFeatureFlags` a un `Stream`
El callback del SDK se fija en `initPostHog`. La implementación mantiene un `StreamController<void>.broadcast()` y `initPostHog` recibe un `VoidCallback` (o el cliente se construye antes y le pasa su `notifyChanged`) que lo dispara. La UI se suscribe al stream; el callback del SDK no se expone fuera de `core/`.

- **Alternativa descartada:** polling periódico de `getFeatureFlag`. Gasta CPU sin necesidad y el SDK ya avisa cuando carga.

### 3. Falla segura en la propia abstracción
`isEnabled` devuelve `false` ante `null`, valor no booleano, excepción o flag inexistente. El default "apagado" vive en un solo lugar, no repartido por los consumidores.

### 4. Entorno como propiedad de persona para flags
Dentro de `initPostHog` se apaga `preloadFeatureFlags` y se llama `setPersonPropertiesForFlags({'environment': 'development' | 'production'})` (que recarga los flags), de modo que la única petición de flags del arranque ya lleve el entorno. `main.dart` solo conecta `onFeatureFlags` con `PostHogFeatureFlagClient.notifyChanged`. En el panel de PostHog el flag `email-login` se condiciona por `environment`.

- **Por qué no la super property:** `register` solo adjunta propiedades a eventos; no entra en la evaluación de flags.
- **Alternativa descartada:** una clave de flag por entorno (`email-login-dev`/`-prod`). Duplica el flag y deja que el código de prod referencie un flag de dev.
- **Alternativa descartada:** un segundo proyecto de PostHog. El plan free solo permite uno (ver nota en `AppConfig`).

### 5. Estado de disponibilidad en un cubit aparte, no en `LoginState`
Un `EmailLoginAvailabilityCubit` (estado `bool`, `Equatable`) lee `isEnabled` al crearse y vuelve a leerlo cada vez que emite `changes`. `LoginScreen` lo provee junto a `LoginCubit` y `LoginOptionsView` lo consume con `BlocBuilder`.

- **Por qué:** `LoginOptionsView` se dibuja para tres estados distintos de `LoginState`; poner el flag dentro de cada variante duplicaría el campo y mezclaría un valor externo con el flujo de autenticación. Con un cubit separado, el flujo de correo en curso (`LoginEmailEntry`, `LoginCodeSent`) ni siquiera lo lee, y por eso un cambio de flag no lo interrumpe.
- **Alternativa descartada:** inyectar `FeatureFlagClient` en `LoginCubit` y añadir un campo a `LoginIdle`/`LoginInProgress`/`LoginError`. Funciona pero ensancha un cubit que ya maneja el temporizador de reenvío y la telemetría.

### 6. Sin bloqueo de arranque
`main.dart` no hace `await` de la carga de flags antes de `runApp`. Solo se espera el `setup` de PostHog que ya se espera hoy. La vista inicial se renderiza con el último valor guardado (o apagado) y se actualiza cuando llegan los flags.

## Risks / Trade-offs

- **El flag oculta la opción, no la protege** → un cliente viejo (`<= 1.10.0+11`) o una llamada directa a Supabase Auth con la anon key sigue pudiendo pedir códigos. La protección real contra abuso sigue siendo el tope de Supabase/Resend y la alerta de Sentry; el flag reduce la exposición, no la cierra. Se documenta para no sobreestimarlo.
- **Salto de layout en el primer arranque** (el botón aparece cuando llegan los flags) → aceptado: ocurre una vez por instalación y el botón es secundario.
- **Lectura asíncrona del valor guardado** → hay una ventana de milisegundos en que el botón no aparece aunque el valor persistido sea `true`. Se acepta; es la misma falla segura.
- **Un solo proyecto de PostHog para dev y prod** → un flag mal condicionado por `environment` se activaría en ambos. Mitigación: tarea explícita de verificar en el panel que la condición `environment` existe antes de subir el porcentaje en prod.
- **Porcentaje por dispositivo, no por persona** → el id anónimo cambia al reinstalar, así que un mismo usuario puede ver el botón y luego no. Aceptable para un flag de rollout de una opción secundaria.
- **Costo de requests** → una evaluación por arranque y otra por `setPersonPropertiesForFlags`, muy por debajo del 1M mensual.

## Migration Plan

1. Implementar y mergear el cambio con el flag **sin crear** en PostHog: la opción de correo queda oculta en las builds nuevas (falla segura).
2. Crear `email-login` en PostHog con la condición `environment = development` al 100 % y verificar en una build de dev que aparece y desaparece al conmutar.
3. Publicar la versión a producción con el flag aún apagado para prod.
4. Subir el flag en prod a 10 % → 50 % → 100 %, revisando entre pasos la alerta de Sentry `login_email_rate_limited`.

**Rollback:** apagar el flag en el panel (efecto en la siguiente carga de flags de cada dispositivo). No hay cambios de servidor que revertir.
