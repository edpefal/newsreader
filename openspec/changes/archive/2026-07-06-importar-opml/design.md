## Context

El proyecto sigue Clean Architecture feature-based. La regla central es que ninguna librería de infraestructura se importa en `domain/` o `presentation/` directamente — siempre se usa una interfaz en `core/`. `AddSource` ya encapsula la lógica de validación de un feed individual (HTTP fetch + parse + deduplicación). `ImportOpml` puede reutilizarla directamente sin duplicar lógica.

OPML es XML simple con elementos `<outline type="rss" xmlUrl="..."/>`. Puede tener anidamiento (carpetas), pero lo relevante es solo el atributo `xmlUrl` independientemente del nivel.

## Goals / Non-Goals

**Goals:**
- Parsear archivos OPML extrayendo todas las `xmlUrl` sin importar nivel de anidamiento
- Validar cada feed extraído usando exactamente la misma lógica que `AddSource`
- Mostrar preview con estado por feed (nuevo, duplicado, error) antes de confirmar
- Respetar la regla de abstracciones: el parser OPML vive en `core/opml/`, accesible vía interfaz
- No romper el flujo existente de `AddSourceScreen`

**Non-Goals:**
- Preservar la estructura de carpetas del OPML (se aplana a lista plana)
- Exportar OPML (solo importación)
- Validación en background o fuera de la pantalla de preview
- Soporte de versiones OPML distintas a 1.0/2.0 con estructura no estándar

## Decisions

### 1. Abstracción OPMLParser en `core/opml/`

**Decisión:** Crear interfaz `OPMLParser` con implementación `XmlOpmlParser`, siguiendo el mismo patrón que `FeedParser` / `WebfeedFeedParser`.

**Alternativa descartada:** Parsear el XML directamente en el use case `ImportOpml`. Se descarta porque viola la regla de abstracciones del proyecto — el use case no debe depender de una librería concreta (`xml`).

**Interfaz:**
```
abstract class OPMLParser {
  List<String> parse(String xmlContent); // retorna lista de xmlUrl
}
```

### 2. `ImportOpml` reutiliza `AddSource` internamente

**Decisión:** `ImportOpml` recibe una instancia de `AddSource` y llama `execute()` por cada URL. No accede a repositorios directamente.

**Alternativa descartada:** Llamar a `SourceRepository` directamente para insertar en batch. Se descarta porque saltaría la validación HTTP y el fetch de metadata que hace `AddSource`, produciendo fuentes sin nombre ni ícono.

**Resultado del use case:**
```
class ImportOpmlResult {
  final List<NewsSource> imported;
  final List<String> skippedDuplicates;  // urls ya existentes
  final List<String> failed;             // urls que lanzaron error
}
```

### 3. Validación antes del preview (no progresiva)

**Decisión:** `ImportOpmlCubit` valida todos los feeds antes de emitir el estado de preview. El usuario ve un spinner y luego la lista completa.

**Alternativa descartada:** Mostrar la lista inmediatamente con items en estado "cargando" que se actualizan de forma progresiva. Se descarta por complejidad de estado innecesaria para el MVP — el usuario typical importa decenas de feeds, no cientos.

**Concurrencia:** Las validaciones se ejecutan en paralelo con `Future.wait()` para reducir el tiempo total de espera.

### 4. Punto de entrada en `AddSourceScreen`

**Decisión:** Agregar un `TextButton` secundario "Importar desde OPML" debajo del botón principal "Agregar". El file picker se lanza desde `AddSourceScreen` y, si el usuario selecciona un archivo, se navega a `/sources/import-opml` pasando el contenido XML como `extra`.

**Alternativa descartada:** Botón en `SourcesScreen` (AppBar o FAB). Se descarta porque `AddSourceScreen` es el contexto natural — es donde el usuario está pensando en agregar fuentes.

### 5. Paquetes nuevos

| Paquete | Uso | Alternativa descartada |
|---|---|---|
| `file_picker` | Selector de archivos del OS, filtrado por `.opml`/`.xml` | `image_picker` (no soporta archivos genéricos) |
| `xml` | Parseo del XML OPML | Parser manual con regex (frágil ante variaciones de formato) |

### 6. Nueva ruta

```
/sources/import-opml   →   ImportOpmlScreen
```

La pantalla recibe el contenido XML del archivo como `state.extra as String`, lo que evita escribir el archivo a disco temporalmente.

## Risks / Trade-offs

- **Tiempo de validación con muchos feeds** → Mitigation: `Future.wait()` paraleliza las llamadas; se muestra spinner con mensaje informativo. Si hay >50 feeds, el tiempo puede ser notable en redes lentas — aceptable para MVP.
- **Archivo OPML malformado o con encoding no-UTF8** → Mitigation: el `OPMLParser` captura excepciones de parseo y lanza `ParseException`, que `ImportOpmlCubit` convierte en estado de error con mensaje claro.
- **Memoria con archivos OPML muy grandes** → Mitigation: OPML es texto XML, raramente supera unos KB. No es un riesgo real para este caso de uso.
- **`file_picker` en Android requiere permisos de almacenamiento en API <33** → Mitigation: `file_picker` maneja esto internamente desde su versión 5+. Verificar que `minSdkVersion` (ya en 21 según `pubspec.yaml`) esté cubierto.

## Open Questions

- ¿Se debe mostrar el conteo de feeds encontrados en el spinner ("Validando 12 feeds…")? No bloquea la implementación — se puede agregar como polish posterior.
