import 'package:webfeed_plus/webfeed_plus.dart';

import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/core/feed/feed_data.dart';
import 'package:newsreader/core/feed/feed_parser.dart';

class WebfeedFeedParser implements FeedParser {
  @override
  // Los tres `catch (_)` de este método no se reportan a observabilidad a
  // propósito: intentar RSS y después Atom es control de flujo normal, y
  // fallar los dos solo significa "esta URL no es un feed", algo esperado
  // cuando el usuario pega cualquier URL (ver design.md de
  // add-observability-provider, sección 4).
  FeedData parse(String xmlContent) {
    try {
      return _tryRss(xmlContent);
    } catch (_) {
      try {
        return _tryAtom(xmlContent);
      } catch (_) {
        throw const ParseException(AppErrorCode.invalidFeedUrl);
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
      // No se reporta a observabilidad a propósito: una fecha con formato
      // raro en un feed de terceros es rutina, ocurre todo el tiempo (ver
      // design.md de add-observability-provider, sección 4).
      return null;
    }
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
