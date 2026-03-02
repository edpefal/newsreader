# Progress: Newsletter Hub (MVP)

> Una historia se marca ✅ cuando: criterios de aceptación cumplidos + `flutter analyze` sin warnings + tests pasan.

---

## Sprint 0 — Infraestructura Base

| Tarea | Estado |
|-------|--------|
| Estructura de carpetas (`core/`, `domain/`, `data/`, `presentation/`) | ✅ |
| Entidades de dominio (`NewsSource`, `Article`) | ✅ |
| Interfaces de repositorios (`SourceRepository`, `ArticleRepository`) | ✅ |
| Modelos Hive + TypeAdapters (`NewsSourceModel`, `ArticleModel`) | ✅ |
| Inicialización de Hive en `main.dart` | ✅ |
| Interfaces de abstracciones en `core/` (`HttpClient`, `FeedParser`, `IdGenerator`, `AppNavigator`, widgets) | ✅ |
| Implementaciones concretas de abstracciones | ✅ |
| `get_it` configurado en `core/di/injection.dart` | ✅ |
| Shell de navegación con `go_router` (rutas base) | ✅ |
| Tema Material 3 + `ThemeCubit` (light/dark toggle) | ✅ |
| Bottom navigation (Inbox · Favoritos · Fuentes) | ✅ |

---

## Épica 1 — Gestión de Fuentes

| Historia | Estado | Tests |
|----------|--------|-------|
| US-01 · Agregar fuente por URL | ✅ | ✅ |
| US-02 · Identificación automática de metadatos | ✅ | ✅ |
| US-03 · Ver lista de fuentes activas | ✅ | ✅ |
| US-04 · Editar nombre de fuente | ⬜ | ⬜ |
| US-05 · Eliminar fuente | ⬜ | ⬜ |

---

## Épica 2 — Inbox y Sincronización

| Historia | Estado | Tests |
|----------|--------|-------|
| US-06 · Ver artículos no leídos en el Inbox | ⬜ | ⬜ |
| US-07 · Primer uso: Inbox vacío (Onboarding) | ⬜ | ⬜ |
| US-08 · Sincronizar manualmente (pull-to-refresh) | ⬜ | ⬜ |
| US-09 · Marcar artículo como leído al abrirlo | ⬜ | ⬜ |

---

## Épica 3 — Experiencia de Lectura

| Historia | Estado | Tests |
|----------|--------|-------|
| US-10 · Leer contenido del artículo (Vista Original) | ⬜ | ⬜ |
| US-11 · Acceder a contenido de pago via WebView | ⬜ | ⬜ |
| US-12 · Activar Modo Reader | ⬜ | ⬜ |

---

## Épica 4 — Favoritos y Archivo

| Historia | Estado | Tests |
|----------|--------|-------|
| US-13 · Marcar artículo como favorito | ⬜ | ⬜ |
| US-14 · Desmarcar favorito | ⬜ | ⬜ |
| US-15 · Ver sección de Favoritos | ⬜ | ⬜ |
| US-16 · Ver artículos archivados | ⬜ | ⬜ |

---

## Épica 5 — Limpieza Automática

| Historia | Estado | Tests |
|----------|--------|-------|
| US-17 · Limpieza automática de artículos leídos | ⬜ | ⬜ |
| US-18 · Archivo automático de artículos no leídos | ⬜ | ⬜ |

---

## Leyenda

| Símbolo | Significado |
|---------|-------------|
| ⬜ | Pendiente |
| 🔄 | En progreso |
| ✅ | Completo (criterios + analyze + tests) |
| 🚧 | Bloqueado |
