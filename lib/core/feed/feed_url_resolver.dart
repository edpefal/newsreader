/// Deriva candidatos de feed URL a partir de una URL "humana" de newsletter,
/// aplicando heurísticas de patrón de host por plataforma conocida.
class FeedUrlResolver {
  static const _platformSuffixes = {
    'substack.com': '/feed',
    'wordpress.com': '/feed/',
    'ghost.io': '/rss/',
  };

  /// Devuelve la lista ordenada de candidatos de feed URL a probar:
  /// [rawUrl] siempre primero (preserva pegar la feed URL exacta), seguido
  /// del candidato heurístico si el host matchea una plataforma conocida.
  List<String> candidatesFor(String rawUrl) {
    final candidates = [rawUrl];

    final heuristicCandidate = _heuristicCandidateFor(rawUrl);
    if (heuristicCandidate != null && heuristicCandidate != rawUrl) {
      candidates.add(heuristicCandidate);
    }

    return candidates;
  }

  String? _heuristicCandidateFor(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || uri.host.isEmpty) return null;

    final substackProfileCandidate = _substackProfileCandidateFor(uri);
    if (substackProfileCandidate != null) return substackProfileCandidate;

    for (final entry in _platformSuffixes.entries) {
      final domain = entry.key;
      if (uri.host.endsWith('.$domain')) {
        final origin = Uri(scheme: uri.scheme, host: uri.host).toString();
        return '$origin${entry.value}';
      }
    }

    return null;
  }

  /// Caso especial: `substack.com/@usuario` no usa subdominio, el usuario
  /// va en el path. Se transforma a `https://usuario.substack.com/feed`.
  String? _substackProfileCandidateFor(Uri uri) {
    if (uri.host != 'substack.com' && uri.host != 'www.substack.com') {
      return null;
    }

    final segments = uri.pathSegments;
    if (segments.isEmpty || !segments.first.startsWith('@')) return null;

    final username = segments.first.substring(1);
    if (username.isEmpty) return null;

    return 'https://$username.substack.com/feed';
  }
}
