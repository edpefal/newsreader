import 'package:newsreader/core/errors/app_error_code.dart';

/// Tipo de mención detectada en un artículo (ver capability
/// `article-mentions`). "Productos" queda fuera de scope -- no se encontró
/// un proveedor gratuito viable para resolver nombre de producto en texto
/// libre a imagen/link (ver proposal.md). `article` (URL de otro artículo
/// mencionado/citado) se agregó en `add-article-mentioned-links`.
enum MentionType { book, podcast, music, article }

/// Nombre y tipo de una mención, tal como los extrae `summarize-article`,
/// antes de enriquecer. [url] solo está presente (y no vacía) cuando [type]
/// es [MentionType.article] -- la URL detectada directamente en el
/// artículo, no una búsqueda por nombre.
typedef RawMention = ({MentionType type, String name, String? url});

/// Una mención ya enriquecida: `imageUrl`/`link` ausentes indican que el
/// proveedor correspondiente no encontró match (o falló), no que se haya
/// descartado la mención.
typedef EnrichedMention = ({
  MentionType type,
  String name,
  String? imageUrl,
  String? link,
});

/// Abstracción sobre el proveedor externo que resuelve una [RawMention] a
/// imagen de portada + link. Sigue la regla de abstracciones del proyecto:
/// ningún proveedor concreto (Google Books, iTunes Search, o uno futuro
/// como Spotify) se importa directo en `domain/`/`presentation/`. El ruteo
/// por tipo de mención a un proveedor concreto vive del lado del backend
/// (`enrich-mentions`), no en esta interfaz -- ver design.md.
abstract class MentionEnricher {
  /// Enriquece [mentions] en una sola invocación. Lanza
  /// [MentionEnrichmentException] si la request entera falla (red, backend
  /// caído); una mención puntual sin match del proveedor no lanza, se
  /// devuelve sin `imageUrl`/`link`.
  Future<List<EnrichedMention>> enrich(List<RawMention> mentions);
}

/// Serialización de [MentionType] al string usado en el wire format de
/// `summarize-article`/`enrich-mentions` (`"book"`/`"podcast"`/`"music"`) y
/// en la persistencia local -- un único lugar para no repetir el mapeo.
extension MentionTypeWireFormat on MentionType {
  String get wireValue => name;

  static MentionType fromWireValue(String value) => MentionType.values
      .firstWhere((t) => t.name == value, orElse: () => MentionType.book);
}

class MentionEnrichmentException implements Exception {
  final AppErrorCode code;

  const MentionEnrichmentException(this.code);

  @override
  String toString() => 'MentionEnrichmentException: $code';
}
