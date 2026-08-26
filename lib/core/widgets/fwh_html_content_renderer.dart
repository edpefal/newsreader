import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:newsreader/core/widgets/html_content_renderer.dart';

final _styleAttrPattern = RegExp(
  r'''style\s*=\s*(["'])(.*?)\1''',
  caseSensitive: false,
  dotAll: true,
);
final _colorAttrPattern = RegExp(
  r'''\scolor\s*=\s*(["']).*?\1''',
  caseSensitive: false,
);

/// Quita el color de texto inline (`style="color:..."` y el atributo
/// deprecado `color`) de todos los elementos del HTML del artículo, para
/// que el contenido siempre use los colores del theme activo en vez del
/// branding propio del autor del newsletter -- algunos (ej. Android Weekly)
/// traen su propio azul de link o su propio gris de descripción, calibrados
/// contra un fondo blanco, con muy bajo contraste sobre el fondo oscuro de
/// dark mode. No toca `background-color` ni otras propiedades.
///
/// Trabaja con regex sobre el string crudo en vez de parsear y
/// re-serializar el HTML: un roundtrip de parseo puede reestructurar el
/// árbol de un documento mal formado (común en newsletters), lo que
/// rompió el layout de embeds de YouTube en la primera versión de este
/// fix. Regex quirúrgico sobre atributos puntuales no toca la estructura.
///
/// Público (sin `_`) y anotado `@visibleForTesting` por el mismo motivo que
/// [normalizeYoutubeUrl]: no está pensado para usarse fuera de este archivo.
@visibleForTesting
String stripInlineTextColors(String htmlContent) {
  final withoutStyleColors = htmlContent.replaceAllMapped(
    _styleAttrPattern,
    (match) {
      final quote = match.group(1)!;
      final declarations = match
          .group(2)!
          .split(';')
          .map((declaration) => declaration.trim())
          .where(
            (declaration) =>
                declaration.isNotEmpty &&
                !declaration.toLowerCase().startsWith('color'),
          )
          .toList();
      return declarations.isEmpty
          ? ''
          : 'style=$quote${declarations.join('; ')}$quote';
    },
  );
  return withoutStyleColors.replaceAll(_colorAttrPattern, '');
}

final _tableTagPattern = RegExp(r'<(/?)table\b', caseSensitive: false);

/// Máxima profundidad de anidamiento de `<table>` en [htmlContent].
///
/// El crash de `flutter_widget_from_html_core`
/// (`_TableRenderLayouter.step3MinIntrinsicWidth`, ver
/// openspec/changes/fix-newsletter-html-rendering/design.md) lo dispara la
/// profundidad de anidamiento en sí, no ninguna marca particular del email
/// que la contiene -- se confirmó con un segundo newsletter real (Daily
/// Stoic) que reproduce el mismo crash sin traer los namespaces VML/Office
/// que [looksLikeRawEmailHtml] originalmente usaba como única señal. Un
/// conteo lineal de aperturas/cierres de `<table` es suficiente: HTML de
/// blog/web real prácticamente nunca anida tablas más de 2-3 niveles,
/// mientras que el HTML de emails de marketing lo hace rutinariamente para
/// compatibilidad entre clientes de correo.
///
/// Público (sin `_`) y anotado `@visibleForTesting` por el mismo motivo que
/// [normalizeYoutubeUrl]: no está pensado para usarse fuera de este archivo.
@visibleForTesting
int maxTableNestingDepth(String htmlContent) {
  var depth = 0;
  var maxDepth = 0;
  for (final match in _tableTagPattern.allMatches(htmlContent)) {
    if (match.group(1) == '/') {
      if (depth > 0) depth--;
    } else {
      depth++;
      if (depth > maxDepth) maxDepth = depth;
    }
  }
  return maxDepth;
}

/// Umbral de anidamiento a partir del cual se asume que renderizar
/// [htmlContent] como widgets nativos dispararía el crash de
/// `_TableRenderLayouter.step3MinIntrinsicWidth`. El fixture real de
/// Morning Brew llega a 9 niveles; se elige 4 con margen conservador --
/// suficientemente por encima de cualquier tabla de datos real (que rara
/// vez anida) para no generar falsos positivos en HTML de blog/web.
const _deeplyNestedTableThreshold = 4;

/// Detecta si [htmlContent] es un email de marketing crudo (recibido tal
/// cual de un puente de email-a-RSS como kill-the-newsletter.com) en vez de
/// HTML pensado para la web -- por dos señales independientes:
///
/// 1. `xmlns:v="urn:schemas-microsoft-com:vml"` y
///    `xmlns:o="urn:schemas-microsoft-com:office:office"`, namespaces VML
///    que solo existen para sobrevivir al motor de renderizado de Word que
///    usa Outlook de escritorio -- ningún generador de HTML para web los
///    produce.
/// 2. Anidamiento de `<table>` por encima de [_deeplyNestedTableThreshold]
///    (ver [maxTableNestingDepth]) -- la causa estructural real del crash,
///    presente incluso en newsletters cuyo ESP no deja las marcas VML/Office
///    (ej. Daily Stoic).
///
/// En vez de intentar renderizar este contenido como widgets nativos, se
/// delega a [_RawEmailWebView], que usa un motor de browser real y no tiene
/// ese bug.
///
/// Público (sin `_`) y anotado `@visibleForTesting` por el mismo motivo que
/// [normalizeYoutubeUrl]: no está pensado para usarse fuera de este archivo.
@visibleForTesting
bool looksLikeRawEmailHtml(String htmlContent) =>
    htmlContent.contains('xmlns:v="urn:schemas-microsoft-com:vml"') ||
    htmlContent.contains('xmlns:o="urn:schemas-microsoft-com:office:office"') ||
    maxTableNestingDepth(htmlContent) >= _deeplyNestedTableThreshold;

