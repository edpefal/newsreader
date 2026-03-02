import 'package:newsreader/core/constants/app_constants.dart';

class FeedContentChecker {
  const FeedContentChecker._();

  /// Returns true if [contentHtml] is considered truncated or empty.
  /// Truncated means: null, blank, or shorter than [AppConstants.articleTruncatedThreshold].
  static bool isTruncated(String? contentHtml) {
    if (contentHtml == null || contentHtml.trim().isEmpty) return true;
    return contentHtml.length < AppConstants.articleTruncatedThreshold;
  }
}
