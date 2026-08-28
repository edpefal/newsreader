/// Abstracción sobre abrir un link fuera de la app, en el navegador del
/// sistema (no en el `ArticleWebView` interno). Sigue la regla de
/// abstracciones del proyecto: `url_launcher` no se importa directo en
/// `domain/`/`presentation/` -- ver capability `article-mentions`.
abstract class ExternalLinkLauncher {
  Future<void> open(String url);
}