const _youtubeHosts = {
  'youtube.com',
  'www.youtube.com',
  'youtube-nocookie.com',
  'www.youtube-nocookie.com',
  'youtu.be',
};

/// Normaliza la URL de un iframe embebido de YouTube para que se reproduzca
/// dentro de un WebView aislado sin el Error 153 ("Video player
/// configuration error"): quita el parámetro `origin` (no hay ningún dominio
/// real sirviendo ese WebView que lo justifique) y convierte los formatos
/// `/v/<id>` y `youtu.be/<id>` al formato `/embed/<id>`.
///
/// Retorna `null` si [url] no es reconocible como un embed de YouTube --
/// el llamador debe usar la URL original sin modificar en ese caso.
///
/// Público (sin `_`) y anotado `@visibleForTesting` únicamente para que los
/// tests puedan importarlo directamente; no está pensado para usarse fuera
/// de este archivo.
@visibleForTesting
String? normalizeYoutubeUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;

  final host = uri.host.toLowerCase();
  if (!_youtubeHosts.contains(host)) return null;

  String? videoId;
  if (host == 'youtu.be') {
    videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
  } else if (uri.pathSegments.length >= 2 &&
      (uri.pathSegments[0] == 'embed' || uri.pathSegments[0] == 'v')) {
    videoId = uri.pathSegments[1];
  }
  if (videoId == null || videoId.isEmpty) return null;

  final params = Map<String, String>.from(uri.queryParameters)
    ..remove('origin');
  return Uri.https(
    host == 'youtu.be' ? 'www.youtube.com' : host,
    '/embed/$videoId',
    params.isEmpty ? null : params,
  ).toString();
}

class _ArticleWidgetFactory extends WidgetFactory {
  final String articleUrl;

  _ArticleWidgetFactory({required this.articleUrl});

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
      return _YoutubeWebView(
        embedUrl: youtubeUrl,
        baseUrl: articleUrl,
        height: height,
        width: width,
      );
    }
    return super.buildWebView(
      meta,
      url,
      height: height,
      sandbox: sandbox,
      width: width,
    );
  }
}

/// WebView dedicado para embeds de YouTube: en vez de delegar en el `WebView`
/// por defecto de `fwfh_webview` (que carga la URL como navegación de nivel
/// superior aislada, sin ningún documento padre), carga un documento HTML
/// mínimo con un `<iframe>` real anidado apuntando al video, con
/// `referrerpolicy="strict-origin-when-cross-origin"` -- la corrección que
/// resolvió el mismo problema en FreshRSS
/// (https://github.com/FreshRSS/Extensions/pull/382). El `baseUrl` es la URL
/// real del artículo, para que el iframe tenga el mismo contexto de origen
/// que tendría si el usuario abriera la página original (como en "Ver en
/// navegador", que ya funciona).
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
      ..loadHtmlString(
        _wrapperHtml(widget.embedUrl),
        baseUrl: widget.baseUrl,
      );
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

final _headOpenTagPattern = RegExp(r'<head[^>]*>', caseSensitive: false);
final _viewportMetaPattern = RegExp(
  '''<meta[^>]+name\\s*=\\s*["']viewport["']''',
  caseSensitive: false,
);
const _viewportMetaTag =
    '<meta name="viewport" content="width=device-width, initial-scale=1.0">';

/// Asegura que [htmlContent] tenga una etiqueta `<meta name="viewport">`
/// apuntando a `width=device-width` antes de cargarlo en un `WebView`.
///
/// El HTML de un email de marketing casi nunca la trae -- fue diseñado para
/// un cliente de correo que ya controla su propio zoom/escalado, no para un
/// navegador móvil. Sin ella, WebKit asume un viewport virtual de escritorio
/// (~980px de ancho) y escala toda la página hacia abajo para que quepa en
/// el ancho real de la pantalla, produciendo el efecto de contenido "alejado"
/// con texto diminuto y márgenes vacíos a los costados -- reportado en un
/// artículo real de Daily Stoic cuyo ESP no incluye esta marca (a diferencia
/// de Morning Brew, que sí la trae y por eso no mostró el problema).
///
/// No hace nada si [htmlContent] ya trae su propia etiqueta viewport, para
/// no pisar un valor que el autor del email haya elegido deliberadamente.
///
/// Público (sin `_`) y anotado `@visibleForTesting` por el mismo motivo que
/// [normalizeYoutubeUrl]: no está pensado para usarse fuera de este archivo.
@visibleForTesting
String ensureViewportMeta(String htmlContent) {
  if (_viewportMetaPattern.hasMatch(htmlContent)) return htmlContent;

  final headMatch = _headOpenTagPattern.firstMatch(htmlContent);
  if (headMatch == null) return '$_viewportMetaTag$htmlContent';

  return htmlContent.replaceRange(
    headMatch.end,
    headMatch.end,
    _viewportMetaTag,
  );
}

