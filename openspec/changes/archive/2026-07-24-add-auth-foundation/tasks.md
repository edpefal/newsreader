## 1. Prerequisitos externos (manuales, antes de cualquier código)

- [x] 1.1 Crear proyecto/credenciales OAuth de Google en Google Cloud Console: client ID web (para Supabase), client ID Android (con el SHA-1 del keystore de debug/release), client ID iOS. Los 3 client IDs ya están cargados en el código: web como `serverClientId` en `SupabaseAuthClient`, e iOS como `GIDClientID`/URL scheme en `Info.plist`. Pendiente: registrar también el SHA-1 del keystore de **release** cuando exista (hoy solo está el de debug).
- [x] 1.2 Configurar "Sign in with Apple" en Apple Developer: habilitar la capability, crear el Services ID (`com.artlab.reevo.signin`), generar la key privada (Key ID `STQ8KVTFB6`, Team ID `HK5V7DF66Q`) para el intercambio de tokens.
- [x] 1.3 Habilitar los providers Google y Apple en el dashboard de Supabase Auth, cargando los client IDs/secrets correspondientes.
- [x] 1.4 Configurar el redirect URL / bundle ID / package name en cada consola según lo que pida Supabase Auth para cada provider. Client IDs de Apple en Supabase configurados con ambos identifiers (`com.artlab.reevo,com.artlab.reevo.signin`) para cubrir el flujo nativo (bundle ID) y el flujo web (Services ID).

## 2. Dependencias y abstracción de auth

- [x] 2.1 Agregar `supabase_flutter`, `google_sign_in` y `sign_in_with_apple` a `pubspec.yaml`.
- [x] 2.2 Crear `lib/core/auth/auth_client.dart`: interfaz `AuthClient` con métodos `signInWithGoogle()`, `signInWithApple()`, `signOut()`, y un stream/getter de sesión actual.
- [x] 2.3 Crear `lib/core/auth/supabase_auth_client.dart`: implementación concreta que envuelve `supabase_flutter`, `google_sign_in` y `sign_in_with_apple`, usando `signInWithIdToken` para intercambiar el token nativo por sesión de Supabase.
- [x] 2.4 Inicializar `Supabase` (URL + anon key) en `main.dart`, antes de `runApp`.
- [x] 2.5 Registrar `AuthClient` en `lib/core/di/injection.dart`.

## 3. Pantalla de login y gate de acceso

- [x] 3.1 Crear `lib/features/auth/presentation/screens/login_screen.dart` con los dos botones ("Continuar con Google", "Continuar con Apple") y manejo de estado de carga/error.
- [x] 3.2 Crear el cubit/estado asociado (`features/auth/presentation/cubit/`) que llama a `AuthClient` y expone el resultado a `LoginScreen`.
- [x] 3.3 Agregar la ruta `/login` en `lib/presentation/app/router.dart`.
- [x] 3.4 Agregar el `redirect` a nivel raíz del router: sin sesión activa, cualquier ruta redirige a `/login`; con sesión activa, `/login` redirige al Inbox. Usar `refreshListenable` enganchado al stream de sesión de `AuthClient` para que el router reaccione a cambios de sesión en vivo.

## 4. Logout

- [x] 4.1 Agregar la entrada "Cerrar sesión" al final del `NavigationDrawer` en `_ScaffoldWithNavBar`, llamando a `AuthClient.signOut()`.

## 5. Verificación

- [x] 5.1 Correr `flutter analyze` y resolver cualquier warning.
- [x] 5.2 Correr `flutter test` y confirmar que todo pasa. 194/194 sin regresiones.
- [x] 5.3 Escribir tests unitarios para el cubit de login (éxito, cancelación, error) usando mocks de `AuthClient`.
- [x] 5.4 Probar manualmente en un dispositivo/emulador real: login con Google, confirmar acceso al Inbox. Verificado por el usuario en emulador Android.
- [x] 5.5 Probar manualmente en un dispositivo iOS real (Sign in with Apple no funciona en emulador Android): login con Apple, confirmar acceso al Inbox. Verificado por el usuario en iPhone real (por cable USB; la conexión inalámbrica dio problemas de timeout). Encontrados y corregidos dos bugs reales de configuración: (1) el Team ID de firma en Xcode (`MX6ZD58S46`) no coincidía con el team donde se configuró Sign in with Apple (`HK5V7DF66Q`) — corregido en las 3 build configurations; (2) faltaba el archivo `Runner.entitlements` con el entitlement `com.apple.developer.applesignin` y su referencia `CODE_SIGN_ENTITLEMENTS` en el proyecto Xcode — sin esto, Apple devolvía `AuthorizationError 1000`. También hizo falta agregar la cuenta de Apple ID en Xcode (Settings → Accounts) para que el provisioning profile pudiera regenerarse con el nuevo entitlement.
- [x] 5.6 Cerrar y reabrir la app tras loguearse: confirmar que la sesión persiste y no vuelve a pedir login. Verificado por el usuario.
- [x] 5.7 Probar logout: confirmar que vuelve a la pantalla de login y que intentar navegar a cualquier ruta interna redirige de nuevo a `/login`. Verificado por el usuario.
