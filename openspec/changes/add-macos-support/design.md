## Context

Estado verificado al abrir el change (2026-11-24, `main` en `1aa78c8`, versión `1.11.0+12`):

- No existe `macos/`. iOS usa el bundle ID `com.artlab.reevo` (iOS mínimo 14.0) y Sign in with Apple como único entitlement.
- Todos los plugins nativos en uso declaran macOS en las versiones del lock: `webview_flutter` 4.13.1, `google_sign_in` 6.3.0 (`google_sign_in_ios` 5.9.0), `sign_in_with_apple` 6.1.4, `sentry_flutter` 8.14.2, `posthog_flutter` 5.56.2, `file_picker` 8.3.7, `share_plus` 10.1.4, `url_launcher` 6.3.2 y `purchases_flutter` 10.19.0. `cached_network_image` y `flutter_widget_from_html_core` son Dart puro. Solo `flutter_native_splash` no declara macOS, y `preserve`/`remove` no usan el canal nativo (son `deferFirstFrame`/`allowFirstFrame`).
- Los mínimos de macOS que declaran los podspecs son 10.13 (Sentry), 10.14 (webview, share_plus), 10.15 (PostHog, Google Sign-In). `purchases_flutter` no lo declara en su podspec y depende de `PurchasesHybridCommon 19.17.0`.
- La única condición de plataforma en `lib/` es `AppConfig.revenueCatApiKey`, que devuelve la llave solo si `Platform.isIOS`. El layout adaptativo (`AdaptiveShell`, rail y master-detail desde 840dp) ya existe y es el que usará la ventana de Mac.
- La búsqueda y el estado "buscando" viven en `AdaptiveShell` (`_isSearching`, `_toggleSearch`, solo en las tabs 0–3). La sincronización manual del Inbox vive en `_onRefresh` de `inbox_screen.dart`, con sus SnackBars de error.
- Codemagic tiene un solo workflow (`ios-testflight`, `flutter: stable`); `ci.yml` fija Flutter 3.44.6 y corre `analyze` + `test` en Linux. `codemagic-trigger.yml` lanza un workflow fijo.

Motivación y alcance: ver `proposal.md`. Comportamiento exigido: ver `specs/`.

## Goals / Non-Goals

**Goals:**

- Que la misma base de código produzca una app de Mac que se sienta de Mac sin bifurcar features ni capas.
- Que ninguna decisión de este change obligue a tocar el servidor (Supabase, Edge Functions, webhooks).
- Que cualquier condición de plataforma quede en un solo lugar, testeable sin `dart:io`.

**Non-Goals:**

- Cambios de diseño visual: la UI es la misma, solo se adapta a mouse y teclado.
- Menú contextual, recordar ventana, arrastrar OPML, notificaciones, widgets de escritorio: change posterior.
- Build de macOS en GitHub Actions.
- Suscripciones web o Mac fuera de la Mac App Store (Developer ID).

## Decisions

### D1. Mismo bundle ID, misma ficha: compra universal

macOS se agrega como plataforma de la app existente en App Store Connect con el bundle ID `com.artlab.reevo`. Así el producto de suscripción y el entitlement `pro` se comparten con iOS, y el cliente OAuth nativo de Google y la configuración de Sign in with Apple siguen siendo válidos.

*Alternativa descartada:* una app de Mac con otro bundle ID y compra separada. Obliga a vender dos veces, a duplicar la configuración de Google y de Apple, y a decidir cómo unir entitlements entre dos productos.

### D2. Mínimo de macOS: 10.15, subible solo si un plugin lo exige

Se fija `MACOSX_DEPLOYMENT_TARGET = 10.15` en el `Podfile` y en el proyecto Xcode: es el mayor mínimo que declaran los plugins verificados (PostHog y Google Sign-In). `purchases_flutter` no lo declara, así que la primera tarea de implementación corre `pod install`; si CocoaPods rechaza el pod, se sube al valor que pida `PurchasesHybridCommon 19.17.0` y se documenta aquí. No se fija un mínimo más alto "por si acaso": cada versión que se excluye son usuarios que no pueden instalar.

### D3. Sandbox y entitlements

