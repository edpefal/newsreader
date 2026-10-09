## 1. Domain: resolver fuentes del resumen

- [x] 1.1 Crear `ResolveSummarySources` en `lib/features/summaries/domain/usecases/resolve_summary_sources.dart` (`sourceId` → `NewsSource` vía `SourceRepository.getSourceById`, descartando en silencio los ids inexistentes)
- [x] 1.2 Registrarlo en `lib/core/di/injection.dart` junto a `ResolveSummaryArticles`
- [x] 1.3 Test unitario del use case con `mocktail`: todas existen, algunas no existen, lista vacía

## 2. Textos (en/es/fr)

- [x] 2.1 Agregar `summaryDetailHeaderCount` (artículos y fuentes, con plural) en `app_en.arb`, `app_es.arb` (neutro con tuteo) y `app_fr.arb`
- [x] 2.2 Correr `flutter gen-l10n` y confirmar que el plural doble compila; si no, partir en dos claves (ver design.md, decisión 8)
- [x] 2.3 Agregar al `app_fr.arb` la traducción real y revisarla a mano para singular/plural

## 3. Presentación: widgets del detalle

- [x] 3.1 Extraer el parseo de bloques (`_parseBlocks`, `_ParsedBlock`) a `summary_block_parser.dart` sin cambiar su comportamiento
- [x] 3.2 Crear `summary_plain_block.dart` con el bloque sin tarjeta (título en negrita + texto) para resúmenes sin `sourceBlocks` o bloques sin match
- [x] 3.3 Crear `summary_article_row.dart`: miniatura 40×40 con `NetworkImageWidget`, fallback con ícono de documento, título a dos líneas, chevron; navega con `openDetailRoute` como el link actual
- [x] 3.4 Crear `summary_source_card.dart`: encabezado tintado con `SourceIcon` + nombre en negrita + contador de texto ("N artículos") con los artículos mostrados, párrafo y filas de artículo
- [x] 3.5 Crear `summary_header.dart`: avatares redondos apilados (máx. 4, "+N" si hay más) + "N artículos de M fuentes"; sin `sourceBlocks` muestra solo `summaryDetailArticleCount`
- [x] 3.6 Colores desde `ColorScheme`/`ReevoAccent`, sin hex fijos, válidos en claro y oscuro

## 4. Presentación: integrar en `SummaryDetailScreen`

- [x] 4.1 Recibir `ResolveSummarySources` por constructor; resolver fuentes y artículos con `Future.wait` y un solo `setState`
- [x] 4.2 Pintar cada bloque como tarjeta cuando empareja con un `SummarySourceBlock`, o como bloque plano en caso contrario; fuente no resuelta usa la inicial del `sourceName` guardado
- [x] 4.3 Envolver el contenido en un `ConstrainedBox` centrado de 680 de ancho máximo (constante local, sin importar de `reader`)
- [x] 4.4 Pasar `getIt<ResolveSummarySources>()` en los dos sitios de `lib/presentation/app/router.dart`
- [x] 4.5 Confirmar que el chrome (AppBar) y la selección persistente no cambian

## 5. Tests de widget

- [x] 5.1 Actualizar `summary_detail_screen_test.dart` con el mock de `ResolveSummarySources`
- [x] 5.2 Casos: tarjeta con ícono y conteo; fuente eliminada (inicial); artículo sin imagen; artículo eliminado omitido y reflejado en el contador; resumen sin `sourceBlocks`; bloque sin match; etiqueta `Fuente:`/`Source:`; cabecera con "N artículos de M fuentes"
- [x] 5.3 Mantener los tests existentes de navegación a artículo con las nuevas filas

## 6. Verificación

- [x] 6.1 `flutter analyze` sin warnings
- [x] 6.2 `flutter test` completo en verde, incluido `neutral_spanish_test.dart`
- [x] 6.3 Razonar el layout en ≥840dp (rail + split view + selección persistente) y por debajo del breakpoint
- [x] 6.4 Pruebas manuales en simulador/iPad por el usuario (claro, oscuro, resumen con y sin `sourceBlocks`, fuente eliminada)
