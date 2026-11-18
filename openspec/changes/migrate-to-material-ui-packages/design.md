## Context

El CI está fijado en Flutter 3.44.6 desde el PR #81 para evitar que los 86 avisos de obsolescencia rompan `flutter analyze`. Los imports antiguos siguen compilando. Ver `proposal.md` para el motivo. Fuentes consultadas: la guía oficial de migración de Flutter ("Migrate to standalone material_ui and cupertino_ui packages") y el anuncio de Flutter 3.47. El nombre exacto de la regla de `dart fix` salió de una fuente secundaria y no está verificado.

## Goals / Non-Goals

**Goals:**
- Dejar `lib/` y `test/` sin avisos `deprecated_member_use` con Flutter 3.47 o posterior.
- Que local, CI y Codemagic usen la misma versión de Flutter, fijada explícitamente.

**Non-Goals:**
- Rediseñar la interfaz o adoptar APIs nuevas de `material_ui`.
- Cambiar de versión mayor otras dependencias sin necesidad.
- Soporte de macOS (change posterior `add-macos-support`), aunque comparte el requisito de plataformas.

## Decisions

### D1. Hacerlo cuando se decida subir de Flutter, no antes
Con el CI fijado no hay nada roto. Migrar solo tiene sentido junto con la subida de Flutter, que además pide nuevas versiones de plugins y del SDK de iOS. Conviene hacerlo antes de `add-macos-support`, para no migrar dos veces los imports.
*Alternativa descartada:* silenciar `deprecated_member_use` en `analysis_options.yaml`: esconde obsolescencias reales.

### D2. Migración automática en un solo PR
Aplicar la herramienta oficial a todo el repo y verificar con `flutter analyze` y `flutter test`. Son 84 archivos de un cambio mecánico (el import), así que un PR único es más fácil de revisar que varios parciales.

### D3. Decidir el mínimo de iOS con datos
Antes de subir a iOS 15, medir en PostHog (`$os_version`, propiedades de dispositivo) cuántos usuarios activos siguen en iOS 14, siguiendo el criterio de `CLAUDE.md` para cambios que afectan a clientes ya publicados. Si hay usuarios, decidir conscientemente si se acepta perderlos.

### D4. Fijar la versión también en Codemagic
Hoy Codemagic usa `flutter: stable`: una Flutter nueva podría cambiar las builds de TestFlight sin aviso. Fijarla evita sorpresas y mantiene reproducible lo que se prueba.

## Risks / Trade-offs

- [Un plugin no soporta Flutter 3.47 todavía] → revisar `flutter pub outdated` y las notas de cada plugin antes de subir; si alguno bloquea, esperar.
- [Cambios de la reorganización de los page transition builders entre 3.44 y 3.47] → buscar en el código transiciones personalizadas y probarlas.
- [Regresiones visuales sutiles] → las pruebas manuales en iPhone y en iPad las hace el usuario (ver `CLAUDE.md`); `flutter test` cubre los widgets.
- [Perder usuarios con iOS 14] → D3.
- [La herramienta automática deja imports sin migrar o genera conflictos con el formato] → ejecutar `dart format` solo sobre los archivos tocados y revisar el diff.

## Migration Plan

1. Medir iOS 14 en PostHog y decidir. Revisar notas de 3.47 y compatibilidad de plugins.
2. Subir Flutter local, ajustar `pubspec.yaml`, correr `flutter pub get` y regenerar pods.
3. Aplicar la migración de imports y la de localización.
4. Subir el mínimo de iOS a 15.0 si se acepta.
5. Cambiar el pin de `ci.yml` y fijar `codemagic.yaml`.
6. `flutter analyze`, `flutter test`, build de TestFlight y pruebas manuales.

*Rollback:* volver a Flutter 3.44.6 y revertir el PR; no hay cambios de datos ni de servidor.

## Open Questions

- ¿Cuántos usuarios activos siguen en iOS 14?
- ¿Cuál es el nombre exacto de la regla de `dart fix` y si requiere flags?
- ¿Algún plugin del proyecto impide subir a Flutter 3.47 hoy?
