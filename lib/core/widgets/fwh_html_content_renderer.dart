import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import 'package:newsreader/core/widgets/html_content_renderer.dart';

class FwhHtmlContentRenderer extends HtmlContentRenderer {
  const FwhHtmlContentRenderer({
    super.key,
    required super.htmlContent,
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
      htmlContent,
      textStyle: textStyle,
      renderMode: RenderMode.column,
    );
  }
}
