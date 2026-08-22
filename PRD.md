# PRD: Reevo (v2)

> Este documento reemplaza la versión original (MVP local-only, sin cuentas). Desde entonces el producto evolucionó hacia un modelo con cuenta y sincronización en la nube. Ver `openspec/specs/` para el detalle línea a línea de cada capability — este PRD es la vista de producto, no la fuente normativa de comportamiento.

---

## 1. Visión del Producto

Crear un espacio de lectura dedicado que rescate los boletines informativos del desorden del correo electrónico. La aplicación centraliza suscripciones de plataformas como Substack, WordPress.com o Ghost en una interfaz limpia, priorizando la concentración y el hábito de lectura sin distracciones — y ahora, con cuenta de usuario, ese hábito y esas suscripciones viajan con la persona entre sus dispositivos.

---

## 2. Plataforma Objetivo

- **iOS y Android**, publicadas en App Store y Google Play para público general.
- Versiones mínimas de SO: iOS 16+ / Android 8.0 (API 26)+.
- Backend: Supabase (Postgres + Auth + Edge Functions) como servicio administrado.

---

## 3. Objetivos del Producto

- **Descongestionar el Email:** mover el consumo de contenido editorial fuera de la bandeja de entrada, incluso para newsletters sin feed RSS propio (vía email-to-RSS).
- **Lectura de Alto Valor:** interfaz optimizada para textos largos, con imagen destacada y renderizado fiel del HTML original.
- **Continuidad entre dispositivos:** el estado de lectura, favoritos y fuentes suscritas es el mismo sin importar en qué dispositivo se abra la app.
- **Síntesis diaria:** ofrecer, además del inbox artículo por artículo, un resumen editorial generado por IA que dé ganas de volver a la app todos los días.
- **Simplicidad de configuración:** agregar una fuente debe funcionar pegando el link humano del sitio, sin que el usuario necesite encontrar la URL exacta del feed.

**Criterio de éxito:** un usuario nuevo puede crear cuenta, agregar una fuente (aunque no publique RSS), leer un artículo completo, y volver a encontrar ese artículo y ese estado en otro dispositivo — todo sin fricción ni errores.

---

## 4. Requisitos Funcionales

### A. Cuenta y Autenticación

- **Login obligatorio:** toda pantalla de la app requiere sesión activa (Google Sign-In o Sign in with Apple vía Supabase Auth). Sin sesión, la app muestra la pantalla de login antes que cualquier otra cosa.
- **Persistencia de sesión:** con sesión previamente válida, la app entra directo al Inbox.
- **Cierre de sesión:** disponible desde el `NavigationDrawer`; limpia los datos locales del dispositivo para evitar colisiones si otra cuenta inicia sesión después.
- **Borrado de cuenta y datos:** el usuario puede eliminar su cuenta y todos sus datos asociados (fuentes, artículos, resúmenes, estado) desde dentro de la app, sin necesidad de contactar soporte. Requisito de compliance de las tiendas de aplicaciones para cualquier app que permita crear cuenta in-app.
- **Exportación de datos:** el usuario puede solicitar una copia de sus datos (fuentes suscritas, artículos favoritos como mínimo) en un formato legible (OPML para fuentes, JSON o similar para el resto).

### B. Gestión de Suscripciones

- **Registro por URL humana o feed exacto:** el usuario pega el link del sitio (ej. `autor.substack.com`) o la URL exacta del feed; el sistema intenta primero la URL tal cual como feed, y si falla, aplica heurísticas de detección automática por plataforma conocida (Substack, WordPress.com, Ghost Pro), incluyendo el formato de perfil `substack.com/@usuario`.
- **Fallback vía email-to-RSS:** si la detección automática falla, el sistema ofrece generar una dirección de email desechable que recibe el newsletter por correo y lo expone como feed RSS propio, con retención de 30 días sobre los items recibidos.
- **Identificación automática:** tras validar el feed, la app extrae nombre, autor e ícono de la fuente.
- **Importación masiva vía OPML:** el usuario puede importar múltiples fuentes de una vez desde un archivo `.opml`/`.xml`, con preview de validación concurrente por feed (nuevo/válido, ya suscrito, o error) y selección granular antes de confirmar.
- **Administración de fuentes:** listar, editar nombre, eliminar. Al eliminar una fuente, sus artículos no favoritos se eliminan en cascada (servidor).
- **Límite de fuentes:** ilimitado.

### C. El Inbox

