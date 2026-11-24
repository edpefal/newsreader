## 1. Plataforma macOS y configuración nativa

- [ ] 1.1 Crear la carpeta `macos/` con `flutter create --platforms=macos .` y revisar `git status` para confirmar que no toca `ios/`, `android/` ni `lib/`
- [ ] 1.2 Fijar `MACOSX_DEPLOYMENT_TARGET = 10.15` en `macos/Podfile` y en `macos/Runner.xcodeproj`; correr `pod install` y, si `purchases_flutter` (`PurchasesHybridCommon 19.17.0`) exige más, subirlo al mínimo requerido y anotarlo en `design.md` (D2)
- [ ] 1.3 Fijar el bundle ID `com.artlab.reevo` y el equipo de desarrollo en el proyecto de macOS, y la misma versión y build number que `pubspec.yaml`
- [ ] 1.4 Declarar en `DebugProfile.entitlements` y `Release.entitlements`: `app-sandbox`, `network.client`, `files.user-selected.read-write`, `com.apple.developer.applesignin` y `keychain-access-groups` con `$(AppIdentifierPrefix)com.artlab.reevo` (más lo de depuración de la plantilla solo en `DebugProfile`)
- [ ] 1.5 Completar `macos/Runner/Info.plist`: `CFBundleDisplayName` Reevo, `CFBundleLocalizations` (`en`, `es`, `fr`), `LSApplicationCategoryType` `public.app-category.news`, `ITSAppUsesNonExemptEncryption` en `false`, `GIDClientID` y el esquema URL invertido de Google (los mismos valores que `ios/Runner/Info.plist`)
- [ ] 1.6 En `MainFlutterWindow.swift`: `minSize` 480×640 y tamaño inicial 1120×760 centrado cuando no hay frame previo
- [ ] 1.7 Generar el `AppIcon.appiconset` de macOS (16 a 1024) desde el maestro óxido `#C1401F`, ya redondeado y con margen según la plantilla de Apple (D13)
- [ ] 1.8 Confirmar que `flutter build macos --debug` compila y que `flutter analyze` queda sin warnings

## 2. Una sola condición de plataforma y telemetría

- [ ] 2.1 Test (rojo) de `AppConfig`: con `debugDefaultTargetPlatformOverride` en iOS y macOS `platformName` es `ios`/`macos` y `revenueCatApiKey` devuelve la llave; en Android `platformName` es `android` y la llave es `null`
- [ ] 2.2 Reemplazar `Platform.isIOS` en `lib/core/config/app_config.dart` por `platformName` y `revenueCatApiKey` basados en `defaultTargetPlatform`, y quitar `dart:io` si ya no se usa (D5)
- [ ] 2.3 Test (rojo) de `DefaultTelemetryClient`: `initPostHog` registra la super property `platform` con `AppConfig.platformName`, sin incluir correo ni otro dato personal
- [ ] 2.4 Registrar `platform` junto a `environment` en `DefaultTelemetryClient.initPostHog` (D9)
- [ ] 2.5 Actualizar el comentario de `RevenueCatSubscriptionStatusProvider` y de `AppConfig` que hoy dicen que solo Android carece de compras

## 3. Barra de menús, atajos y comandos

- [ ] 3.1 Agregar las claves de los menús (Acerca de, Ajustes, Edición y sus ítems, Ver, Sincronizar, Buscar, Ventana, Ayuda) a `app_en.arb`, `app_es.arb` (tuteo, sin voseo) y `app_fr.arb`, y correr `flutter gen-l10n`
- [ ] 3.2 Agregar `goToSettings` a `AppNavigator` y a su implementación con `go_router`
- [ ] 3.3 Extraer `_onRefresh` de `inbox_screen.dart` a una función pública del feature inbox (`refreshInbox(context)`) con los mismos SnackBars, y hacer que el `RefreshIndicator` la use; los tests existentes del Inbox siguen en verde
- [ ] 3.4 Test (rojo) de `DesktopCommands`: emite cada `DesktopCommand` (`sync`, `search`, `settings`) a todos los suscriptores y deja de emitir tras cancelar
- [ ] 3.5 Implementar `DesktopCommands` en `lib/presentation/app/`, crearlo en `main.dart` y pasarlo a `App` por constructor
- [ ] 3.6 Widget test (rojo) de `AdaptiveShell`: `search` abre la búsqueda con foco en Inbox, Favoritos, Leídos y Fuentes, y no hace nada en Resúmenes; `sync` dispara la sincronización del Inbox; `settings` navega a Ajustes
- [ ] 3.7 Suscribir `AdaptiveShell` a `DesktopCommands` (cancelar en `dispose`) reutilizando `_toggleSearch`, `refreshInbox` y `AppNavigator.goToSettings`
- [ ] 3.8 Widget test (rojo) de la barra de menús: sin sesión los ítems propios están deshabilitados y con sesión emiten el comando; en plataformas distintas de macOS no se monta
- [ ] 3.9 Implementar la barra de menús con `PlatformMenuBar` en el `builder` de `MaterialApp.router`, solo en macOS: menús Reevo, Edición (con los `Intent` de texto), Ver, Ventana y Ayuda, con `⌘R`, `⌘F` y `⌘,` (D7)
- [ ] 3.10 Comprobar que `⌘C`, `⌘V`, `⌘X`, `⌘A` y `⌘Z` funcionan en un `TextField` y en texto seleccionable del lector