`Release.entitlements` y `DebugProfile.entitlements` declaran: `com.apple.security.app-sandbox`, `com.apple.security.network.client`, `com.apple.security.files.user-selected.read-write` (importar OPML y exportar), `com.apple.developer.applesignin` y `keychain-access-groups` con `$(AppIdentifierPrefix)com.artlab.reevo` (Google Sign-In guarda su sesión en el llavero y falla dentro del sandbox sin ese grupo). `DebugProfile` conserva además lo que trae la plantilla de Flutter para depurar (`network.server`, JIT). StoreKit no necesita entitlement.

Hive, `path_provider` y los temporales de `share_plus` escriben dentro del contenedor del sandbox sin permisos extra.

### D4. Login: reutilizar el cliente iOS de Google

Google Cloud no tiene un tipo de cliente macOS: las apps de Mac usan el cliente tipo iOS, que se valida contra el bundle ID. Como el bundle ID es el mismo (D1), `macos/Runner/Info.plist` lleva el mismo `GIDClientID` y el mismo esquema URL invertido que `ios/Runner/Info.plist`, y `SupabaseAuthClient` no cambia (el `serverClientId` web es común). Apple devuelve el mismo correo (o el mismo relay "Ocultar mi correo", que es por app y equipo, no por plataforma) en iOS y macOS.

*Verificación que condiciona el cierre* (tareas 5.x): que Supabase vincule por correo verificado la identidad de Google/Apple con la cuenta existente, y no cree una cuenta nueva. Si no lo hiciera, el requirement "Misma cuenta desde iOS y macOS" fallaría y habría que decidir un ajuste en Supabase Auth antes de publicar.

### D5. Una sola condición de plataforma, basada en `defaultTargetPlatform`

`AppConfig` deja de usar `Platform.isIOS` y expone `platformName` (`ios`, `macos`, `android`, derivado de `defaultTargetPlatform`) y `revenueCatApiKey` (la llave `appl_…` para `ios` y `macos`, `null` para el resto). `defaultTargetPlatform` se puede forzar en los tests con `debugDefaultTargetPlatformOverride`, y `dart:io` deja de ser necesario en `app_config.dart`. En RevenueCat una app "Apple App Store" cubre iOS y macOS con la misma llave pública, así que no hay llave nueva; se confirma en el panel (tarea 6.x).

`platformName` también alimenta la propiedad de PostHog (D9): una sola fuente.

### D6. Ventana: tamaño mínimo e inicial en Swift, sin plugin

`MainFlutterWindow.swift` fija `minSize` (480×640) y, si no hay un frame previo, un tamaño inicial de 1120×760 centrado. Son tres líneas nativas; agregar `window_manager` traería un paquete nuevo, su ciclo de mantenimiento y una API que sería tentador usar para el resto de cosas de ventana (recordar posición), que quedan fuera de alcance.

El mínimo de 480 deja que el usuario vea el layout compacto (drawer) si lo quiere; el inicial de 1120 arranca en rail + master-detail. El cruce de 840dp ya lo cubren `adaptive-navigation-rail` y `adaptive-master-detail`.

### D7. Barra de menús: `PlatformMenuBar` + comandos por stream

`PlatformMenuBar` (de Flutter, sin paquetes) se monta en el `builder` de `MaterialApp.router`, solo cuando `defaultTargetPlatform == macOS`, para tener `AppLocalizations` disponible. Menús: **Reevo** (Acerca de, Ajustes `⌘,`, Servicios, Ocultar, Ocultar otros, Mostrar todo, Salir), **Edición** (Deshacer, Rehacer, Cortar, Copiar, Pegar, Seleccionar todo), **Ver** (Sincronizar `⌘R`, Buscar `⌘F`, Pantalla completa), **Ventana** (Minimizar, Zoom, Traer todo al frente) y **Ayuda**. Los ítems estándar usan `PlatformProvidedMenuItem`; los de Edición invocan el `Intent` de texto correspondiente sobre el foco actual (`CopySelectionTextIntent`, `PasteTextIntent`, etc.), de modo que los campos de texto se comportan como en cualquier app de Mac.

Los ítems propios no conocen a las pantallas. Emiten un `DesktopCommand` (`sync`, `search`, `settings`) a un `DesktopCommands` (un `StreamController.broadcast` en `presentation/app/`) que se construye en `main.dart` y se pasa a `App` por constructor, igual que los cubits. `AdaptiveShell` se suscribe: `search` abre la búsqueda si la tab es buscable (reusa `_toggleSearch`; `autofocus: true` ya da el foco), `sync` llama a la misma función que el pull-to-refresh, `settings` navega con `AppNavigator`. Los ítems se deshabilitan cuando `AuthClient.isSignedIn` es falso (`App` ya observa `authStateChanges`).