- **Flujo cronológico:** artículos no leídos de todas las fuentes, más reciente primero.
- **Persistencia indefinida en el inbox:** un artículo no leído permanece en el inbox sin importar su antigüedad — no hay archivado automático por tiempo (a diferencia del MVP original).
- **Estado de lectura:** al abrir un artículo se marca como leído y desaparece del inbox hacia "Leídos", de forma indefinida (no expira).
- **Sincronización on-demand:** pull-to-refresh dispara un fetch de feeds del lado del servidor (Edge Function) más una sincronización de estado. No hay fetch periódico en background ni notificaciones push — el contenido nuevo solo aparece cuando algún dispositivo de la cuenta hace pull-to-refresh o inicia sesión.
- **Onboarding (primer uso):** inbox vacío muestra CTA "+ Agregar tu primera fuente".
- **Búsqueda por pantalla:** Inbox, Leídos y Favoritos cada una ofrece su propia búsqueda (ícono de lupa) que filtra la lista ya cargada en esa pantalla por título, nombre de fuente o autor. No es full-text sobre el contenido del artículo, y no es una pantalla global separada.

### D. Experiencia de Lectura

- **Renderizado del artículo:** HTML del campo `<content>` del feed. Si está truncado o vacío (artículo de pago), botón para abrir la URL original en WebView embebido. Los iframes de video (YouTube) embebidos se manejan con tratamiento especial para reproducir correctamente dentro del WebView aislado.
- **Indicador de progreso de scroll:** referencia visual de la posición del usuario dentro de artículos largos.
- **Imagen destacada:** se muestra en las listas (Inbox, Leídos, Favoritos, Fuente) cuando el feed la provee. El servidor la extrae probando, en orden: Media RSS, enclosure de imagen, imagen de iTunes, primera imagen embebida en el HTML.
- **Gestión de Favoritos:** estrella para mover el artículo a una sección de archivo permanente. Favoritos nunca se eliminan automáticamente, ni siquiera al eliminar su fuente de origen.
- **Recuperación de estado de ruta:** abrir un artículo, fuente o resumen diario por URL/deep link no crashea la app aunque el estado de navegación en memoria no esté disponible — se resuelve por id.

### E. Resúmenes Diarios (IA)

- **Generación bajo demanda:** el usuario dispara la generación de un resumen del día a partir de los artículos publicados ese día en su inbox, agrupados por fuente, con voz editorial consistente (tono cercano, sin emojis, español latinoamericano neutro con tuteo) sin importar el tono original de cada fuente.
- **Un resumen por día:** regenerar sobrescribe el resumen existente de ese día; no crea duplicados.
- **Listado y detalle:** pantalla con todos los resúmenes históricos ordenados por fecha, cada uno navegable a su detalle con texto completo.

### F. Sincronización en la Nube

- **Bidireccional al abrir la app:** fuentes, resúmenes diarios y estado de usuario sobre artículos (leído/favorito/borrado) se sincronizan entre dispositivo y nube en una sola operación, subiendo cambios locales pendientes y bajando cambios remotos.
- **El contenido de los artículos es pull-only:** nace en el servidor vía fetch centralizado de feeds; el cliente nunca sube artículos nuevos ni su contenido.
- **Detección de cambios sin cola separada:** por comparación de `updatedAt` contra el cursor de última sincronización.
- **Borrados vía soft-delete:** propagados con `deletedAt`, borrado físico local solo tras confirmación de sync.
- **Resolución de conflictos:** last-write-wins por `updatedAt`, sin merge.
- **Push inmediato best-effort:** marcar leído o favorito intenta subir el cambio a Supabase de inmediato, sin bloquear la UI ni mostrar errores si falla (se repara en la próxima sync completa).
- **Sin tiempo real:** un cambio en un dispositivo no se refleja en otro dispositivo con la app abierta simultáneamente; requiere abrir la app, volver del background, o pull-to-refresh.
- **Aislamiento por usuario:** Row-Level Security en Postgres garantiza que cada usuario solo accede a sus propios registros.

### G. Almacenamiento y Privacidad

- **Persistencia local + nube:** los artículos, historial y favoritos residen en el dispositivo (Hive) y se respaldan/sincronizan en Supabase bajo la cuenta del usuario.
- **Cuenta requerida:** a diferencia del MVP original, ya no hay modo 100% local sin cuenta.
- **RLS como mecanismo de privacidad:** ningún usuario puede leer los datos de otro, ni siquiera con acceso directo a la tabla.

---

## 5. Reglas de Negocio Clave

