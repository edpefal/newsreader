import 'package:newsreader/core/sharing/file_sharer.dart';
import 'package:newsreader/features/account/domain/usecases/export_favorites_json.dart';
import 'package:newsreader/features/account/domain/usecases/export_sources_opml.dart';

/// Genera los archivos de exportación del usuario (fuentes en OPML,
/// favoritos en JSON) y los ofrece para compartir vía el mecanismo nativo
/// del sistema, sin requerir conexión (ver capability `data-export`).
class ExportUserData {
  final ExportSourcesOpml _exportSourcesOpml;
  final ExportFavoritesJson _exportFavoritesJson;
  final FileSharer _fileSharer;

  const ExportUserData(
    this._exportSourcesOpml,
    this._exportFavoritesJson,
    this._fileSharer,
  );

  Future<void> execute() async {
    final opml = await _exportSourcesOpml.execute();
    final json = await _exportFavoritesJson.execute();

    await _fileSharer.shareFiles([
      SharableFile(
        name: 'fuentes-reevo.opml',
        content: opml,
        mimeType: 'text/x-opml',
      ),
      SharableFile(
        name: 'favoritos-reevo.json',
        content: json,
        mimeType: 'application/json',
      ),
    ]);
  }
}
