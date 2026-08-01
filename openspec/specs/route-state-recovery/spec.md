# Capability: Route State Recovery

## Purpose

Evita que la app crashee al abrir una pantalla de detalle (artículo, fuente, resumen diario) cuando el estado de navegación en memoria no está disponible, resolviendo el dato necesario a partir del identificador presente en la URL.

---

## Requirements

### Requirement: Recuperación de datos de ruta por identificador
El sistema SHALL resolver el objeto de dominio necesario para renderizar las rutas `/article/:id`, `/sources/:id` y `/summaries/:date` a partir del identificador de la URL cuando el estado de navegación en memoria no traiga ese objeto (o traiga un valor de un tipo distinto al esperado), en vez de fallar con un error de tipo. Mientras se resuelve, el sistema SHALL mostrar un indicador de carga.

#### Scenario: Navegación normal, sin necesidad de recuperación
- **WHEN** el usuario toca un artículo (o fuente, o resumen) desde una lista y la navegación incluye el objeto completo
- **THEN** la pantalla de detalle se muestra de inmediato, sin ningún indicador de carga intermedio

#### Scenario: La app se restaura sin el estado de navegación en memoria
- **WHEN** el proceso de la app fue recreado (por ejemplo, Android lo mató en background) y la navegación se restaura en una ruta de detalle sin el objeto en memoria
- **THEN** el sistema busca el dato correspondiente por su identificador y muestra la pantalla de detalle normalmente, sin crashear

#### Scenario: El identificador no corresponde a ningún registro existente
- **WHEN** el sistema intenta recuperar por identificador y no encuentra ningún artículo, fuente o resumen con ese id/fecha (por ejemplo, fue borrado)
- **THEN** el sistema redirige al Inbox en vez de mostrar un error o una pantalla en blanco
