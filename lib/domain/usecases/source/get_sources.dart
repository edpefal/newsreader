import '../../entities/news_source.dart';
import '../../repositories/source_repository.dart';

class GetSources {
  final SourceRepository _repository;

  const GetSources(this._repository);

  Future<List<NewsSource>> execute() => _repository.getSources();
}