## 4. Teclado y hover

- [ ] 4.1 Auditar las filas de artículo, fuente y resumen, los destinos del rail y las tarjetas del Inbox: listar los que no sean enfocables (`GestureDetector` sin `InkWell`/`FocusableActionDetector`)
- [ ] 4.2 Reemplazar esos elementos por `InkWell`/`ListTile` o `FocusableActionDetector` con `MouseRegion`, de modo que flechas, `Enter` y el cursor de clic funcionen; sin cambiar su aspecto en iOS
- [ ] 4.3 Definir `hoverColor` y `focusColor` en `AppTheme` para claro y oscuro (sin `surfaceContainerHighest`/`outlineVariant`) y comprobar que el foco es visible en cada fila
- [ ] 4.4 Widget tests: la flecha abajo mueve el foco al elemento siguiente, `Enter` abre el elemento enfocado y `Esc` cierra un diálogo abierto
- [ ] 4.5 Hacer que `Esc` cierre el detalle del master-detail solo cuando no hay un diálogo encima, y que no interfiera con un campo de búsqueda activo
- [ ] 4.6 Razonar y dejar anotado que el rail, el master-detail y la persistencia de selección siguen intactos al cruzar 840dp con estos cambios (regla de compatibilidad adaptativa de `CLAUDE.md`)

## 5. Login y cuenta en macOS

- [ ] 5.1 Pedir al usuario que verifique en la Mac, con un build firmado y sandbox activo, el login con Google (paso manual: avisar y esperar el resultado antes de seguir)
- [ ] 5.2 Pedir al usuario que verifique el login con Apple en la Mac
- [ ] 5.3 Con un usuario creado desde iOS, comprobar que el login con el mismo proveedor y correo en macOS abre la misma cuenta y no crea una nueva; si Supabase no vincula la identidad, detener y decidir el ajuste antes de seguir (D4)
- [ ] 5.4 Verificar que importar un OPML y exportar datos funcionan con los diálogos del sistema dentro del sandbox, y que el panel de compartir aparece anclado a la ventana
- [ ] 5.5 Verificar que cerrar sesión y borrar la cuenta funcionan en macOS

## 6. Suscripciones en macOS

- [ ] 6.1 Confirmar en RevenueCat (MCP o panel) que la app Apple App Store del proyecto cubre macOS con la misma llave pública y que los productos y el entitlement `pro` aplican a ambas plataformas
- [ ] 6.2 Confirmar en App Store Connect que el grupo de suscripciones se ofrece también en la versión de macOS de la ficha
- [ ] 6.3 Pedir al usuario que pruebe en la Mac, con cuenta sandbox, abrir el paywall, comprar mensual y anual, y restaurar compras; y que una suscripción activa de iOS se reconozca en macOS con la misma cuenta
- [ ] 6.4 Verificar que el paywall es diálogo desde 840dp y pantalla modal por debajo en la ventana de Mac

## 7. Distribución en Codemagic

- [ ] 7.1 Agregar a `codemagic.yaml` el workflow `macos-testflight` (disparo manual, `mac_mini_m2`, Flutter 3.44.6, `xcode: latest`) con los pasos de D11: dependencias, firma de Mac App Store (app e instalador), build number de macOS, `flutter build macos --release --dart-define=APP_ENV=prod`, empaquetado `productbuild`/`productsign` y publicación a TestFlight sin enviar a revisión
- [ ] 7.2 Agregar a `.github/workflows/codemagic-trigger.yml` el input `workflow` (`ios-testflight` por defecto, `macos-testflight`), validarlo antes de llamar a la API y pasar su valor como `workflowId`
- [ ] 7.3 Pedir al usuario que cree en Codemagic el workflow de macOS si hace falta y que dispare la primera corrida; corregir los flags del CLI según el resultado real (D11)
- [ ] 7.4 Confirmar que el build llega a TestFlight de macOS y que el binario es universal (`lipo -archs` sobre el ejecutable muestra `x86_64` y `arm64`)

## 8. Ficha de la Mac App Store (pasos manuales, uno a la vez)

- [ ] 8.1 Agregar la plataforma macOS a la app existente en App Store Connect y crear la versión de macOS con el mismo número que iOS
- [ ] 8.2 Preparar capturas reales de Mac, descripción, palabras clave y notas de revisión (incluyendo cómo entrar con Apple y cómo restaurar compras)
- [ ] 8.3 Enviar la versión de macOS a revisión

## 9. Cierre

- [ ] 9.1 Actualizar `CLAUDE.md`: comandos (`flutter build macos`), estructura (`macos/`, `DesktopCommands`), regla de que `Platform.isIOS` no se usa y la condición vive en `AppConfig`, workflow de Codemagic de macOS y la regla de no probar en simulador (la Mac la prueba el usuario)
- [ ] 9.2 Actualizar `README.md` con cómo compilar y correr en macOS
- [ ] 9.3 Correr `flutter analyze` y `flutter test` sin fallos y formatear con `dart format` solo los archivos tocados
- [ ] 9.4 Confirmar con el usuario, tras sus pruebas en la Mac, que todas las tareas están verificadas antes de archivar el change en el mismo PR final