| Regla | Detalle |
|-------|---------|
| **Artículo se marca leído al abrirlo** | Automático, `readAt=now`. No se revierte al reabrirlo. |
| **Sin archivado ni borrado automático por antigüedad** | A diferencia del MVP original, el inbox y "Leídos" no expiran artículos por tiempo. |
| **Favoritos permanentes** | Nunca se eliminan automáticamente, ni al borrar la fuente de origen. |
| **Borrado de fuente cascadea a sus artículos** | Excepto los favoritos, que sobreviven al borrado de su fuente. |
| **Orden del Inbox y de Leídos** | Siempre por `publishedAt` descendente. |
| **Dedupe de artículos** | Por constraint único `(source_id, article_url)` en base de datos, no solo lógica de aplicación. |
| **Contenido truncado** | `contentHtml == null \|\| contentHtml.length < 500` → se usa `excerpt` como fallback (incluye el prompt de resúmenes IA). |
| **Timeout por feed durante fetch** | 10 segundos. Un fallo no interrumpe las demás fuentes. |
| **Retención de items de email-to-RSS** | 30 días desde `received_at`, limpieza periódica automática. |

---

## 6. Manejo de Errores

| Escenario | Comportamiento esperado |
|-----------|------------------------|
| Sin conexión al sincronizar | Artículos ya descargados siguen disponibles; error visible pero no bloqueante. |
| Feed caído o timeout (>10s) | Error por fuente afectada; no interrumpe la sincronización de otras fuentes. |
| URL sin feed detectable ni por heurística | Mensaje: *"No pudimos detectar el feed automáticamente. Pega la URL exacta del feed RSS..."*, con opción de generar dirección de email-to-RSS. |
| Fuente ya existe | Verificado contra la feed URL final resuelta (no la URL cruda ingresada). |
| Artículo de pago sin contenido completo | Excerpt disponible + botón "Leer en el sitio original" (WebView). |
| OPML inválido o sin feeds | Mensajes específicos: *"El archivo no es un OPML válido"* / *"No se encontraron feeds en este archivo"*. |
| Falla la generación de un resumen IA | Estado de error distinguible del estado "sin artículos", con opción de reintentar. |
| Push inmediato de leído/favorito falla | Silencioso; se repara en la próxima sincronización completa. |
| Login cancelado (Google/Apple) | Permanece en login sin mostrar error, listo para reintentar. |

---

## 7. Diseño y Experiencia de Usuario (UX)

**Navegación principal (drawer + 5 tabs):**

1. **Inbox** — foco principal, artículos no leídos, pull-to-refresh, búsqueda por pantalla.
2. **Favoritos** — artículos guardados con estrella, búsqueda por pantalla.
3. **Leídos** — historial de artículos abiertos, búsqueda por pantalla.
4. **Fuentes** — agregar (URL o OPML), editar nombre, eliminar.
5. **Resúmenes** — listado y detalle de resúmenes diarios generados por IA.

**Lectura:** interfaz inmersiva, controles ocultos al hacer scroll hacia abajo, indicador de progreso de lectura.

---

## 8. Fuera del Alcance (explícito)

- Sincronización en tiempo real entre dispositivos (todo sync es on-demand, no hay websockets ni push).
- Fetch de artículos en background sin acción del usuario (sin cron de polling del lado del cliente).
- Notificaciones push de nuevos artículos.
- Búsqueda full-text sobre el contenido (`contentHtml`) de los artículos — solo título/fuente/autor.
- Carpetas o etiquetas para organizar fuentes.
- Soporte para formatos que no sean RSS 2.0 o Atom (JSON Feed queda fuera, aunque email-to-RSS cubre el caso de newsletters sin feed propio).
- Adaptar el tono de los resúmenes IA al estilo de cada fuente individual (la voz editorial es única para toda la app).

---

## 9. Consideraciones Técnicas

- **Offline-first para lectura:** los artículos ya descargados deben ser legibles sin conexión; solo la sincronización y el fetch de feeds requieren red.
- **Servidor como única fuente de fetch/parseo de RSS:** los clientes nunca parsean feeds ni generan ids de artículo; eso ocurre en Edge Functions, con dedupe garantizado a nivel de base de datos.
- **Contenido de pago:** la app no salta paywalls; el WebView embebido es el mecanismo de acceso para quienes ya tienen sesión/suscripción en su navegador.
- **Almacenamiento local:** Hive CE. **Almacenamiento remoto:** Postgres/Supabase con RLS por usuario.
- **Compliance de tiendas:** dado que la app requiere cuenta, debe ofrecer borrado de cuenta in-app antes de publicarse para público general (ver sección 4.A).
