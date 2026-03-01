# PRD: Newsletter Hub (MVP)

---

## 1. Visión del Producto

Crear un espacio de lectura dedicado que rescate los boletines informativos del desorden del correo electrónico. La aplicación permite centralizar suscripciones de plataformas como Substack o Ghost en una interfaz limpia, priorizando la concentración y el hábito de lectura sin distracciones.

---

## 2. Plataforma Objetivo

- **iOS y Android** (ambas desde el MVP)
- Versiones mínimas de SO: iOS 16+ / Android 8.0 (API 26)+

---

## 3. Objetivos del MVP

- **Descongestionar el Email:** Mover el consumo de contenido editorial fuera de la bandeja de entrada.
- **Lectura de Alto Valor:** Ofrecer una interfaz optimizada para textos largos.
- **Simplicidad Extrema:** Funcionamiento local, sin cuentas y sin fricción de configuración.

**Criterio de éxito del MVP:** El usuario puede agregar una fuente, leer un artículo completo y marcarlo como leído sin errores ni fricción.

---

## 4. Requisitos Funcionales

### A. Gestión de Suscripciones

- **Registro Manual:** El usuario añade nuevas fuentes pegando directamente la URL del feed (ej. `autor.substack.com/feed`).
- **Identificación Automática:** Tras validar la URL, la app extrae el nombre del boletín, el autor y el ícono representativo de la fuente.
- **Administración de Fuentes:** Pantalla para listar, editar el nombre o eliminar suscripciones activas.
- **Límite de fuentes:** Ilimitado; el almacenamiento del dispositivo es el único límite.

### B. El Inbox (Sistema Inbox Zero)

- **Flujo Cronológico:** Lista centralizada que muestra únicamente los artículos no leídos de todas las fuentes, ordenados del más reciente al más antiguo.
- **Estado de Lectura:** Al abrir un artículo, este se marca automáticamente como "Leído" y desaparece de la vista principal del Inbox.
- **Sincronización Manual:** Función de "deslizar para actualizar" (pull-to-refresh) para buscar nuevas publicaciones. No hay fetch en background ni notificaciones push.
- **Onboarding (primer uso):** Si el Inbox está vacío, se muestra un estado vacío con mensaje descriptivo y un botón de llamada a la acción: *"+ Agregar tu primer newsletter"*.

### C. Experiencia de Lectura

**Visualización Dual:**

| Modo | Comportamiento |
|------|---------------|
| **Vista Original** | Renderiza el HTML del campo `<content>` del feed RSS. Si el contenido está truncado o vacío (artículo de pago), muestra un botón para abrir la URL del artículo en un WebView embebido. |
| **Modo Reader** | Interruptor que activa una interfaz limpia: tipografía estandarizada, sin imágenes decorativas, contraste optimizado para lectura prolongada. |

**Gestión de Favoritos:** El usuario puede marcar artículos con una estrella para moverlos a una sección de archivo permanente accesible en cualquier momento.

### D. Almacenamiento y Privacidad

- **Persistencia Local:** Toda la información (artículos, historial, favoritos) reside exclusivamente en el dispositivo.
- **Privacidad Total:** No se requiere registro, correo electrónico ni perfil en la nube.

---

## 5. Reglas de Negocio

| Regla | Detalle |
|-------|---------|
| **Validación de feeds** | Solo se aceptan URLs que devuelvan una estructura XML válida (RSS 2.0 o Atom). Si la validación falla, se muestra un mensaje de error claro al usuario. |
| **Limpieza automática** | Los artículos marcados como **leídos** con más de 30 días de antigüedad se eliminan automáticamente para liberar espacio, **salvo** que estén marcados como favoritos. |
| **Archivo de no leídos** | Los artículos **no leídos** con más de 30 días no se eliminan; se mueven a una sección de archivo separada y dejan de aparecer en el Inbox principal. |
| **Favoritos permanentes** | Los artículos marcados con estrella nunca se eliminan automáticamente. |
| **Orden del Inbox** | Siempre de más reciente a más antiguo para mantener la relevancia informativa. |

---

## 6. Manejo de Errores

| Escenario | Comportamiento esperado |
|-----------|------------------------|
| Sin conexión a internet al sincronizar | Mostrar mensaje "Sin conexión. Los artículos descargados siguen disponibles." |
| Feed caído o timeout (>10 seg) | Mostrar error por fuente afectada; no interrumpir la sincronización de otras fuentes. |
| URL válida pero sin estructura RSS/Atom | Mostrar error al intentar agregar la fuente: *"No se encontró un feed válido en esta URL."* |
| Feed que cambia su URL | La fuente aparece como "sin actualizaciones". El usuario puede editar la URL manualmente. |
| Artículo de pago sin contenido completo en el RSS | Mostrar el excerpt disponible + botón *"Leer en el sitio original"* que abre el WebView. |

---

## 7. Diseño y Experiencia de Usuario (UX)

**Flujo de Navegación Principal (4 pantallas):**

1. **Inbox:** Foco principal. Lista de artículos no leídos. Pull-to-refresh para actualizar.
2. **Lectura:** Interfaz inmersiva. Los controles de navegación se ocultan al hacer scroll hacia abajo y reaparecen al hacer scroll hacia arriba.
3. **Favoritos:** Acceso a artículos guardados con estrella, ordenados por fecha de guardado.
4. **Fuentes:** Gestión de newsletters suscritos (agregar, editar nombre, eliminar).

---

## 8. Fuera del Alcance (MVP)

Las siguientes funcionalidades quedan **explícitamente excluidas** del MVP:

- Búsqueda de artículos (en Inbox o Favoritos)
- Importar/exportar suscripciones en formato OPML
- Sincronización en la nube o entre dispositivos
- Notificaciones push de nuevos artículos
- Fetch de artículos en background (sin abrir la app)
- Soporte para formatos que no sean RSS 2.0 o Atom (ej. JSON Feed)
- Carpetas o etiquetas para organizar fuentes

---

## 9. Consideraciones Técnicas

- **Offline-first:** Los artículos ya descargados deben ser legibles sin conexión.
- **Contenido de pago:** La app no puede saltarse paywalls. El flujo con WebView embebido es el mecanismo de acceso para quienes tengan suscripción activa en su navegador.
- **Parseo de feeds:** Soportar RSS 2.0 y Atom como mínimo.
- **Almacenamiento:** Usar la base de datos local del dispositivo (SQLite o equivalente). No usar almacenamiento en red.