Para que `⌘R` y el pull-to-refresh no diverjan, `_onRefresh` sale de `inbox_screen.dart` a una función pública del feature inbox (`refreshInbox(context)`), con sus SnackBars intactos; `AdaptiveShell` ya importa `InboxCubit`, así que no crea una dependencia nueva entre features.

*Alternativa descartada:* `Shortcuts`/`Actions` solo en Dart, sin barra de menús. Los atajos funcionarían, pero la app no tendría menú de Mac (sin "Salir", "Ocultar" ni Ajustes en el menú de la app), y App Review lo nota.

*Alternativa descartada:* editar `MainMenu.xib`. Es menos portable y no puede llamar a Dart sin un `MethodChannel` propio.

### D8. Teclado y hover: auditar, no reconstruir

Flutter en escritorio ya mapea las flechas a `DirectionalFocusIntent`, `Enter`/`Space` a `ActivateIntent` y `Esc` a `DismissIntent`; `InkWell` y `ListTile` son enfocables y usan el cursor de clic y un color de hover por defecto. Lo que cambia es una **auditoría**: las filas de artículo, fuente y resumen, los destinos del rail y las tarjetas deben construirse con `InkWell`/`ListTile` (o un `FocusableActionDetector` con `MouseRegion`), con color de foco y de hover visibles en claro y oscuro; cualquier `GestureDetector` pelado se reemplaza. `Esc` cierra el detalle del master-detail solo si no hay un diálogo encima.

El color de hover y de foco se define en `AppTheme` (`hoverColor`, `focusColor`), no por fila, y respeta la regla de `ReevoAccent`/beiges (no usar `surfaceContainerHighest` para esto).

### D9. Telemetría: super property `platform`

`DefaultTelemetryClient.initPostHog` registra `platform` junto a `environment`, con `AppConfig.platformName`. Una super property llega a todos los eventos y a `screen_view`, que es lo que pide el spec, sin tocar cada llamada. No hay PII: es una constante por dispositivo. PostHog ya trae `$os`, pero depender de él para segmentar deja la definición de "plataforma" en manos del SDK; una propiedad propia es explícita y estable entre versiones del SDK.

### D10. Sin splash en macOS

No se toca `main.dart`. `preserve` pospone el primer frame y `remove` lo libera, ambos Dart puro, así que corren igual en macOS. La configuración `flutter_native_splash` de `pubspec.yaml` solo genera assets de iOS y Android y no se amplía. En macOS la ventana aparece con el primer frame ya pintado.

### D11. Distribución: workflow propio en Codemagic

Un workflow `macos-testflight` en `codemagic.yaml` (`mac_mini_m2`, `flutter: 3.44.6`, `xcode: latest`), disparo manual (`triggering.events: []`):

1. `flutter pub get`.
2. Firma con la integración `reevo_asc_api_key`: `app-store-connect fetch-signing-files "$BUNDLE_ID" --platform MAC_OS --type MAC_APP_STORE --create` y lo mismo con el tipo de instalador, luego `keychain add-certificates` y `xcode-project use-profiles`.
3. Build number: último de TestFlight **de macOS**, más uno. La numeración es independiente de la de iOS.
4. `flutter build macos --release --dart-define=APP_ENV=prod --build-number=$N`. Los builds release de Flutter en macOS son universales por defecto.
5. Empaquetado: `productbuild` y `productsign` con el certificado de instalador, según la documentación de Codemagic para la Mac App Store.
6. Publicación a TestFlight con la integración de App Store Connect, sin enviar a revisión.

El workflow de GitHub `codemagic-trigger.yml` gana un input `workflow` (`choice`: `ios-testflight` por defecto, `macos-testflight`), validado antes de llamar a la API. Los flags exactos del CLI de Codemagic (`--platform MAC_OS`, filtro de build number por plataforma) se confirman en la primera corrida real: el diseño fija la intención, no la sintaxis.

*Fijar Flutter 3.44.6 solo en el workflow nuevo* evita que un Flutter más nuevo (que depreca `material.dart`, ver `migrate-to-material-ui-packages`) rompa el primer build de Mac sin relación con este change. El workflow de iOS no se toca.

