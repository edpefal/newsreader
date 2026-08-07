import 'package:flutter/widgets.dart';

abstract class HtmlContentRenderer extends StatelessWidget {
  final String htmlContent;
  final String articleUrl;
  final bool readerMode;

  const HtmlContentRenderer({
    super.key,
    required this.htmlContent,
    required this.articleUrl,
    this.readerMode = false,
  });
}
