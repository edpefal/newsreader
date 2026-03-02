import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/core/domain/repositories/source_repository.dart';

class GetSources {
  final SourceRepository _repository;

  const GetSources(this._repository);

  Future<List<NewsSource>> execute() => _repository.getSources();
}
