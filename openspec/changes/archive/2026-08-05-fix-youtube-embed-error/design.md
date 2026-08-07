## Context

`flutter_widget_from_html` (vía el paquete transitivo `fwfh_webview`) renderiza cada `<iframe>` del HTML de un artículo como un `WebView` nativo aislado (`webview_flutter`), cargando el `src` del iframe tal cual con `loadRequest` — una navegación de nivel superior, no un iframe real dentro de una página. El punto de extensión es `WebViewFactory.buildWebView(meta, url, ...)`, un método sobreescribible de un mixin que se combina con `WidgetFactory` (la clase base que `HtmlWidget` acepta vía su parámetro `factoryBuilder`).

El HTML de un artículo llega intacto desde el feed RSS original (`supabase/functions/sync-feeds/index.ts` no toca `content_html` salvo para extraer la imagen destacada) hasta el cliente. Cuando ese HTML trae un iframe de YouTube con un parámetro `origin` que apunta al dominio del sitio de origen (típico en el código de embed que generan los CMS de podcasts/newsletters), YouTube detecta que el contexto real de carga (un WebView nativo sin ningún dominio "real" sirviendo la página) no coincide con ese `origin`, y devuelve el Error 153 en vez de reproducir el video.

Ver proposal.md - Why, para la causa completa, y el hallazgo de que `reader_screen.dart` bypassea la abstracción `HtmlContentRenderer` existente.

**Actualización tras verificación manual (primera iteración del fix)**: normalizar la URL (quitar `origin`, convertir `/v/` y `youtu.be` a `/embed/`) no fue suficiente — el Error 153 persistió incluso con la URL limpia. La pista clave: el botón "Ver en navegador" del lector (`WebviewFlutterArticleWebView`, que carga la página real completa del artículo como navegación de nivel superior) **sí** reproduce el mismo video sin error. La diferencia entre ambos casos no es la URL en sí, sino el contexto HTTP de la carga:

- "Ver en navegador": el WebView navega a la página real del artículo. Esa página, al cargarse, contiene el `<iframe>` de YouTube como un iframe genuino *anidado dentro de un documento con origen real* — la carga del iframe lleva un header `Referer` natural (la propia página) que YouTube puede validar.
- Modo lector (HTML inline): `fwfh_webview` extrae el `src` del iframe y lo carga como una **navegación de nivel superior aislada** (`WebViewController.loadRequest(Uri.parse(url))`, sin ningún header `Referer`) — no hay ningún documento padre real. Quitar el parámetro `origin` de la URL no cambia este hecho: sigue sin haber un `Referer` HTTP que YouTube pueda validar, y aparentemente esa ausencia (no solo el parámetro `origin`) es señal suficiente para que YouTube rechace la reproducción.

Esto descarta la Decisión 1 original (delegar en el `WebView` por defecto de `fwfh_webview` tras limpiar la URL) como solución completa — se mantiene la normalización de URL (sigue siendo necesaria para los formatos `/v/` y `youtu.be`, y buena higiene quitar `origin`), pero se reemplaza el mecanismo de carga: en vez de delegar en `super.buildWebView` (que no permite pasar headers), se construye un `WebView` propio con `webview_flutter` que sí puede mandar un header `Referer` explícito en la petición HTTP inicial.

**Actualización tras verificación manual (segunda iteración)**: mandar `Referer: https://www.youtube.com/` como header HTTP en una navegación de nivel superior (`loadRequest`) no solo no resolvió el error, sino que lo cambió a uno peor ("This video is unavailable — Error code: 152-4"), consistente con que YouTube detecta y rechaza referrers falsos/auto-referenciales de forma más agresiva que la ausencia total de referrer.

