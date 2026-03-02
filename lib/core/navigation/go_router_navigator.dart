import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:newsreader/core/navigation/app_navigator.dart';

class GoRouterNavigator implements AppNavigator {
  const GoRouterNavigator();

  @override
  void goToArticle(
    BuildContext context,
    String articleId, {
    required ArticleSource source,
  }) {
    final prefix = switch (source) {
      ArticleSource.inbox => '',
      ArticleSource.favorites => '/favorites',
      ArticleSource.archive => '/archive',
    };
    context.push('$prefix/article/$articleId');
  }

  @override
  void goToAddSource(BuildContext context) => context.push('/sources/add');

  @override
  void goToArchive(BuildContext context) => context.push('/archive');

  @override
  void pop(BuildContext context) => context.pop();
}