const _resizeObserverScript = '''
(function() {
  function reportHeight() {
    ReevoContentHeight.postMessage(document.documentElement.scrollHeight.toString());
  }
  new ResizeObserver(reportHeight).observe(document.body);
  reportHeight();
})();
''';

/// Renderiza HTML de email crudo (ver [looksLikeRawEmailHtml]) en un
/// `WebView` en vez de intentar convertirlo a widgets nativos -- un motor
/// de browser real resuelve tablas anidadas arbitrarias porque es
/// exactamente su trabajo. No se le aplica [stripInlineTextColors] ni
/// ningún strip de color: ese HTML fue diseñado con su propia paleta de
/// marca para un fondo claro, y forzar los colores del theme sobre un email
/// armado con cuidado alrededor de ese fondo produciría peor resultado, no
/// mejor. Se acepta que estos artículos se lean con su diseño original,
/// igual que en Gmail o Apple Mail.
///
/// `WebViewWidget` necesita una altura acotada -- no puede crecer con su
/// contenido como un widget nativo -- así que la altura real se mide desde
/// JS (`document.documentElement.scrollHeight`, vía un `ResizeObserver` para
/// capturar reflows tardíos por imágenes) y se usa para dimensionar este
/// widget dentro del `SingleChildScrollView` de `ReaderScreen`. Mientras la
/// altura es desconocida se muestra un `CircularProgressIndicator` superpuesto,
/// igual que el que ya muestra `HtmlWidget` por defecto para el resto del
/// contenido.
///
/// La navegación dentro del WebView se bloquea después de la carga inicial
/// (`onNavigationRequest`): el contenido viene de un remitente no confiable
/// y no hay una barra de navegación ni botón "atrás" en esta pantalla, así
/// que un tap en un link (ej. "Unsubscribe") no debe secuestrar la pantalla
/// navegando el WebView embebido a otra página.
class _RawEmailWebView extends StatefulWidget {
  final String htmlContent;
  final String articleUrl;

  const _RawEmailWebView({
    required this.htmlContent,
    required this.articleUrl,
  });

  @override
  State<_RawEmailWebView> createState() => _RawEmailWebViewState();
}

class _RawEmailWebViewState extends State<_RawEmailWebView> {
  late final WebViewController _controller;
  double? _contentHeight;
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'ReevoContentHeight',
        onMessageReceived: (message) {
          final height = double.tryParse(message.message);
          if (height != null && height > 0 && mounted) {
            setState(() => _contentHeight = height);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _initialLoadDone = true;
            _controller.runJavaScript(_resizeObserverScript);
          },
          onNavigationRequest: (request) => _initialLoadDone
              ? NavigationDecision.prevent
              : NavigationDecision.navigate,
        ),
      )
      ..loadHtmlString(
        ensureViewportMeta(widget.htmlContent),
        baseUrl: widget.articleUrl,
      );
  }

  @override
  Widget build(BuildContext context) {
    // El email conserva su propio fondo claro (ver comentario de la clase),
    // lo que choca visualmente contra el dark theme de la app. En vez de
    // forzarle colores (rompería el contraste calibrado por su autor), se
    // lo enmarca como una tarjeta -- mismo tratamiento (radio 12,
    // `outlineVariant`, sin sombra) que usan las tarjetas de
    // `add_source_screen.dart` -- para que el fondo blanco se lea como el
    // diseño original del artículo en vez de un choque de estilos.
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: SizedBox(
        height: _contentHeight ?? 200,
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_contentHeight == null)
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}

class FwhHtmlContentRenderer extends HtmlContentRenderer {
  const FwhHtmlContentRenderer({
    super.key,
    required super.htmlContent,
    required super.articleUrl,
    super.readerMode,
  });

  @override
  Widget build(BuildContext context) {
    if (looksLikeRawEmailHtml(htmlContent)) {
      return _RawEmailWebView(htmlContent: htmlContent, articleUrl: articleUrl);
    }

    final theme = Theme.of(context);
    final textStyle = readerMode
        ? theme.textTheme.bodyLarge?.copyWith(
            fontSize: 20,
            height: 1.7,
            letterSpacing: 0.2,
          )
        : theme.textTheme.bodyMedium;

    return HtmlWidget(
      stripInlineTextColors(htmlContent),
      textStyle: textStyle,
      renderMode: RenderMode.column,
      factoryBuilder: () => _ArticleWidgetFactory(articleUrl: articleUrl),
    );
  }
}
