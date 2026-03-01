import 'package:flutter/widgets.dart';

abstract class HtmlContentRenderer extends StatelessWidget {
  final String htmlContent;
  final bool readerMode;

  const HtmlContentRenderer({
    super.key,
    required this.htmlContent,
    this.readerMode = false,
  });
}
