class SharableFile {
  final String name;
  final String content;
  final String mimeType;

  const SharableFile({
    required this.name,
    required this.content,
    required this.mimeType,
  });
}

/// Abstracción sobre el mecanismo nativo de compartir del sistema operativo
/// (ver tabla de abstracciones en CLAUDE.md — ninguna librería de terceros
/// se importa fuera de `core/`).
abstract class FileSharer {
  Future<void> shareFiles(List<SharableFile> files);
}
