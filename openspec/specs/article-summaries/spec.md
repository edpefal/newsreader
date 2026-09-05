# Spec: Article Summaries

## Purpose

Define cómo el sistema genera, almacena y presenta un resumen de un artículo individual usando una API de IA en la nube, on-demand, con persistencia por artículo para no regenerar innecesariamente.

## Requirements

### Requirement: Generación on-demand del resumen de un artículo

El sistema SHALL generar, mediante una API de IA en la nube, un resumen de texto de un único artículo a partir de su título y contenido, cuando el usuario lo solicita explícitamente desde el `ReaderScreen` de ese artículo. Para el contenido usado, el sistema SHALL aplicar el mismo criterio que `daily-summaries`: texto plano extraído de `contentHtml` cuando el artículo no está truncado, o `excerpt` como fallback si está truncado o vacío. El resumen SHALL generarse en el idioma correspondiente al locale activo de la app, con el mismo fallback a inglés que `daily-summaries` cuando el locale no es soportado o no puede determinarse.

El resumen SHALL tener entre 1 y 4 párrafos: el sistema SHALL usar un único párrafo como caso normal, y SHALL permitir hasta 4 párrafos solo cuando el artículo cubra varios temas o ideas separables que lo justifiquen. El sistema SHALL preservar la voz editorial existente (tono business-casual, ángulo propio, sin enumerar temas de forma plana) en cada párrafo del resumen, sin importar cuántos párrafos use.

La solicitud SHALL autenticarse con el access token de la sesión activa del usuario, bajo las mismas reglas que `daily-summaries`: el backend SHALL rechazar solicitudes sin sesión de usuario autenticada.

Generar un resumen de artículo SHALL requerir, alternativamente: (a) una suscripción activa (capability `subscription-entitlements`), o (b) cupo disponible del límite diario gratis de `ai-usage-budget` (2 resúmenes de artículo por día de servidor sin suscripción activa, ver capability `ai-usage-budget`, requirement "Límite diario de resúmenes de artículo por usuario"). El sistema SHALL verificarlo en el siguiente orden, tanto en la UI como en el backend: si hay suscripción activa, abrir el bottom sheet/generar directo sin consultar el cupo gratis; si no hay suscripción activa pero hay cupo diario gratis disponible, abrir el bottom sheet/generar igual que con suscripción; si no se cumple ninguna de las dos, la UI SHALL abrir igualmente el bottom sheet, mostrando el estado de cupo gratis agotado en vez de generar (ver Requirement: Estado de cupo gratis agotado en el bottom sheet), y el backend SHALL rechazar la solicitud sin invocar a la API de IA si de todas formas llega una. El paywall de Superwall ya no se muestra automáticamente en este caso: solo se dispara si el usuario toca el botón correspondiente dentro de ese estado. Ante el cierre del paywall sin comprar, el sistema NO SHALL disparar la generación (mismo comportamiento que `daily-summaries`); ante la compra completada desde el paywall, la generación SHALL dispararse automáticamente a continuación.

La generación SHALL estar sujeta al límite diario vigente (25 con suscripción activa, 2 sin ella) y al techo de longitud por artículo de `ai-usage-budget`: si generar excedería el límite diario disponible, o si el contenido del artículo supera el techo de longitud, el backend SHALL rechazar la solicitud sin invocar a la API de IA, y el sistema SHALL mostrar un estado de error distinguible para cada uno de esos dos casos. El estado de error por límite diario alcanzado tras un rechazo del backend SHALL ser el mismo sin importar si el usuario tiene o no suscripción activa (no hay un estado ni mensaje separado para "cupo gratis agotado" en ese caso) -- esto es distinto del estado de cupo gratis agotado mostrado antes de intentar generar, que sí es exclusivo de usuarios sin suscripción activa (ver Requirement: Estado de cupo gratis agotado en el bottom sheet).

#### Scenario: Generar resumen de un artículo abierto

- **WHEN** el usuario con suscripción activa toca el botón de resumen en el `ReaderScreen` de un artículo que todavía no tiene resumen generado
- **THEN** el sistema invoca la API de IA con el título y contenido de ese artículo y, al finalizar, persiste el resultado asociado a ese artículo

#### Scenario: Artículo simple recibe un resumen de un párrafo

- **WHEN** el usuario genera el resumen de un artículo que trata un único tema o idea central
- **THEN** el resumen generado tiene un solo párrafo

#### Scenario: Artículo con varios temas recibe un resumen de varios párrafos

