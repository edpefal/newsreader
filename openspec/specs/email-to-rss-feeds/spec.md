# Capability: Email to RSS Feeds

## Purpose

Generar direcciones de email desechables que reciben newsletters y las exponen como un feed RSS, para usuarios cuyos newsletters no publican un feed RSS/Atom descubrible automáticamente.

---

## Requirements

### Requirement: Generación de una dirección de email y feed RSS únicos
El sistema SHALL, ante una solicitud de creación, generar un identificador único (UUID v4), asociar una dirección de email (`<id>@<dominio configurado>`) y un feed RSS correspondiente (`/functions/v1/feed/<id>`), y persistir un registro en `generated_feeds` con un label opcional.

#### Scenario: Creación exitosa con label
- **WHEN** se solicita crear un feed con label "Newsletter de Fulano"
- **THEN** el sistema devuelve un id nuevo, la dirección de email `<id>@<dominio>` y la URL del feed correspondiente

#### Scenario: Creación exitosa sin label
- **WHEN** se solicita crear un feed sin especificar label
- **THEN** el sistema genera el feed igual, usando un título por defecto para el canal RSS

---

### Requirement: El feed generado es válido desde su creación, incluso sin items
El sistema SHALL servir un feed RSS 2.0 válido (parseable como RSS) para cualquier `generated_feeds.id` existente, incluso si todavía no tiene ningún `feed_item` asociado.

#### Scenario: Feed recién creado sin correos aún
- **WHEN** se solicita el feed de un id que existe pero no tiene items
- **THEN** el sistema devuelve un RSS 2.0 válido con `<channel>` (title, link) y cero `<item>`

---

### Requirement: Recepción y conversión de emails entrantes en items del feed
El sistema SHALL, al recibir un webhook de email entrante válido, extraer el `feed_id` del local-part de la dirección de destino, y si ese `feed_id` existe en `generated_feeds`, guardar un nuevo `feed_item` con el contenido del email (título desde el asunto, contenido HTML preferido sobre texto plano, remitente, y fecha de recepción).

#### Scenario: Email recibido para un feed existente
- **WHEN** llega un webhook de email entrante dirigido a `<id>@<dominio>` y ese id existe en `generated_feeds`
- **THEN** el sistema guarda un nuevo `feed_item` asociado a ese feed con el asunto como título y el HTML del correo como contenido

#### Scenario: Email recibido para un feed que no existe
- **WHEN** llega un webhook de email entrante dirigido a una dirección cuyo local-part no corresponde a ningún `generated_feeds.id` existente
- **THEN** el sistema responde con error 404 y no guarda ningún item

#### Scenario: Email duplicado (reintento de entrega)
- **WHEN** llega un webhook de email entrante con el mismo `messageId` que un `feed_item` ya guardado para el mismo feed
- **THEN** el sistema no crea un item duplicado

---

### Requirement: Autenticación del webhook de email entrante
El sistema SHALL rechazar cualquier solicitud al endpoint de recepción de email entrante que no incluya el secreto compartido correcto en la query string, y SHALL además validar que la IP de origen esté dentro del rango publicado por el proveedor de email entrante.

#### Scenario: Solicitud sin secreto o con secreto incorrecto
- **WHEN** llega una solicitud al endpoint de email entrante sin el query param `secret`, o con un valor incorrecto
- **THEN** el sistema rechaza la solicitud sin procesar ningún contenido

#### Scenario: Solicitud con secreto correcto pero IP fuera del rango esperado
- **WHEN** llega una solicitud con el secreto correcto pero desde una IP que no pertenece al rango publicado del proveedor de email entrante
- **THEN** el sistema rechaza la solicitud

---

### Requirement: Retención de items por tiempo
El sistema SHALL eliminar automáticamente los `feed_items` cuya fecha de recepción supere los 30 días, de forma periódica, sin requerir ninguna confirmación de sincronización por parte del cliente.

#### Scenario: Limpieza periódica de items antiguos
- **WHEN** transcurre el proceso de limpieza periódica
- **THEN** el sistema elimina todos los `feed_items` con `received_at` de más de 30 días, dejando intactos los `generated_feeds` a los que pertenecían
