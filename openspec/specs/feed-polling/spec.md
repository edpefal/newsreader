# Capability: Feed Polling

## Purpose

Fetch y parseo centralizado de feeds RSS/Atom del lado del servidor (Edge Function), disparado on-demand por pull-to-refresh, por login, o al agregar una fuente, con dedupe garantizado por constraint de base de datos y generación de ids de artículo en el servidor.

---

## Requirements

### Requirement: El servidor es el único que hace fetch de los feeds RSS
El sistema SHALL hacer fetch y parseo de los feeds RSS exclusivamente desde el servidor (Edge Function), nunca desde los clientes. Los clientes NO SHALL contener lógica de fetch/parseo de RSS ni crear registros de artículo a partir de contenido de feed.

#### Scenario: Dos dispositivos de la misma cuenta nunca generan el mismo artículo dos veces
- **WHEN** el servidor hace fetch de un feed y encuentra un ítem cuya URL ya existe como artículo para esa fuente
- **THEN** el sistema no crea un registro duplicado, sin importar cuántos dispositivos estén sincronizados con esa cuenta

---

### Requirement: Dedupe garantizado por constraint de base de datos
El sistema SHALL garantizar que no existan dos artículos con la misma combinación de `source_id` y `article_url` mediante un constraint único a nivel de base de datos, no solo mediante lógica de aplicación.

#### Scenario: Fetch concurrente del mismo feed
- **WHEN** dos invocaciones de la función de sincronización procesan el mismo feed al mismo tiempo (por ejemplo, dos pull-to-refresh disparados desde dos dispositivos de la misma cuenta)
- **THEN** el segundo intento de insertar el mismo artículo falla silenciosamente por el constraint único, sin crear una fila duplicada ni interrumpir el resto del fetch

---

### Requirement: Fetch on-demand disparado por pull-to-refresh, por login, o al agregar una fuente
El sistema SHALL permitir que el cliente dispare una ejecución del fetch de feeds al hacer pull-to-refresh en el Inbox, automáticamente al completar el login (ver capability `cloud-sync`, requirement "Sincronización automática al iniciar sesión"), o automáticamente al agregar una fuente exitosamente (ver capability `source-management`), antes de sincronizar los cambios locales/remotos en cada caso. No existe un fetch programado en segundo plano (sin cron): el contenido nuevo solo se descubre cuando algún dispositivo de la cuenta hace pull-to-refresh, inicia sesión, o agrega una fuente.

El fetch disparado al agregar una fuente SHALL ser el mismo fetch de cuenta completa que usan pull-to-refresh y login (no un fetch acotado a una sola fuente); el sistema confía en que el servidor prioriza las fuentes nunca sincronizadas para que la recién agregada quede cubierta por esa misma invocación.

Si un pull-to-refresh manual y el fetch automático de login coinciden en el tiempo para el mismo usuario, el sistema SHALL evitar disparar dos invocaciones simultáneas del fetch de feeds: la segunda solicitud SHALL esperar y reutilizar el resultado de la que ya está en curso, en vez de iniciar una invocación adicional. Esta deduplicación no aplica al fetch disparado por agregar una fuente, que es independiente y no comparte invocación en vuelo con el Inbox.

#### Scenario: Usuario hace pull-to-refresh
- **WHEN** el usuario hace pull-to-refresh en el Inbox
- **THEN** el sistema invoca el fetch de feeds del lado del servidor para las fuentes de ese usuario, y luego sincroniza los artículos resultantes al dispositivo

#### Scenario: Usuario inicia sesión
- **WHEN** el usuario inicia sesión y la sincronización inicial de datos ya existentes en la nube termina
- **THEN** el sistema invoca automáticamente el fetch de feeds del lado del servidor para las fuentes de ese usuario, sin que el usuario tenga que hacer pull-to-refresh

#### Scenario: Usuario agrega una fuente exitosamente
- **WHEN** el usuario agrega una fuente nueva y la validación de feed resulta exitosa
- **THEN** el sistema invoca automáticamente el fetch de feeds del lado del servidor para las fuentes de ese usuario, sin que el usuario tenga que hacer pull-to-refresh ni saber que esa opción existe