### D12. Metadatos nativos y localización de menús

`macos/Runner/Info.plist` declara `CFBundleLocalizations` (`en`, `es`, `fr`) para que los ítems estándar del sistema (Acerca de, Ocultar, Salir) salgan en el idioma del usuario, `LSApplicationCategoryType = public.app-category.news` y `ITSAppUsesNonExemptEncryption = false`, igual que iOS. Las etiquetas de los menús propios van en los tres `.arb` en el mismo change, con tuteo y sin voseo (lo verifica `neutral_spanish_test.dart`).

### D13. Ícono de macOS

macOS no aplica máscara automática: el ícono debe venir ya redondeado y con margen sobre el lienzo de 1024. Se genera un `AppIcon.appiconset` de macOS (16 a 1024) desde el maestro óxido `#C1401F`, con la plantilla de Apple; no se reutiliza el cuadrado de iOS.

## Risks / Trade-offs

- **Google Sign-In falla dentro del sandbox** (llavero, URL de retorno) → el grupo de llavero está en D3; se prueba el login en un build firmado con sandbox real, no solo en `flutter run`. Si el cliente iOS fuera rechazado en macOS, se evalúa un flujo web con `signInWithOAuth` antes de publicar.
- **Vinculación de cuentas por correo en Supabase** (D4) → verificación explícita con un usuario de prueba creado en iOS; sin ella el requirement de "misma cuenta" no se da por cumplido.
- **Pruebas solo en Apple Silicon** → el binario universal incluye Intel, pero el usuario puede no tener una Mac Intel; se compila y se arranca bajo Rosetta como mínimo y se deja constancia de lo que no se pudo probar en hardware Intel.
- **Prueba de compras en macOS** → exige una cuenta sandbox en la Mac y la suscripción visible en el sandbox de macOS; ver `feedback-sandbox-subscription-identity-apple-id`: la identidad queda atada al Apple ID.
- **Menú de Edición propio** → `PlatformMenuBar` reemplaza el menú completo; si un ítem de Edición no resuelve el `Intent`, `⌘C`/`⌘V` seguirían funcionando por los atajos de texto de Flutter, pero el menú quedaría gris. Se prueba con un `TextField` y con texto seleccionable del lector.
- **Anclaje del panel de compartir**: `SharePlusFileSharer` pasa `Rect.fromLTWH(0, 0, 1, 1)`, que en macOS ancla el popover en la esquina de la ventana, correcto pero poco pulido → se acepta en esta versión; anclarlo al botón exigiría cambiar la interfaz `FileSharer`, que hoy no recibe contexto.
- **Revisión de la Mac App Store**: restaurar compras visible, Sign in with Apple junto a Google (ya cumplido en iOS), y capturas de Mac reales → son los puntos que suelen rechazarse; la ficha se prepara con el CLI de App Store Connect como en iOS.
- **`material.dart` deprecado en Flutter 3.47** → el workflow de Mac fija 3.44.6 y no depende de ese change.

## Migration Plan

1. Rama `add-macos-support`; implementar y verificar en local (`flutter analyze`, `flutter test`, `flutter build macos`), luego PR con CI en verde.
2. Tras el merge, agregar la plataforma macOS a la ficha en App Store Connect (paso manual del usuario, con el CLI donde se pueda) y subir el primer build por el workflow `macos-testflight` a TestFlight interno.
3. El usuario prueba en la Mac: login con Google y Apple, compra y restauración con cuenta sandbox, importar y exportar, menús y atajos, redimensionar a través de 840dp.
4. Enviar a revisión de la Mac App Store con capturas y descripción de Mac.

No hay cambios de servidor, de esquema ni de Edge Functions, así que no aplica el orden de despliegue servidor/clientes de `CLAUDE.md`. **Rollback:** la app de Mac es una plataforma nueva sin usuarios previos; si hay un problema se retira la versión de macOS de la ficha sin afectar a iOS, y el código nuevo no cambia el comportamiento de iOS (solo `AppConfig.platformName`, la super property y la barra de menús, que se monta únicamente en macOS).

## Open Questions

- Textos y capturas de la ficha de Mac (descripción, palabras clave, capturas): se preparan al enviar a revisión, no condicionan el código.
- Si más adelante conviene un ítem "Importar OPML…" en un menú Archivo: queda para el change de UX de escritorio nivel 3.
