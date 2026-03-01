# Historias de Usuario: Newsletter Hub (MVP)

> Formato: **Como** [usuario], **quiero** [acción], **para** [beneficio].
> Cada historia incluye criterios de aceptación (CA) y notas técnicas cuando aplica.

---

## Épica 1 — Gestión de Fuentes

### US-01 · Agregar una fuente por URL

**Como** lector, **quiero** agregar un newsletter pegando su URL de feed, **para** empezar a recibir sus artículos en la app.

**Criterios de aceptación:**
- [ ] Hay un campo de texto donde puedo pegar o escribir una URL.
- [ ] Al confirmar, la app valida que la URL devuelve un feed RSS 2.0 o Atom válido.
- [ ] Si la validación es exitosa, la fuente aparece en la lista de fuentes activas.
- [ ] Si la URL no es un feed válido, se muestra el mensaje: *"No se encontró un feed válido en esta URL."*
- [ ] Si no hay conexión a internet al intentar agregar, se muestra un mensaje de error apropiado.
- [ ] No se puede agregar la misma URL dos veces (deduplicación).

**Notas técnicas:**
- Soportar RSS 2.0 y Atom como formatos válidos.
- Timeout de conexión: 10 segundos.

---

### US-02 · Identificación automática de metadatos de la fuente

**Como** lector, **quiero** que la app extraiga automáticamente el nombre, autor e ícono del newsletter al agregarlo, **para** no tener que ingresarlos manualmente.

**Criterios de aceptación:**
- [ ] Tras validar la URL, la app extrae el título del feed como nombre del newsletter.
- [ ] La app extrae el autor del feed cuando está disponible.
- [ ] La app extrae y descarga el ícono/favicon de la fuente cuando está disponible.
- [ ] Si algún metadato no está disponible en el feed, se usa un valor por defecto (ícono genérico, "Autor desconocido").
- [ ] El nombre extraído es editable antes de confirmar o desde la pantalla de fuentes.

---

### US-03 · Ver lista de fuentes activas

**Como** lector, **quiero** ver todas las fuentes a las que estoy suscrito en una sola pantalla, **para** tener una vista clara de mi biblioteca de newsletters.

**Criterios de aceptación:**
- [ ] La pantalla muestra todas las fuentes activas con nombre e ícono.
- [ ] Si no hay fuentes agregadas, se muestra un estado vacío con un botón para agregar la primera.
- [ ] La lista es scrolleable si hay muchas fuentes.

---

### US-04 · Editar el nombre de una fuente

**Como** lector, **quiero** poder cambiar el nombre de una fuente, **para** identificarla con un nombre más claro o personal.

**Criterios de aceptación:**
- [ ] Desde la pantalla de fuentes, puedo acceder a la opción de editar el nombre de cualquier fuente.
- [ ] El campo muestra el nombre actual como valor inicial.
- [ ] El nuevo nombre se guarda y se refleja en toda la app (Inbox, Favoritos, Archivo).
- [ ] No se permite guardar un nombre vacío.

---

### US-05 · Eliminar una fuente

**Como** lector, **quiero** eliminar una fuente de mis suscripciones, **para** dejar de recibir sus artículos.

**Criterios de aceptación:**
- [ ] Desde la pantalla de fuentes, puedo eliminar una fuente.
- [ ] Se muestra un diálogo de confirmación antes de eliminar: *"¿Eliminar [nombre]? También se eliminarán sus artículos no guardados como favoritos."*
- [ ] Al confirmar, la fuente desaparece de la lista.
- [ ] Los artículos de esa fuente se eliminan del Inbox y del Archivo.
- [ ] Los artículos de esa fuente marcados como favoritos **no** se eliminan.

---

## Épica 2 — Inbox y Sincronización

### US-06 · Ver artículos no leídos en el Inbox

**Como** lector, **quiero** ver todos mis artículos pendientes en una lista unificada, **para** tener un único lugar desde donde empezar a leer.

**Criterios de aceptación:**
- [ ] El Inbox muestra únicamente artículos no leídos de todas las fuentes activas.
- [ ] Los artículos están ordenados de más reciente a más antiguo.
- [ ] Cada ítem muestra: título, nombre de la fuente, ícono de la fuente y fecha de publicación.
- [ ] El contador de artículos no leídos es visible en la navegación.

---

### US-07 · Primer uso: Inbox vacío (Onboarding)

