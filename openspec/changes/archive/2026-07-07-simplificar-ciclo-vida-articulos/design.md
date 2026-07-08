## Context

El modelo actual tiene dos flags en `ArticleModel`: `isRead` e `isArchived`. El flag `isArchived` fue diseñado para que el mantenimiento automático moviera artículos no leídos > 30 días fuera del inbox, preservándolos sin eliminarlos. Sin embargo, al renombrar la pantalla de "Archivados" a "Leídos", el comportamiento quedó desalineado: "Leídos" muestra artículos con `isArchived=true && isRead=false` (artículos que el usuario nunca abrió), mientras que los que sí leyó (`isRead=true`) no aparecen ahí.

El usuario quiere un modelo mental simple: inbox para no leídos, "Leídos" para lo que abrió, sin expiración automática de ningún tipo.

## Goals / Non-Goals

**Goals:**
- "Leídos" muestra exactamente los artículos que el usuario abrió
- Los artículos no leídos permanecen en inbox indefinidamente
- Eliminar toda lógica de limpieza automática (RunMaintenance)
- Migrar datos existentes: eliminar artículos con `isArchived=true` que son residuos del comportamiento anterior

**Non-Goals:**
- Eliminar el campo `isArchived` del modelo Hive (requeriría migración de schema con riesgo de corrupción; se deja como campo zombie)
- Agregar limpieza manual por parte del usuario (fuera de scope)
- Modificar la lógica de favoritos

## Decisions

### 1. Eliminar RunMaintenance completamente

**Decisión:** Borrar el use case, su registro en DI, y la llamada en `main.dart`.

**Alternativa considerada:** Dejarlo vacío (no-op). Descartado — código muerto que confunde.

### 2. Migración one-time de artículos isArchived=true existentes

**Decisión:** Al quitar el filtro `!isArchived` del inbox, los artículos auto-archivados resurgirían. Se eliminarán en una migración que corre una sola vez en `main.dart` antes de `runApp`. Son artículos viejos no leídos que el usuario nunca quiso abrir — eliminarlos es correcto.

```
// En main.dart, reemplaza RunMaintenance.execute():
await getIt<MigrateArchivedArticles>().execute();

// MigrateArchivedArticles:
// Elimina todos los artículos con isArchived=true
```

**Alternativa considerada:** Dejar `!isArchived` en el inbox query para ocultarlos. Descartado — acumularían data basura en Hive para siempre y el campo nunca se volvería a leer.

### 3. Query de "Leídos" → isRead=true, orden por readAt desc

**Decisión:** `getArchive()` retorna artículos con `isRead=true`, ordenados por `readAt` descendente (más reciente arriba).

`readAt` puede ser null en artículos marcados antes de que existiera el campo — en ese caso se usa `publishedAt` como fallback.

### 4. Query de inbox → !isRead (sin !isArchived)

**Decisión:** Simplificar a un solo filtro. Después de la migración, ningún artículo tendrá `isArchived=true`, por lo que el filtro es redundante.

### 5. Métodos de repositorio obsoletos

`getReadArticlesOlderThan` y `getUnreadNonArchivedArticlesOlderThan` se eliminan de la interfaz, implementación, y datasource.

## Risks / Trade-offs

- **[Riesgo] La migración elimina artículos que el usuario podría haber querido leer** → Los artículos auto-archivados estaban ocultos al usuario desde hace >30 días, es improbable que los buscara activamente. Aceptable.

- **[Riesgo] Sin limpieza automática, Hive crece indefinidamente** → El inbox solo tiene artículos del último sync; los leídos se acumulan pero son texto plano liviano. Aceptable en el corto plazo.

- **[Campo zombie] `isArchived` en ArticleModel nunca vuelve a ser `true`** → No causa bugs, solo ocupa un campo Hive. Se puede eliminar en un cambio futuro con migración de schema.

## Migration Plan

1. `MigrateArchivedArticles` use case elimina todos los registros con `isArchived=true` al startup
2. El resto de los cambios son en queries y código — no afectan el schema de Hive
3. No hay rollback necesario (la migración es idempotente: si ya no hay archivados, no hace nada)
