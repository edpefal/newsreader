import 'dart:convert';

import 'package:share_plus/share_plus.dart';

import 'package:newsreader/core/sharing/file_sharer.dart';

class SharePlusFileSharer implements FileSharer {
  @override
  Future<void> shareFiles(List<SharableFile> files) async {
    final xFiles = files
        .map((f) => XFile.fromData(
              utf8.encode(f.content),
              name: f.name,
              mimeType: f.mimeType,
            ))
        .toList();
    // `XFile.fromData` ignora `name` en todas las plataformas salvo web
    // (ver doc de `Share.shareXFiles`), así que hay que pasar los nombres
    // explícitamente para que el archivo compartido no pierda su extensión.
    await Share.shareXFiles(
      xFiles,
      fileNameOverrides: files.map((f) => f.name).toList(),
    );
  }
}