**Como** nuevo usuario, **quiero** entender qué hacer cuando abro la app por primera vez, **para** comenzar a usarla sin confusión.

**Criterios de aceptación:**
- [ ] Si el Inbox está vacío y no hay fuentes agregadas, se muestra un estado vacío con un mensaje descriptivo de la app.
- [ ] Se muestra un botón de llamada a la acción: *"+ Agregar tu primer newsletter"*.
- [ ] El botón lleva directamente a la pantalla para agregar una fuente.
- [ ] Si hay fuentes pero no hay artículos nuevos, se muestra un mensaje: *"Estás al día. Desliza para actualizar."*

---

### US-08 · Sincronizar manualmente nuevos artículos

**Como** lector, **quiero** actualizar mi Inbox deslizando hacia abajo, **para** obtener los artículos más recientes de mis fuentes cuando yo lo decida.

**Criterios de aceptación:**
- [ ] Al deslizar hacia abajo en el Inbox, se inicia la sincronización de todas las fuentes activas.
- [ ] Se muestra un indicador de progreso durante la sincronización.
- [ ] Los artículos nuevos aparecen en el Inbox al completar la sincronización.
- [ ] Si una fuente falla (timeout o error), se muestra un aviso por esa fuente específica sin interrumpir las demás.
- [ ] Si no hay conexión a internet, se muestra: *"Sin conexión. Los artículos descargados siguen disponibles."*
- [ ] Si no hay artículos nuevos, la sincronización termina silenciosamente.

**Notas técnicas:**
- Timeout por fuente: 10 segundos.
- Las fuentes se sincronizan en paralelo.

---

### US-09 · Marcar artículo como leído al abrirlo

**Como** lector, **quiero** que un artículo se marque automáticamente como leído al abrirlo, **para** que mi Inbox refleje solo lo que realmente no he visto.

**Criterios de aceptación:**
- [ ] Al abrir un artículo desde el Inbox, se marca automáticamente como "Leído".
- [ ] El artículo desaparece del Inbox al volver a la lista.
- [ ] El contador de no leídos se actualiza.
- [ ] El artículo permanece accesible si está marcado como favorito.

---

## Épica 3 — Experiencia de Lectura

### US-10 · Leer el contenido del artículo (Vista Original)

**Como** lector, **quiero** ver el contenido completo de un artículo dentro de la app, **para** leerlo sin salir a un navegador externo.

**Criterios de aceptación:**
- [ ] Al abrir un artículo, se muestra el contenido HTML del campo `<content>` del feed RSS.
- [ ] El contenido respeta el formato original: imágenes, negritas, listas, enlaces.
- [ ] Los enlaces dentro del artículo son funcionales y se abren en el WebView embebido.
- [ ] La pantalla de lectura oculta la barra de navegación principal al hacer scroll hacia abajo.
- [ ] La barra de navegación reaparece al hacer scroll hacia arriba.

---

### US-11 · Acceder a contenido de pago via WebView (fallback)

**Como** lector suscriptor de un newsletter de pago, **quiero** poder abrir el artículo completo en un navegador embebido, **para** leerlo con mi sesión activa cuando el RSS solo muestra un extracto.

**Criterios de aceptación:**
- [ ] Si el contenido RSS está vacío o es un extracto (menos de X caracteres sin cierre de párrafos), se muestra el extracto disponible más un botón: *"Leer artículo completo"*.
- [ ] Al pulsar el botón, se abre un WebView embebido con la URL original del artículo.
- [ ] El WebView tiene un botón para cerrarlo y volver a la pantalla de lectura.
- [ ] El WebView no guarda historial ni cookies entre sesiones (privacidad).

**Notas técnicas:**
- Umbral de "contenido truncado": a definir en implementación (ej. ausencia de cierre de etiquetas o longitud < 500 chars).

---

### US-12 · Activar el Modo Reader

**Como** lector, **quiero** activar un modo de lectura limpio, **para** reducir distracciones visuales y leer con mayor comodidad.

**Criterios de aceptación:**
- [ ] Hay un interruptor o botón visible en la pantalla de lectura para activar/desactivar el Modo Reader.
- [ ] En Modo Reader: tipografía estandarizada, márgenes amplios, sin imágenes decorativas, fondo claro u oscuro según el sistema.
- [ ] La preferencia de Modo Reader persiste entre artículos (si lo activo, sigue activo al abrir el siguiente).
- [ ] En Modo Reader se mantienen los elementos esenciales: título, autor, fecha y cuerpo del texto.