Investigación externa (búsqueda web) encontró un caso idéntico ya resuelto: el PR [FreshRSS/Extensions#382](https://github.com/FreshRSS/Extensions/pull/382) — un lector RSS, mismo problema exacto (Error 153 en videos de YouTube embebidos en artículos) — se resolvió agregando el atributo `referrerpolicy="strict-origin-when-cross-origin"` al `<iframe>` real, **no** mandando un header `Referer` inventado por fuera. Esto confirma que el mecanismo correcto es recrear un iframe genuino anidado dentro de un documento HTML (que el navegador/WebView puede aplicar `referrerpolicy` correctamente), no forzar un header en una navegación de nivel superior aislada — que es estructuralmente distinto a un iframe real y no soporta esa política.

## Goals / Non-Goals

**Goals:**
- Que los iframes de YouTube embebidos en el HTML de un artículo se reproduzcan sin el Error 153, sin tocar el pipeline de sync (`sync-feeds`) ni el HTML guardado en Supabase.
- Centralizar la única lógica que conoce `flutter_widget_from_html` en `core/widgets/fwh_html_content_renderer.dart`, corrigiendo el import directo en `reader_screen.dart` que viola la regla de abstracciones de CLAUDE.md.

**Non-Goals:**
- No se resuelve el caso general de "cualquier iframe roto" — el fix es específico para el dominio de YouTube, que es el caso reportado y el único confirmado como roto.
- No se cambia el HTML almacenado en Supabase ni se agrega lógica de reescritura de HTML en `sync-feeds` — la normalización ocurre solo en el cliente, al momento de renderizar.
- No se introduce una preferencia de usuario para desactivar los embeds de video ni ningún control de reproducción custom (autoplay, calidad, etc.) — se mantiene el comportamiento por defecto del embed de YouTube, solo se corrige el error de carga.

## Decisions

### Decisión 1: Normalizar la URL en un `WidgetFactory` personalizado, no en el HTML antes de renderizar

Se crea una clase privada `_ArticleWidgetFactory extends WidgetFactory` dentro de `fwh_html_content_renderer.dart`, que sobreescribe `buildWebView(meta, url, ...)`. Para iframes de YouTube (`normalizeYoutubeUrl(url)` retorna no-`null`), en vez de delegar en `super.buildWebView` (que no permite mandar headers HTTP), construye directamente el widget `_YoutubeWebView` propio (ver Decisión 4). Para cualquier otro iframe, delega en `super.buildWebView` sin cambios, igual que antes:

```dart
@override
Widget? buildWebView(
  BuildTree meta,
  String url, {
  double? height,
  Iterable<String>? sandbox,
  double? width,
}) {
  final youtubeUrl = normalizeYoutubeUrl(url);
  if (youtubeUrl != null) {
    return _YoutubeWebView(url: youtubeUrl, height: height, width: width);
  }
  return super.buildWebView(meta, url, height: height, sandbox: sandbox, width: width);
}
```

**Alternativa considerada**: hacer una pasada de regex/parsing sobre el `contentHtml` completo antes de pasarlo a `HtmlWidget`, buscando y reescribiendo `<iframe src="...">` de YouTube como texto. Se descartó porque manipular HTML arbitrario con regex es frágil (atributos en cualquier orden, comillas simples/dobles, HTML mal formado), mientras que interceptar en `buildWebView` recibe la URL ya extraída y resuelta por el parser HTML real de `flutter_widget_from_html_core`, sin tener que re-parsear nada.

### Decisión 2: Función de normalización pura, basada en `Uri`, no en regex sobre el string completo

```dart
String? _normalizeYoutubeUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;

  final host = uri.host.toLowerCase();
  final isYoutube = host == 'youtube.com' ||
      host == 'www.youtube.com' ||
      host == 'youtube-nocookie.com' ||
      host == 'www.youtube-nocookie.com' ||
      host == 'youtu.be';
  if (!isYoutube) return null;

  String? videoId;
  if (host == 'youtu.be') {
    videoId = uri.pathSegments.firstOrNull;
  } else if (uri.pathSegments.length >= 2 &&
      (uri.pathSegments[0] == 'embed' || uri.pathSegments[0] == 'v')) {
    videoId = uri.pathSegments[1];
  }
  if (videoId == null || videoId.isEmpty) return null;

  final params = Map<String, String>.from(uri.queryParameters)..remove('origin');
  return Uri.https(
    host == 'youtu.be' ? 'www.youtube.com' : host,
    '/embed/$videoId',
    params.isEmpty ? null : params,
  ).toString();
}
```

Retorna `null` cuando la URL no es reconocible como embed de YouTube (dominio distinto, o no se pudo extraer un `videoId`), en cuyo caso el llamador usa la URL original sin modificar — nunca rompe un iframe que no sea de YouTube.

**Por qué quitar `origin` en vez de reescribirlo con un valor "correcto"**: no existe un dominio real que sirva el WebView (es una navegación nativa aislada), así que no hay ningún valor de `origin` verdadero para poner. YouTube solo aplica esa validación cuando el parámetro está presente; omitirlo evita el chequeo por completo sin necesitar inventar un valor.

### Decisión 3: Migrar `reader_screen.dart` a `FwhHtmlContentRenderer`, con `readerMode` sin especificar

`FwhHtmlContentRenderer` ya soporta un parámetro `readerMode` (hoy sin ningún caller en toda la app, por lo tanto siempre `false` por default) que cambia el `textStyle` a uno más grande para lectura. Se usa el default (`false`), preservando exactamente el `textStyle` (`theme.textTheme.bodyMedium`) que `reader_screen.dart` usa hoy — este change no introduce ningún cambio visual más allá del fix de YouTube.

```dart
// antes
HtmlWidget(article.contentHtml!, textStyle: theme.textTheme.bodyMedium)

// después
FwhHtmlContentRenderer(htmlContent: article.contentHtml!)
```

El test existente `test/widget/features/reader/reader_screen_test.dart` busca `find.byType(HtmlWidget)` — sigue encontrándolo, ahora un nivel más adentro del árbol (dentro de `FwhHtmlContentRenderer`), sin necesitar cambios.

### Decisión 4 (revisada, tercera iteración): `_YoutubeWebView` carga un documento HTML con un iframe real anidado, vía `loadHtmlString`

Se abandona el enfoque de header `Referer` (no funcionó, empeoró el error). En su lugar, `_YoutubeWebView` construye un documento HTML mínimo con un `<iframe>` real (con el atributo `referrerpolicy="strict-origin-when-cross-origin"`, la corrección confirmada por el caso externo de FreshRSS) y lo carga vía `WebViewController.loadHtmlString(html, baseUrl: articleUrl)`:

```dart
class _YoutubeWebView extends StatefulWidget {
  final String embedUrl;
  final String baseUrl;
  final double? height;
  final double? width;

  const _YoutubeWebView({
    required this.embedUrl,
    required this.baseUrl,
    this.height,
    this.width,
  });

  @override
  State<_YoutubeWebView> createState() => _YoutubeWebViewState();
}

class _YoutubeWebViewState extends State<_YoutubeWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(_wrapperHtml(widget.embedUrl), baseUrl: widget.baseUrl);
  }

  @override
  Widget build(BuildContext context) {
    final dimensOk = widget.height != null &&
        widget.height! > 0 &&
        widget.width != null &&
        widget.width! > 0;
    return AspectRatio(
      aspectRatio: dimensOk ? widget.width! / widget.height! : 16 / 9,
      child: WebViewWidget(controller: _controller),
    );
  }
}

String _wrapperHtml(String embedUrl) => '''
<!DOCTYPE html>
<html><head>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>html,body{margin:0;padding:0;background:transparent;}
iframe{position:absolute;top:0;left:0;width:100%;height:100%;border:0;}</style>
</head><body>
<iframe src="$embedUrl"
  referrerpolicy="strict-origin-when-cross-origin"
  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
  allowfullscreen></iframe>
</body></html>
''';
```

**Por qué `baseUrl: articleUrl` (la URL real del artículo) y no un dominio inventado**: recrea exactamente el contexto de "Ver en navegador" (que ya confirmamos que funciona) — el documento que contiene el iframe tiene, para efectos de `referrerpolicy`, el mismo origen real que tendría si el usuario hubiera abierto el artículo original. No hace falta inventar ni falsificar ningún dominio.

Esto requiere pasar la URL del artículo hasta `_ArticleWidgetFactory`: `FwhHtmlContentRenderer` gana un parámetro nuevo `articleUrl` (`String`, requerido), que `reader_screen.dart` puebla con `article.articleUrl` (ya existe en la entidad `Article`, `core/domain/entities/article.dart:14`).

**Por qué esto vive en `fwh_html_content_renderer.dart` y no reutiliza `WebviewFlutterArticleWebView`**: esa clase es una abstracción pensada para mostrar una página completa a pantalla completa (con su propio `Scaffold`/`AppBar`), no un widget embebido del tamaño del iframe dentro del flujo de texto del artículo. Compartir código entre ambos agregaría una abstracción prematura para dos usos con forma distinta; ambos ya importan `webview_flutter` directamente, cumpliendo la regla de abstracciones de CLAUDE.md (`webview_flutter` se abstrae vía `ArticleWebView`, pero ese widget es para el caso de "página completa"; este uso es un caso distinto y acotado, ya dentro de `core/widgets/`).

**Iteraciones descartadas** (documentadas para no repetirlas): (1) delegar en el `WebView` por defecto de `fwfh_webview` solo con la URL limpia — no alcanza porque sigue siendo una navegación de nivel superior sin ningún contexto de referrer; (2) mandar un header `Referer` inventado en esa misma navegación de nivel superior — empeoró el error, YouTube parece detectar referrers auto-referenciales/falsos como señal negativa.

## Risks / Trade-offs

- **[Riesgo] YouTube podría cambiar en el futuro qué parámetros disparan el Error 153, o agregar validaciones nuevas que este fix no cubra** → Mitigación: es un riesgo inherente a integrar con una plataforma externa que no controlamos; el fix cubre la causa confirmada hoy (parámetro `origin` desalineado) y los formatos de URL conocidos (`/embed/`, `/v/`, `youtu.be`). Si aparece un caso nuevo, es un ajuste acotado a `_normalizeYoutubeUrl`, no un rediseño.
- **[Riesgo] Un artículo con múltiples iframes de YouTube en formatos distintos o mal formados** → Mitigación: la función retorna `null` (URL sin tocar) ante cualquier caso no reconocido, en vez de lanzar una excepción — el peor caso es que ese iframe específico siga mostrando el error que ya mostraba, sin afectar al resto del artículo ni a otros iframes.
- **[Riesgo] El header `Referer` explícito (Decisión 4) tampoco alcance a resolver el Error 153 para algún video/caso particular** → Mitigación: es la causa más probable según la evidencia recolectada (funciona con navegación completa, no con navegación aislada sin `Referer`), pero no hay forma de confirmarlo sin una segunda verificación manual — si tampoco alcanza, la alternativa considerada en Decisión 4 (envolver en HTML con `loadHtmlString`) o reemplazar el embed inline por una miniatura clickeable que abra YouTube externamente quedan como próximos pasos, ya evaluados y descartados por ahora a favor del enfoque más simple.
