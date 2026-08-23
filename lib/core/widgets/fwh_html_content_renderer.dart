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

class FwhHtmlContentRenderer extends HtmlContentRenderer {
  const FwhHtmlContentRenderer({
    super.key,
    required super.htmlContent,
    required super.articleUrl,
    super.readerMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = readerMode
        ? theme.textTheme.bodyLarge?.copyWith(
            fontSize: 18,
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
