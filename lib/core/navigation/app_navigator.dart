import 'package:flutter/widgets.dart';

enum ArticleSource { inbox, favorites, archive }

abstract class AppNavigator {
  void goToArticle(
    BuildContext context,
    String articleId, {
    required ArticleSource source,
  });

  void goToAddSource(BuildContext context);
  void goToArchive(BuildContext context);
  void pop(BuildContext context);
}