- **WHEN** el usuario genera el resumen de un artículo que cubre varios temas o ideas separables y un solo párrafo no alcanza para cubrirlos con la voz editorial esperada
- **THEN** el resumen generado usa más de un párrafo, hasta un máximo de 4, manteniendo la voz editorial en cada uno

#### Scenario: Usuario sin suscripción y sin cupo gratis ve el bottom sheet con el cupo agotado

- **WHEN** el usuario sin suscripción activa y sin cupo diario gratis disponible toca el botón de resumen de un artículo
- **THEN** el sistema abre el bottom sheet mostrando el estado de cupo gratis agotado, sin invocar la API de IA ni mostrar el paywall automáticamente

#### Scenario: Usuario sin suscripción pero con cupo gratis abre el sheet sin ver el paywall

- **WHEN** el usuario sin suscripción activa, con cupo diario gratis disponible, toca el botón de resumen de un artículo
- **THEN** el sistema abre el bottom sheet y genera el resumen igual que con suscripción activa, sin mostrar el paywall

#### Scenario: Backend rechaza la generación sin suscripción activa ni cupo gratis

- **WHEN** `summarize-article` recibe una solicitud de un usuario autenticado cuya suscripción no está activa y cuyo cupo diario gratis (2/día) ya está agotado
- **THEN** el backend responde con un error de suscripción requerida y no invoca a la API de IA

#### Scenario: Cerrar el paywall sin comprar no dispara la generación

- **WHEN** el usuario sin suscripción activa y sin cupo gratis toca el botón de resumen, ve el estado de cupo agotado, toca el botón de premium, se muestra el paywall, y lo cierra sin completar ninguna compra
- **THEN** el sistema no dispara la generación ni envía ninguna solicitud al backend, y el bottom sheet sigue mostrando el estado de cupo agotado

#### Scenario: Completar la compra desde el paywall dispara la generación

- **WHEN** el usuario sin suscripción activa toca el botón de resumen, ve el estado de cupo agotado, toca el botón de premium, se muestra el paywall, y completa la compra
- **THEN** el sistema, con la suscripción ya activa, dispara la generación automáticamente a continuación

#### Scenario: Solicitud sin sesión de usuario activa

- **WHEN** no hay una sesión de usuario activa en el dispositivo
- **THEN** el sistema no envía ninguna solicitud de generación al backend, y falla con un error indicando que se requiere sesión activa

#### Scenario: Rechazo por límite diario de resúmenes agotado, con suscripción activa

- **WHEN** el usuario con suscripción activa toca el botón de resumen y ya generó 25 resúmenes de artículo hoy
- **THEN** el backend rechaza la solicitud sin invocar a la API de IA, y el sistema muestra el estado neutro de límite diario alcanzado (ver Requirement: Indicador de uso restante en el bottom sheet)

#### Scenario: Rechazo por límite diario gratis agotado, sin suscripción activa

- **WHEN** el usuario sin suscripción activa, con cupo gratis disponible al momento de tocar el botón, ya generó 2 resúmenes de artículo hoy para cuando la solicitud llega al backend (ej. condición de carrera entre dispositivos)
- **THEN** el backend rechaza la solicitud sin invocar a la API de IA, y el sistema muestra el mismo estado neutro de límite diario alcanzado que vería un usuario con suscripción activa al llegar a 25

#### Scenario: Rechazo por artículo demasiado largo para resumir

- **WHEN** el usuario toca el botón de resumen de un artículo cuyo contenido supera el techo de longitud de `ai-usage-budget`
- **THEN** el backend rechaza la solicitud sin invocar a la API de IA y sin descontar del límite diario, y el sistema muestra un estado de error específico indicando que ese artículo es demasiado largo para resumir automáticamente

#### Scenario: Falla la generación por un motivo genérico

- **WHEN** la llamada a la API de IA falla por un motivo genérico (sin red, timeout, error del backend, respuesta con formato inválido, etc.)
- **THEN** el sistema muestra un estado de error distinguible, permitiendo reintentar

#### Scenario: El proveedor de IA bloquea el contenido del artículo

- **WHEN** el proveedor de IA rechaza generar el resumen porque clasifica el contenido del artículo como no permitido por su propia política de contenido
- **THEN** el sistema muestra un estado de error específico que indica que ese artículo en particular no se puede resumir, sin invitar a reintentar la misma acción sin cambios

#### Scenario: El backend rechaza por falta de suscripción activa al momento de generar

- **WHEN** el backend rechaza la solicitud de generación porque la suscripción del usuario no está activa en la tabla de entitlements (por ejemplo, expiró entre la verificación local de la UI y la verificación del backend)
- **THEN** el sistema muestra un estado de error específico que indica que se requiere una suscripción activa, distinguible del error genérico de generación

