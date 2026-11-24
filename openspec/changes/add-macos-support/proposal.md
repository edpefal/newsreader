## Why

Reevo es una app de lectura de newsletters y RSS que se usa mucho en sesiones largas, y esas sesiones ocurren a menudo frente a una Mac. El layout adaptativo de `optimize-ipad-ux` (rail permanente y master-detail desde 840dp) ya cubre ventanas anchas, y la migración a RevenueCat (`migrate-to-revenuecat`, publicada en la 1.11.0) eliminó el último bloqueo: Superwall no tenía SDK para macOS y `purchases_flutter` sí. Con una compra universal, quien ya paga en iPhone o iPad tiene Reevo en Mac sin pagar otra vez.

## What Changes

- Agregar la plataforma macOS al proyecto Flutter (carpeta `macos/`), con el mismo bundle ID que iOS (`com.artlab.reevo`) para que la compra sea universal. Binario universal (Intel + Apple Silicon), distribuido por la Mac App Store.
- Habilitar el App Sandbox con los entitlements que la app necesita: red de salida, lectura/escritura de archivos elegidos por el usuario (importar OPML, exportar datos), Sign in with Apple y grupo de llavero para Google Sign-In.
- Login con Google y con Apple en macOS, reusando el cliente OAuth nativo de iOS (mismo bundle ID).
- Compras y paywall en macOS: la llave pública de RevenueCat se resuelve también para macOS, y el paywall propio sigue abriéndose como diálogo (la ventana de Mac siempre supera 840dp salvo que el usuario la achique).
- UX de escritorio nivel 1 y 2: tamaño mínimo de ventana, barra de menús nativa con atajos (`⌘R` sincronizar, `⌘F` buscar, `⌘,` Ajustes), navegación por teclado en las listas y estados de hover/cursor en los elementos clicables.
- Workflow `macos-testflight` en Codemagic (disparo manual, elegible desde el workflow de GitHub `codemagic-trigger.yml`) que compila, firma con perfiles de Mac App Store y sube el build a TestFlight de macOS.
- Registrar la propiedad `platform` (`ios`, `macos`, `android`) en PostHog para separar el uso por plataforma.
- Sin pantalla de arranque nativa en macOS: `flutter_native_splash` no genera nada para macOS, y sus llamadas `preserve`/`remove` son Dart puro, así que el código de `main.dart` se queda como está.
- Fuera de alcance, en un change posterior: menú contextual con clic derecho, recordar tamaño y posición de la ventana, arrastrar un OPML a la ventana, notificaciones. Build de macOS en el CI de GitHub tampoco entra: `ci.yml` sigue en Linux con `analyze` + `test`.

## Capabilities

### New Capabilities

- `macos-app-support`: la app corre en macOS como app de escritorio nativa: sandbox, login, ventana con tamaño mínimo, barra de menús con atajos, navegación por teclado y hover.
- `macos-testflight-deploy`: camino repetible y manual para compilar, firmar y subir un build de macOS a TestFlight, equivalente al de iOS.

### Modified Capabilities

- `subscription-paywall`: se agrega el requirement de compras en macOS (el provider configura el SDK con la llave de Apple y el paywall ofrece comprar), junto al existente "Sin compras en Android", que no cambia.
- `product-analytics`: los eventos de producto y de pantalla incluyen la plataforma en la que ocurren.
- `codemagic-manual-trigger`: el disparo manual acepta qué workflow lanzar (`ios-testflight` por defecto, o `macos-testflight`).

## Impact

- **Nuevo**: `macos/` (proyecto Xcode, `Podfile`, `Runner/*.entitlements`, `Info.plist`, `MainFlutterWindow.swift` con el tamaño mínimo) y un workflow `macos-testflight` en `codemagic.yaml` y un input `workflow` en `.github/workflows/codemagic-trigger.yml`.
- **Código Dart**: `lib/core/config/app_config.dart` (llave de RevenueCat por plataforma), `lib/core/observability/default_telemetry_client.dart` (super property `platform`), `lib/presentation/app/` (barra de menús y atajos), y las pantallas de lista (foco y hover). Ningún feature importa de otro.
- **Dependencias**: ninguna nueva; todos los plugins nativos en uso ya declaran macOS (`webview_flutter`, `google_sign_in`, `sign_in_with_apple`, `purchases_flutter`, `sentry_flutter`, `posthog_flutter`, `file_picker`, `share_plus`, `url_launcher`). El tamaño mínimo de ventana va en Swift nativo, sin `window_manager`.
- **Servicios externos** (pasos manuales del usuario): agregar la plataforma macOS a la app existente en App Store Connect, capturas y metadatos de Mac, certificados y perfiles de Mac App Store, y confirmar en RevenueCat que el producto de suscripción cubre macOS. No hay cambios en Supabase ni en Edge Functions: `entitlements` y los webhooks ya son independientes de la plataforma.
- **Relación con otros changes**: independiente de `retire-superwall` (los avisos de Apple de las compras en Mac llegan a la misma URL de RevenueCat) y de `migrate-to-material-ui-packages` (el workflow de macOS fija Flutter 3.44.6, igual que `ci.yml`).
