import 'package:newsreader/core/feed/feed_data.dart';

abstract class FeedParser {
  /// Parses an XML string (RSS 2.0 or Atom) into a [FeedData].
  /// Throws [ParseException] if the content is not a valid feed.
  FeedData parse(String xmlContent);
}