### Requirement: Indicador de uso restante en el bottom sheet

El sistema SHALL mostrar siempre, en el bottom sheet de resumen del `ReaderScreen`, un indicador con la cantidad de resúmenes restantes hoy respecto al límite diario vigente para ese usuario (25 con suscripción activa, 2 sin ella), sin condicionarlo a que quede poco consumo disponible. El indicador SHALL usar un tono visual neutro, distinto del color de acento reservado para no-leído/favorito. Cuando el usuario alcanzó el límite diario vigente, el sistema SHALL mostrar un estado propio y distinguible del bloque de error genérico usado para otros `AppErrorCode` (sin el color de error ni iconografía de alerta), indicando que el límite se alcanzó y cuándo vuelve a estar disponible — el mismo estado sin importar si el límite alcanzado fue 25 (con suscripción) o 2 (sin ella). El texto de ese estado SHALL reflejar el número real del límite alcanzado (25 o 2) en vez de un número fijo hardcodeado.

#### Scenario: Indicador siempre visible
- **WHEN** el usuario abre el bottom sheet de resumen con cualquier cantidad de resúmenes restantes hoy (incluido el máximo del límite vigente para ese usuario)
- **THEN** el sistema muestra un indicador informativo con la cantidad restante, en tono neutro, sin bloquear ninguna acción

#### Scenario: Límite diario alcanzado se muestra en tono neutro, no como error
- **WHEN** el backend rechaza la generación porque el usuario ya alcanzó el límite diario vigente (25 resúmenes con suscripción activa, o 2 sin ella)
- **THEN** el sistema muestra, en el bottom sheet, un estado propio con superficie y tono neutro (no el bloque rojo de error genérico) indicando el límite alcanzado y cuándo se resetea

#### Scenario: El texto del límite alcanzado muestra el número correcto sin suscripción
- **WHEN** un usuario sin suscripción activa alcanza su límite diario gratis de 2 resúmenes
- **THEN** el texto mostrado indica "2", no "25"

### Requirement: Estado de cupo gratis agotado en el bottom sheet

Cuando el usuario sin suscripción activa y sin cupo diario gratis disponible toca el botón de resumen de un artículo, el sistema SHALL abrir el bottom sheet mostrando un estado propio, distinguible del bloque de error genérico y del estado neutro de "límite diario alcanzado" (ver Requirement: Indicador de uso restante en el bottom sheet), que indica al usuario que consumió su resumen gratis de hoy. Ese estado SHALL incluir un botón visible que, al tocarlo, dispara el paywall de Superwall (mismo paywall y mismo flujo post-compra que el resto de la app: al completar la compra, la generación se dispara automáticamente; al cerrar sin comprar, no se dispara ninguna generación y el bottom sheet permanece en este mismo estado). Este estado SHALL aplicar únicamente antes de intentar generar (sin invocar al backend) y solo a usuarios sin suscripción activa.

#### Scenario: Abrir el sheet sin cupo gratis muestra el estado de cupo agotado

- **WHEN** el usuario sin suscripción activa y sin cupo diario gratis disponible toca el botón de resumen de un artículo
- **THEN** el bottom sheet muestra un mensaje indicando que ya usó su resumen gratis de hoy, junto con un botón para acceder a la versión premium

#### Scenario: Tocar el botón de premium dispara el paywall

- **WHEN** el usuario ve el estado de cupo gratis agotado en el bottom sheet y toca el botón de premium
- **THEN** el sistema muestra el paywall de Superwall

#### Scenario: El estado de cupo agotado no invoca a la API de IA

- **WHEN** el sistema muestra el estado de cupo gratis agotado en el bottom sheet
- **THEN** el sistema no envía ninguna solicitud de generación al backend hasta que el usuario complete una compra desde el paywall

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

### Requirement: El contenido del artículo enviado a la API de IA está delimitado de la instrucción del sistema

El sistema SHALL enviar el contenido del artículo a la API de IA envuelto en un delimitador explícito que lo distinga de la instrucción del sistema, junto con una indicación de que ese contenido delimitado se trata siempre como texto a resumir y nunca como una instrucción a seguir, sin importar lo que ese contenido diga.

#### Scenario: Artículo cuyo contenido incluye texto que simula una instrucción

- **WHEN** el contenido de un artículo incluye texto que intenta darle una instrucción distinta al modelo (por ejemplo, pedirle que ignore las instrucciones anteriores o cambie de tono/idioma)
- **THEN** el sistema igual envía ese texto delimitado como contenido a resumir, sin que dejen de aplicarse las instrucciones de tono, idioma y formato ya definidas para el resumen
