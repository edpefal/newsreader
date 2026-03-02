import 'package:webfeed_plus/webfeed_plus.dart';

import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/core/feed/feed_data.dart';
import 'package:newsreader/core/feed/feed_parser.dart';

class WebfeedFeedParser implements FeedParser {
  @override
  FeedData parse(String xmlContent) {
    try {
      return _tryRss(xmlContent);
    } catch (_) {
      try {
        return _tryAtom(xmlContent);
      } catch (_) {
        throw const ParseException();
      }
    }
  }

  FeedData _tryRss(String xml) {
    final feed = RssFeed.parse(xml);
    return FeedData(
      title: feed.title ?? 'Sin título',
      author: feed.author,
      iconUrl: feed.image?.url,
      items: (feed.items ?? []).map(_rssItemToFeedItem).toList(),
    );
  }

  FeedData _tryAtom(String xml) {
    final feed = AtomFeed.parse(xml);
    return FeedData(
      title: feed.title ?? 'Sin título',
      author: feed.authors?.firstOrNull?.name,
      iconUrl: feed.icon,
      items: (feed.items ?? []).map(_atomItemToFeedItem).toList(),
    );
  }

  FeedItem _rssItemToFeedItem(RssItem item) {
    return FeedItem(
      guid: item.guid,
      title: item.title ?? 'Sin título',
      author: item.author,
      publishedAt: item.pubDate,
      contentHtml: item.content?.value,
      excerpt: item.description,
      link: item.link,
    );
  }

  FeedItem _atomItemToFeedItem(AtomItem item) {
    return FeedItem(
      guid: item.id,
      title: item.title ?? 'Sin título',
      author: item.authors?.firstOrNull?.name,
      publishedAt: _parseDate(item.published),
      contentHtml: item.content,
      excerpt: item.summary,
      link: item.links?.firstOrNull?.href,
    );
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
