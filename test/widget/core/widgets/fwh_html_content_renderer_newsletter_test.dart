import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'package:newsreader/core/widgets/fwh_html_content_renderer.dart';

// `WebViewController`/`WebViewWidget` requieren un `WebViewPlatform.instance`
// real (backed por un canal de plataforma nativo), que no existe en el
// entorno de `flutter_test`. Estos fakes son el patrón que el propio paquete
// `webview_flutter` usa en sus tests (ver `webview_widget_test.dart` en el
// pub cache): implementan solo los métodos que `_RawEmailWebView` llama
// (`setJavaScriptMode`, `addJavaScriptChannel`, `setPlatformNavigationDelegate`,
// `loadHtmlString`, `setOnPageFinished`, `setOnNavigationRequest`), dejando
// el resto con el `UnimplementedError` por defecto de la clase abstracta ya
// que nunca se invocan en este test.
class _FakeWebViewPlatform extends WebViewPlatform {
  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) =>
      _FakePlatformWebViewController(params);

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) =>
      _FakePlatformNavigationDelegate(params);

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) =>
      _FakePlatformWebViewWidget(params);
}

class _FakePlatformWebViewController extends PlatformWebViewController {
  _FakePlatformWebViewController(super.params) : super.implementation();

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> addJavaScriptChannel(
    JavaScriptChannelParams javaScriptChannelParams,
  ) async {}

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {}

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {}
}

class _FakePlatformNavigationDelegate extends PlatformNavigationDelegate {
  _FakePlatformNavigationDelegate(super.params) : super.implementation();

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {}

  @override
  Future<void> setOnNavigationRequest(
    NavigationRequestCallback onNavigationRequest,
  ) async {}
}

class _FakePlatformWebViewWidget extends PlatformWebViewWidget {
  _FakePlatformWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// Fixture capturado directamente del `contentHtml` real de un artículo de
// The Morning Brew (ver openspec/changes/fix-newsletter-html-rendering):
// email de marketing de ~94 KB con hasta 9 niveles de tablas anidadas, y con
// las marcas VML/Office de Outlook (`xmlns:v`, `xmlns:o`) que confirman que
// es un email crudo (ver `looksLikeRawEmailHtml` en
// `fwh_html_content_renderer.dart`).
//
// Investigación: un reporte de "el lector queda en blanco" para este tipo
// de contentHtml, no truncado. Se confirmó con eventos reales de Sentry
// (`reevo-dev`, ver design.md) que `flutter_widget_from_html_core` envuelve
// todo `<table>` en `ValignBaselineContainer` y que su algoritmo de ancho
// intrínseco (`_TableRenderLayouter.step3MinIntrinsicWidth`) consulta el
// tamaño de RenderObjects hijos que Flutter todavía no terminó de
// layoutear cuando hay tablas anidadas profundas -- un `AssertionError`
// fatal que corrompe el layout de toda la pantalla del lector.
//
// Se probaron y revirtieron dos fixes (aplanar tablas a `<div>`; actualizar
// `flutter_widget_from_html` a 0.17.2) -- ver design.md, ninguno resolvía el
// crash sin introducir una regresión peor. El fix vigente evita el
// algoritmo de tabla de `fwfh_core` por completo para este tipo de
// contenido: en vez de convertirlo a widgets nativos, `looksLikeRawEmailHtml`
// lo detecta y `FwhHtmlContentRenderer` lo delega a un `WebView`
// (`_RawEmailWebView`), que usa un motor de browser real.
final _newsletterHtml = File(
  'test/fixtures/newsletter_nested_tables.html',
).readAsStringSync();

Widget _buildSubject(String html) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: FwhHtmlContentRenderer(
            htmlContent: html,
            articleUrl: 'https://www.morningbrew.com',
          ),
        ),
      ),
    );

void main() {
  setUpAll(() {
    WebViewPlatform.instance = _FakeWebViewPlatform();
  });

  testWidgets(
    'confirma que el fixture real dispara looksLikeRawEmailHtml',
    (tester) async {
      expect(looksLikeRawEmailHtml(_newsletterHtml), isTrue);
    },
  );

  testWidgets(
    'renderiza el fixture real vía WebView (no HtmlWidget) sin lanzar '
    'ninguna excepción de rendering',
    (tester) async {
      await tester.pumpWidget(_buildSubject(_newsletterHtml));
      await tester.pump();

      // Si `looksLikeRawEmailHtml` fallara y el fixture cayera en el camino
      // nativo, HtmlWidget intentaría convertir las tablas anidadas a
      // widgets y reproduciría el crash de Sentry (ver design.md). Confirmar
      // que el árbol usa WebViewWidget y no HtmlWidget es la señal de que
      // el fix está activo para este contenido.
      expect(find.byType(HtmlWidget), findsNothing);
      expect(find.byType(WebViewWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'no afecta HTML normal (sin marcas de email crudo): sigue usando '
    'HtmlWidget',
    (tester) async {
      await tester.pumpWidget(
        _buildSubject('<p>Un párrafo normal de un blog.</p>'),
      );
      await tester.pump();

      expect(find.byType(HtmlWidget), findsOneWidget);
      expect(find.byType(WebViewWidget), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
