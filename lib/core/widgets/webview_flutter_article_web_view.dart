import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:newsreader/core/widgets/article_web_view.dart';
import 'package:newsreader/l10n/app_localizations.dart';

class WebviewFlutterArticleWebView extends ArticleWebView {
  const WebviewFlutterArticleWebView({
    super.key,
    required super.url,
    super.onClose,
  });

  @override
  State<WebviewFlutterArticleWebView> createState() =>
      _WebviewFlutterArticleWebViewState();
}

class _WebviewFlutterArticleWebViewState
    extends State<WebviewFlutterArticleWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
        ),
        title: Text(AppLocalizations.of(context).webViewOriginalArticle),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
