import 'package:flutter/widgets.dart';

abstract class ArticleWebView extends StatefulWidget {
  final String url;
  final VoidCallback? onClose;

  const ArticleWebView({
    super.key,
    required this.url,
    this.onClose,
  });
}
