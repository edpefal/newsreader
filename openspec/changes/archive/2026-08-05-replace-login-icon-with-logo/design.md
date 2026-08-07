## Context

Ver proposal.md - Why. `assets/reevo_logo.png` es un PNG de 1024×1024 con fondo transparente (mismo archivo que usa `flutter_launcher_icons` para generar los íconos de instalación), hoy no declarado en la sección `assets:` de `pubspec.yaml`, así que `Image.asset()` no podría cargarlo sin ese paso previo.

## Goals / Non-Goals

**Goals:**
- Que la pantalla de login muestre el logo real de Reevo en vez de un ícono genérico de Material, manteniendo la disposición visual actual (centrado, mismo tamaño aproximado, mismo espaciado con el texto de abajo).

**Non-Goals:**
- No se regenera ni se reemplaza el archivo de logo en sí — se usa el PNG existente tal cual.
- No se reemplaza ningún otro uso de íconos genéricos en la app (splash screen, otras pantallas) — alcance limitado a la pantalla de login, único pedido.
- No se introduce ninguna abstracción nueva de imágenes — `Image.asset` es un widget del framework Flutter, no una librería de terceros que requiera pasar por `core/widgets/` según la tabla de abstracciones de CLAUDE.md (esa tabla aplica a paquetes como `cached_network_image`, no a `Image.asset`).

## Decisions

### Decisión 1: Declarar el archivo específico, no toda la carpeta `assets/`

En `pubspec.yaml`, se declara `assets/reevo_logo.png` explícitamente en vez de `assets/` (la carpeta completa). Es el único archivo que la app necesita cargar en runtime hoy; declarar la carpeta completa incluiría cualquier archivo futuro sin que sea una decisión consciente.

**Alternativa considerada**: declarar `- assets/` para no tener que tocar `pubspec.yaml` de nuevo si se agregan más assets después. Se descartó por ser una generalización no pedida — si se necesita otro asset en el futuro, agregar una línea a `pubspec.yaml` es trivial.

### Decisión 2: Usar `Image.asset` directo, sin envolver en un widget propio

Se reemplaza el `Icon(...)` por `Image.asset('assets/reevo_logo.png', height: 72)` directamente en `login_screen.dart`, sin crear un widget intermedio (p. ej. `AppLogo`). Es un solo punto de uso; envolver en un widget separado sería una abstracción prematura para un único caller.

## Risks / Trade-offs

- **[Riesgo] El PNG puede verse distinto en tamaño/proporción al ícono de Material que reemplaza (72×72 con `size:`, que fija ancho y alto por igual)** → Mitigación: se usa `height: 72` en `Image.asset` y se deja que el ancho se ajuste según el aspect ratio real del PNG, evitando distorsión; se verifica visualmente en el simulador antes de dar la tarea por completa.
