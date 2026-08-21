## 1. Traducción de `app_fr.arb`

- [x] 1.1 Traducir claves `common*`, `appTitle` (queda igual, es la marca) e `inbox*`
- [x] 1.2 Traducir claves `reader*`, `favorites*`, `archive*`
- [x] 1.3 Traducir claves `sources*` (la sección más grande: pantalla de agregar, detalle, importar OPML, diálogos de editar/eliminar)
- [x] 1.4 Traducir claves `summaries*`, `login*`, `account*`
- [x] 1.5 Traducir claves `nav*` (Drawer/AppBar compartido) y las últimas sueltas (`commonDaysAgoShort`, `commonNoSearchResults`, `webViewOriginalArticle`) — `navInbox` se mantuvo "Inbox" en los 3 idiomas, igual que en inglés/español
- [x] 1.6 Correr `flutter gen-l10n` y confirmar que compila

## 2. Test de completitud

- [x] 2.1 Crear test que compara `app_fr.arb` contra `app_en.arb` clave por clave y falla si algún valor quedó idéntico, con lista explícita de excepciones (`appTitle`) — el barrido inicial encontró 2 excepciones legítimas más (`navSources`, `summaryListArticleCount`: cognados reales, "Sources"/"article(s)" se escriben igual en francés), agregadas a la lista
- [x] 2.2 Correr el test y confirmar que pasa contra el `app_fr.arb` ya traducido

## 3. Actualizar tests existentes

- [x] 3.1 Actualizar `test/widget/core/utils/localized_date_formatter_test.dart`: la aserción que hoy espera `frResult == 'Today'` pasa a esperar el string francés real (`"Aujourd'hui"`); la aserción `isNot(equals(esResult))` para mes abreviado no compara contra francés, no necesitaba cambios

## 4. Verificación final

- [x] 4.1 Correr `flutter analyze` y resolver cualquier warning
- [x] 4.2 Correr `flutter test` (unit + widget) y confirmar que todo pasa — 393 tests, todos en verde
- [x] 4.3 Probar manualmente en simulador/dispositivo con el idioma configurado en francés — confirmado en Inbox (título "Inbox" como se decidió, separadores de fecha "19 août"/"18 août" en francés, sufijo "2 j"/"3 j"). No se pudo abrir el Drawer para capturar visualmente Favoris/Lus/Sources/Résumés: no hay acceso de accesibilidad en este entorno para simular el tap del ícono de hamburguesa (mismo límite ya documentado en el Change 1). El contenido del Drawer no depende de lógica nueva — son las mismas claves `nav*` ya usadas y cubiertas por el test de completitud, así que se confía en esa cobertura en vez de la captura visual
- [x] 4.4 Nota para el usuario: si hay oportunidad de que un hablante nativo de francés revise `app_fr.arb`, vale la pena — el test de completitud garantiza que no quedó nada en inglés, no que la traducción sea perfectamente idiomática
