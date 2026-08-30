## Context

Ver `proposal.md` - Why. Hoy no existe ningún workflow de CI/CD (no `.github/workflows`, no fastlane, no Codemagic). Flutter local: 3.44.6 stable, sin pin vía FVM. El repo ya tiene 82 archivos de test (`bloc_test` + `mocktail`) y usa `flutter_lints` vía `analysis_options.yaml`.

Los secretos de la app (Supabase anon key, Sentry DSN, PostHog key) están hardcodeados por entorno en `lib/core/config/app_config.dart` y se seleccionan con `--dart-define=APP_ENV=prod|dev` (ya existente, no se agrega nada nuevo acá). El único secreto real que necesita este change es la App Store Connect API key, que vive como integración de Codemagic — nunca en el repo.

El usuario tiene cuenta de App Store Connect con la app registrada (`com.artlab.reevo`). No tiene cuenta de Play Console todavía — Android queda fuera de alcance.

## Goals / Non-Goals

**Goals:**
- Bloquear regresiones de lint/tests antes de mergear a `main`, automáticamente.
- Dar un botón repetible para producir un build de iOS firmado y subido a TestFlight interno, sin pasos manuales de Xcode/certificados.
- No consumir minutos de Codemagic en cada push (el free tier es limitado: ~500 min/mes en macOS M2, ~10-20 min por build iOS).

**Non-Goals:**
- No se automatiza Android (ni build ni firma) en este change.
- No se automatiza la subida a revisión de App Store (eso es Fase 3, más adelante, disparada por git tag).
- No se introduce fastlane ni `fastlane match` — la firma la resuelve Codemagic vía integración con App Store Connect API.
- No se pinea la versión de Flutter con FVM en este change (fuera de alcance; si se vuelve un problema de reproducibilidad, es un change aparte).

## Decisions

### CI en GitHub Actions, no en Codemagic
`flutter analyze` + `flutter test` corren en GitHub Actions (runners Linux, gratis para repos privados dentro de límites generosos), no en Codemagic. Codemagic se reserva exclusivamente para el build firmado de iOS, que es lo único que necesita macOS y lo único que consume minutos limitados. Alternativa considerada: correr todo en Codemagic para tener un solo sistema — descartada porque mezclaría minutos de CI (que deberían correr en cada push sin fricción) con minutos de CD (que son escasos).

### Trigger manual para CD, no automático en merge a main
Decisión explícita del usuario tras revisar el consumo de minutos: con builds de ~10-20 min y 500 min/mes gratis, un auto-deploy en cada merge agotaría el free tier rápido dado el ritmo de merges frecuentes vía OpenSpec. Se usa el trigger manual nativo de Codemagic ("Start new build" en la UI) en vez de, por ejemplo, atarlo a un git tag — porque no hay todavía necesidad de un mecanismo más elaborado que un click, dado que solo el usuario consume estos builds (TestFlight interno).

### Firma vía App Store Connect API, no fastlane match
Codemagic soporta gestión automática de firma de iOS conectándose directamente a la App Store Connect API (crea/reusa certificados y provisioning profiles sin que el desarrollador los administre). Se prefiere esto sobre `fastlane match` (que requeriría un repo git aparte para certificados encriptados) porque es menos superficie a mantener para un desarrollador solo, y es el camino que Codemagic documenta como el estándar para setups nuevos.

### Build number autoincremental, versión semántica manual
Se mantiene la convención existente de bump manual de `X.Y.Z` en `pubspec.yaml` vía commit `chore:`. Codemagic resuelve el build number (`+N` / `CFBundleVersion`) automáticamente contra el último subido a TestFlight, para evitar que una subida falle por número de build duplicado cuando no hubo bump manual entre dos builds de prueba. Esto no cambia el archivo `pubspec.yaml` en el repo — el build number que se sube a TestFlight puede diferir del que está commiteado, que sigue siendo la fuente de verdad de la versión "oficial".

## Risks / Trade-offs

- **[Riesgo]** El build number efectivo en TestFlight puede divergir del `+N` commiteado en `pubspec.yaml`, porque Codemagic lo recalcula. → **Mitigación**: aceptable porque el build number de TestFlight es solo un identificador técnico de subida; la versión semántica visible (`X.Y.Z`) sigue siendo la commiteada y es la que importa para comunicación con el usuario/soporte.
- **[Riesgo]** El trigger manual depende de que el desarrollador se acuerde de iniciar el build antes de probar en dispositivo — no hay push automático. → **Mitigación**: aceptado explícitamente por el usuario a cambio de no gastar minutos del free tier; se puede revisar más adelante si el free tier deja de ser una restricción real.
- **[Riesgo]** Sin FVM, un cambio de versión de Flutter en la máquina local o en los runners podría generar builds inconsistentes entre CI, CD y desarrollo local. → **Mitigación**: fuera de alcance de este change; documentado como no-goal explícito.

## Migration Plan

No aplica migración de datos. Pasos de habilitación (algunos manuales, fuera del repo, responsabilidad del usuario):
1. Mergear `.github/workflows/ci.yml` — queda activo en el próximo push/PR sin configuración adicional.
2. Conectar el repo a Codemagic y configurar la integración de App Store Connect API key (paso manual del usuario en la UI de Codemagic, no versionado).
3. Mergear `codemagic.yaml`.
4. Confirmar el primer build manual desde Codemagic y validar que llega a TestFlight interno.

Rollback: eliminar o deshabilitar los workflows/`codemagic.yaml` no afecta el código de la app ni requiere revertir nada más.
