/// Deriva candidatos de feed URL a partir de una URL "humana" de newsletter,
/// combinando sufijos genéricos de feed (probados sobre el dominio raíz sin
/// importar la plataforma) con casos de inserción de path específicos de
/// plataforma (Substack, Medium) para perfiles/publicaciones que no cuelgan
/// de la raíz del dominio.
class FeedUrlResolver {
  static const _genericSuffixes = [
    '/feed',
    '/feed/',
    '/rss/',
    '/atom.xml',
    '/rss.xml',
    '/feed.xml',
    '/index.xml',
  ];

  /// Devuelve la lista ordenada de candidatos de feed URL a probar, en orden
  /// de prioridad: la URL normalizada (con esquema `https://` agregado si
  /// [rawUrl] no lo incluye) siempre primero (preserva pegar la feed URL
  /// exacta), seguido de los casos de inserción de path específicos de
  /// plataforma que apliquen, y por último los sufijos genéricos sobre el
  /// origin del host. No incluye duplicados.
  List<String> candidatesFor(String rawUrl) {
    final normalizedUrl = _withScheme(rawUrl);
    final candidates = [normalizedUrl];

    void addIfNew(String? candidate) {
      if (candidate != null && !candidates.contains(candidate)) {
        candidates.add(candidate);
      }
    }

    final uri = Uri.tryParse(normalizedUrl);
    if (uri == null || uri.host.isEmpty) return candidates;

    addIfNew(_substackProfileCandidateFor(uri));
    addIfNew(_mediumInsertionCandidateFor(uri));

    final origin = Uri(scheme: uri.scheme, host: uri.host).toString();
    for (final suffix in _genericSuffixes) {
      addIfNew('$origin$suffix');
    }

    if (!uri.host.startsWith('www.')) {
      final wwwOrigin =
          Uri(scheme: uri.scheme, host: 'www.${uri.host}').toString();
      for (final suffix in _genericSuffixes) {
        addIfNew('$wwwOrigin$suffix');
      }
    }

    return candidates;
  }

  /// Antepone `https://` cuando [url] no incluye ningún esquema — el caso
  /// más común de lo que un usuario escribe a mano (ej. `stratechery.com`).
  /// Sin esto, `Uri.parse` del lado del cliente HTTP produce una URI sin
  /// host y falla con un error no relacionado a "no se encontró el feed".
  String _withScheme(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.hasScheme) return url;
    return 'https://$url';
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

  /// Caso especial: en `medium.com/@usuario` o `medium.com/publicación`,
  /// el feed no cuelga de la raíz del dominio — hay que insertar `/feed`
  /// inmediatamente después del host, antes del resto del path. No aplica
  /// a subdominios propios (`usuario.medium.com`), que ya resuelven bien
  /// con el sufijo genérico `/feed` sobre el origin.
  String? _mediumInsertionCandidateFor(Uri uri) {
    if (uri.host != 'medium.com' && uri.host != 'www.medium.com') {
      return null;
    }

    final segments = uri.pathSegments;
    if (segments.isEmpty || segments.first.isEmpty) return null;

    final origin = Uri(scheme: uri.scheme, host: uri.host).toString();
    return '$origin/feed/${segments.first}';
  }
}
