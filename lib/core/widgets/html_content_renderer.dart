import 'package:flutter/widgets.dart';

import 'package:newsreader/core/navigation/external_link_launcher.dart';

abstract class HtmlContentRenderer extends StatelessWidget {
  final String htmlContent;
  final String articleUrl;
  final bool readerMode;
  final ExternalLinkLauncher externalLinkLauncher;

  const HtmlContentRenderer({
    super.key,
    required this.htmlContent,
    required this.articleUrl,
    required this.externalLinkLauncher,
    this.readerMode = false,
  });
}
