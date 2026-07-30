# Capability: Feed Polling

## Purpose

Fetch y parseo centralizado de feeds RSS/Atom del lado del servidor (Edge Function), disparado on-demand por pull-to-refresh, con dedupe garantizado por constraint de base de datos y generación de ids de artículo en el servidor.

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

### Requirement: Fetch on-demand disparado por pull-to-refresh
El sistema SHALL permitir que el cliente dispare una ejecución del fetch de feeds al hacer pull-to-refresh en el Inbox, antes de sincronizar los cambios locales/remotos. No existe un fetch programado en segundo plano (sin cron): el contenido nuevo solo se descubre cuando algún dispositivo de la cuenta hace pull-to-refresh.

#### Scenario: Usuario hace pull-to-refresh
- **WHEN** el usuario hace pull-to-refresh en el Inbox
- **THEN** el sistema invoca el fetch de feeds del lado del servidor para las fuentes de ese usuario, y luego sincroniza los artículos resultantes al dispositivo

#### Scenario: Nadie hace pull-to-refresh
- **WHEN** ningún dispositivo de una cuenta hace pull-to-refresh durante varias horas
- **THEN** no aparece contenido nuevo hasta que algún dispositivo lo dispare manualmente — no hay actualización en segundo plano

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