---

## Épica 4 — Favoritos y Archivo

### US-13 · Marcar un artículo como favorito

**Como** lector, **quiero** marcar un artículo con una estrella, **para** guardarlo permanentemente y poder releerlo después.

**Criterios de aceptación:**
- [ ] Hay un ícono de estrella accesible desde la pantalla de lectura.
- [ ] Al marcar como favorito, el artículo se mueve a la sección de Favoritos.
- [ ] El artículo favorito nunca se elimina automáticamente por la regla de 30 días.
- [ ] Puedo marcar como favorito desde el Inbox (sin abrir el artículo), mediante un gesto o acción rápida.

---

### US-14 · Desmarcar un artículo como favorito

**Como** lector, **quiero** poder quitar la estrella a un artículo guardado, **para** mantener mi sección de favoritos relevante.

**Criterios de aceptación:**
- [ ] Desde la pantalla de lectura o desde la lista de Favoritos, puedo quitar la estrella.
- [ ] Al desmarcar, el artículo desaparece de la sección de Favoritos.
- [ ] Si el artículo ya estaba marcado como leído, queda sujeto a la regla de limpieza de 30 días.

---

### US-15 · Ver la sección de Favoritos

**Como** lector, **quiero** tener una sección dedicada a mis artículos guardados, **para** acceder a ellos en cualquier momento como biblioteca personal.

**Criterios de aceptación:**
- [ ] La sección de Favoritos es accesible desde la navegación principal.
- [ ] Los artículos se muestran ordenados por fecha en que fueron marcados como favoritos (más reciente primero).
- [ ] Cada ítem muestra: título, fuente, ícono y fecha de guardado.
- [ ] Si no hay favoritos, se muestra un estado vacío con mensaje descriptivo.
- [ ] Al abrir un artículo desde Favoritos, no se modifica su estado de leído/no leído.

---

### US-16 · Ver artículos archivados

**Como** lector, **quiero** acceder a los artículos no leídos que ya no aparecen en el Inbox por tener más de 30 días, **para** decidir si los leo o los descarto.

**Criterios de aceptación:**
- [ ] Existe una sección de Archivo accesible desde la app (puede estar dentro de Favoritos o en navegación propia).
- [ ] El Archivo muestra artículos no leídos con más de 30 días, ordenados de más reciente a más antiguo.
- [ ] Puedo abrir y leer cualquier artículo del Archivo; al hacerlo se marca como leído y desaparece del Archivo.
- [ ] Puedo marcar artículos del Archivo como favoritos.
- [ ] Si el Archivo está vacío, se muestra un estado vacío.

---

## Épica 5 — Limpieza y Mantenimiento Automático

### US-17 · Limpieza automática de artículos leídos

**Como** usuario, **quiero** que la app elimine automáticamente los artículos leídos con más de 30 días, **para** que el dispositivo no acumule contenido innecesario.

**Criterios de aceptación:**
- [ ] Al iniciar la app, se ejecuta silenciosamente una limpieza de artículos leídos con más de 30 días desde su fecha de publicación.
- [ ] Los artículos marcados como favoritos **no** se eliminan, sin importar su antigüedad.
- [ ] La limpieza no interrumpe el uso de la app (proceso en background).
- [ ] No se muestra ninguna notificación al usuario durante la limpieza.

---

### US-18 · Archivo automático de artículos no leídos

**Como** usuario, **quiero** que los artículos no leídos con más de 30 días salgan del Inbox automáticamente, **para** mantener el Inbox relevante sin perder el contenido.

**Criterios de aceptación:**
- [ ] Los artículos no leídos con más de 30 días desde su publicación desaparecen del Inbox y pasan al Archivo.
- [ ] El proceso ocurre al iniciar la app, de forma silenciosa.
- [ ] Los artículos archivados siguen siendo accesibles desde la sección de Archivo.
- [ ] Los artículos favoritos no se ven afectados por esta regla.

---

## Resumen por Épica

| Épica | Historias | Prioridad |
|-------|-----------|-----------|
| E1 · Gestión de Fuentes | US-01 a US-05 | Alta |
| E2 · Inbox y Sincronización | US-06 a US-09 | Alta |
| E3 · Experiencia de Lectura | US-10 a US-12 | Alta |
| E4 · Favoritos y Archivo | US-13 a US-16 | Media |
| E5 · Limpieza Automática | US-17 a US-18 | Media |

**Total: 18 historias de usuario**
