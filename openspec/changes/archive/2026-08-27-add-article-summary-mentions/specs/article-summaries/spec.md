## Purpose

Define cómo el sistema genera, almacena y presenta un resumen de un artículo individual usando una API de IA en la nube, on-demand, con persistencia por artículo para no regenerar innecesariamente.

## ADDED Requirements

### Requirement: Generación on-demand del resumen de un artículo

El sistema SHALL generar, mediante una API de IA en la nube, un resumen de texto de un único artículo a partir de su título y contenido, cuando el usuario lo solicita explícitamente desde el `ReaderScreen` de ese artículo. Para el contenido usado, el sistema SHALL aplicar el mismo criterio que `daily-summaries`: texto plano extraído de `contentHtml` cuando el artículo no está truncado, o `excerpt` como fallback si está truncado o vacío. El resumen SHALL generarse en el idioma correspondiente al locale activo de la app, con el mismo fallback a inglés que `daily-summaries` cuando el locale no es soportado o no puede determinarse.

La solicitud SHALL autenticarse con el access token de la sesión activa del usuario, bajo las mismas reglas que `daily-summaries`: el backend SHALL rechazar solicitudes sin sesión de usuario autenticada.

Generar un resumen de artículo SHALL requerir una suscripción activa (capability `subscription-entitlements`), verificada tanto en la UI (paywall) como en el backend, con el mismo comportamiento que `daily-summaries` ante el cierre del paywall sin comprar (no dispara la generación) y ante la compra completada (dispara la generación automáticamente a continuación).

La generación SHALL estar sujeta al mismo presupuesto diario de palabras de `ai-usage-budget` que ya comparten las demás features de IA de la app: si generar excedería el presupuesto disponible, el backend SHALL rechazar la solicitud sin invocar a la API de IA, y el sistema SHALL mostrar un estado de error distinguible que indica el límite diario alcanzado.

#### Scenario: Generar resumen de un artículo abierto

- **WHEN** el usuario con suscripción activa toca el botón de resumen en el `ReaderScreen` de un artículo que todavía no tiene resumen generado
- **THEN** el sistema invoca la API de IA con el título y contenido de ese artículo y, al finalizar, persiste el resultado asociado a ese artículo

#### Scenario: Usuario sin suscripción activa ve el paywall

- **WHEN** el usuario sin suscripción activa toca el botón de resumen de un artículo
- **THEN** el sistema muestra el paywall de Superwall en vez de disparar la generación

#### Scenario: Backend rechaza la generación sin suscripción activa

- **WHEN** `summarize-article` recibe una solicitud de un usuario autenticado cuya suscripción no está activa
- **THEN** el backend responde con un error de suscripción requerida y no invoca a la API de IA

#### Scenario: Cerrar el paywall sin comprar no dispara la generación

- **WHEN** el usuario sin suscripción activa toca el botón de resumen, se muestra el paywall, y lo cierra sin completar ninguna compra
- **THEN** el sistema no dispara la generación ni envía ninguna solicitud al backend

#### Scenario: Completar la compra desde el paywall dispara la generación

- **WHEN** el usuario sin suscripción activa toca el botón de resumen, se muestra el paywall, y completa la compra
- **THEN** el sistema, con la suscripción ya activa, dispara la generación automáticamente a continuación

#### Scenario: Solicitud sin sesión de usuario activa

- **WHEN** no hay una sesión de usuario activa en el dispositivo
- **THEN** el sistema no envía ninguna solicitud de generación al backend, y falla con un error indicando que se requiere sesión activa

#### Scenario: Rechazo por presupuesto diario de IA agotado

- **WHEN** el usuario toca el botón de resumen y generar excedería el presupuesto diario de palabras disponible
- **THEN** el backend rechaza la solicitud sin invocar a la API de IA, y el sistema muestra un estado de error que indica específicamente el límite diario alcanzado

#### Scenario: Falla la generación

- **WHEN** la llamada a la API de IA falla (sin red, error del backend, respuesta inválida, etc.)
- **THEN** el sistema muestra un estado de error distinguible, permitiendo reintentar

### Requirement: Persistencia del resumen por artículo, sin regenerar

El sistema SHALL persistir localmente, como máximo un resumen por artículo, asociado al id de ese artículo. Cuando el usuario abre el bottom sheet de resumen de un artículo que ya tiene un resumen persistido, el sistema SHALL mostrar directamente ese resultado guardado, sin invocar la API de IA ni descontar presupuesto diario de nuevo. No existe, en esta versión, ninguna acción de "regenerar" un resumen de artículo ya existente.

#### Scenario: Reabrir un artículo con resumen ya generado

- **WHEN** el usuario toca el botón de resumen de un artículo que ya tiene un resumen persistido de una sesión anterior
- **THEN** el sistema muestra el resumen guardado inmediatamente, sin llamar al backend ni consumir presupuesto de IA

#### Scenario: Primer resumen de un artículo se persiste

- **WHEN** el sistema genera exitosamente el resumen de un artículo que no tenía uno persistido
- **THEN** el sistema lo guarda asociado a ese artículo, disponible para próximas aperturas sin regenerar

### Requirement: Presentación del resumen en el lector

El sistema SHALL mostrar un botón en el AppBar del `ReaderScreen` que, al tocarlo, abre un bottom sheet con el resultado del resumen (y las menciones detectadas, ver capability `article-mentions`) del artículo abierto.

#### Scenario: Abrir el bottom sheet de resumen

- **WHEN** el usuario toca el botón de resumen en el AppBar del lector
- **THEN** el sistema abre un bottom sheet mostrando el resumen del artículo (generándolo primero si no existe uno persistido, o mostrando el guardado si ya existe)
