## Context

`lib/core/constants/app_constants.dart` ya establece el patrón de clase estática con constructor privado para configuración global (`AppConstants._()`, todo `static const`). La URL/anon key de Supabase hoy están repetidas como constantes locales en 5 archivos distintos (`main.dart`, `gemini_summary_generator.dart`, `supabase_email_feed_generator.dart`, `supabase_feed_sync_trigger.dart`, `delete_account.dart`), cada uno con el mismo valor copiado a mano. Ver proposal.md - Why.

## Goals / Non-Goals

**Goals:**
- Un solo lugar (`AppConfig`) que decide qué backend usa la app, sin que ningún archivo vuelva a hardcodear la URL/key.
- Selección explícita al buildear (`--dart-define=APP_ENV=prod`), con "dev" como default seguro para que un `flutter run` normal nunca toque prod sin pedirlo.

**Non-Goals:**
- No se arman flavors de Flutter (Xcode schemes / Android product flavors) — queda para un change futuro si hace falta tener las dos apps instaladas en paralelo.
- No se automatiza la creación del proyecto Supabase "dev" ni el deploy de sus Edge Functions vía script — se hace una vez, a mano (o asistido con las herramientas MCP de Supabase disponibles), como parte de las tasks de este change.
- No se toca el dominio/DNS de email-to-RSS para dev.

## Decisions

- **Un solo dart-define (`APP_ENV`), no uno por cada valor**: dado que la URL y el anon key de Supabase no son secretos (están pensados para embeberse en el cliente — el secreto real, `GEMINI_API_KEY`, vive del lado del servidor y nunca en la app), no hace falta pasar los valores reales por `--dart-define` en cada build. Alcanza con un flag que elige entre dos pares ya hardcodeados dentro de `AppConfig`, evitando tener que recordar/pasar múltiples defines.
- **Default `dev` cuando no se pasa `APP_ENV`**: `flutter run` sin flags (lo que se usa constantemente durante desarrollo normal) debe ser siempre seguro por default. Prod requiere un acto explícito (`--dart-define=APP_ENV=prod`), que es exactamente lo que ya va a hacer el comando de build para la store.
- **`AppConfig` como clase estática (mismo patrón que `AppConstants`)**, no un objeto inyectado vía `get_it`: es configuración de compilación (no cambia en runtime, no tiene estado, no necesita mockearse en tests — los tests ya mockean los generators/clients que la usan, no `AppConfig` en sí).
- **Log al arrancar, no una UI nueva**: alcanza para poder confirmar rápido contra qué backend corre una build (`adb logcat` / consola de Xcode), sin agregar un banner visual que habría que mantener y que no se pidió.
- **Los 5 archivos migran a leer `AppConfig`, no se centraliza además la lógica HTTP en sí**: cada uno sigue construyendo su propia URL de función (`${AppConfig.supabaseUrl}/functions/v1/<nombre>`) — mantiene el alcance acotado a "de dónde sale la URL base", sin tocar la forma en que cada uno arma su request.

## Risks / Trade-offs

- [Alguien podría buildear para la store sin pasar `--dart-define=APP_ENV=prod` y terminar subiendo una build que apunta a dev] → Mitigación: el log de ambiente al arrancar permite detectarlo antes de subir a TestFlight/Play Console con solo abrir la app una vez y mirar la consola; a futuro, los flavors eliminan este riesgo por completo al hacerlo estructural en vez de un flag que hay que recordar.
- [Mantener dos proyectos Supabase implica aplicar cada migración nueva y cada deploy de Edge Function dos veces manualmente] → Aceptado conscientemente: a esta escala (un solo desarrollador, días de trabajo entre releases) el costo de recordar "aplicar en los dos" es bajo comparado con el riesgo que evita.