#### Scenario: Nadie hace pull-to-refresh, inicia sesión, ni agrega una fuente
- **WHEN** ningún dispositivo de una cuenta hace pull-to-refresh, inicia sesión, ni agrega una fuente durante varias horas
- **THEN** no aparece contenido nuevo hasta que algún dispositivo dispare el fetch por alguno de esos medios — no hay actualización en segundo plano

#### Scenario: Pull-to-refresh manual mientras el fetch de login sigue en curso
- **WHEN** el fetch de feeds disparado automáticamente por el login todavía está en curso, y el usuario hace pull-to-refresh en ese momento
- **THEN** el sistema no dispara una segunda invocación del fetch de feeds; el pull-to-refresh espera el resultado de la invocación ya en curso y continúa su flujo normal (sincronizar estado y recargar) con ese resultado

---

### Requirement: Un fallo en una fuente no interrumpe el fetch de las demás
El sistema SHALL continuar procesando el resto de las fuentes del usuario si el fetch o parseo de una fuente particular falla (timeout, feed inválido, error de red), igual que el comportamiento actual de `SyncSources`.

#### Scenario: Una fuente tiene un feed roto
- **WHEN** el fetch de la fuente A falla por timeout o XML inválido
- **THEN** las demás fuentes del mismo usuario se procesan normalmente en la misma invocación

---

### Requirement: Los artículos nacen con id generado por el servidor
El sistema SHALL generar el `id` de cada artículo en el servidor al insertarlo en Postgres. Los clientes NO SHALL generar ids de artículo.

#### Scenario: Artículo nuevo sincronizado a dos dispositivos
- **WHEN** el servidor crea un artículo nuevo y dos dispositivos de la misma cuenta sincronizan
- **THEN** ambos dispositivos guardan localmente el artículo con el mismo `id`, permitiendo que cambios de estado (leído/favorito) hechos en cualquiera de los dos converjan sobre el mismo registro

---

### Requirement: El servidor extrae una imagen destacada de cada ítem del feed
El sistema SHALL intentar obtener una URL de imagen destacada para cada ítem de feed durante el fetch, probando las siguientes fuentes en orden hasta encontrar una: (1) imagen de tipo Media RSS del ítem, (2) enclosure del ítem cuyo tipo sea una imagen, (3) imagen de iTunes del ítem, (4) primera imagen embebida en el HTML del contenido del ítem. El sistema SHALL usar la primera fuente que produzca una URL válida y SHALL ignorar las fuentes de menor prioridad una vez encontrada una.

#### Scenario: Feed con imagen Media RSS
- **WHEN** un ítem del feed incluye una imagen Media RSS
- **THEN** el artículo creado usa esa imagen, sin evaluar enclosure, iTunes ni el HTML del contenido

#### Scenario: Feed sin Media RSS pero con enclosure de imagen
- **WHEN** un ítem del feed no incluye imagen Media RSS pero sí un enclosure cuyo tipo es una imagen
- **THEN** el artículo creado usa la imagen del enclosure

#### Scenario: Feed con imagen únicamente embebida en el HTML
- **WHEN** un ítem del feed no incluye imagen Media RSS, enclosure de imagen, ni imagen de iTunes, pero su contenido HTML incluye al menos una imagen
- **THEN** el artículo creado usa la primera imagen encontrada en ese HTML

---

### Requirement: Ausencia de imagen no es una condición de fallo
El sistema SHALL crear el artículo normalmente cuando ninguna de las fuentes de imagen produce una URL válida, sin registrar la fuente como fallida ni interrumpir el fetch de las demás fuentes.

#### Scenario: Feed sin ninguna imagen disponible
- **WHEN** un ítem del feed no tiene imagen Media RSS, enclosure de imagen, imagen de iTunes, ni imágenes embebidas en su HTML
- **THEN** el artículo se crea sin imagen asociada, y la sincronización de esa fuente se considera exitosa
