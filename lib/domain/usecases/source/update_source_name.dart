import '../../repositories/source_repository.dart';

class UpdateSourceName {
  final SourceRepository _repository;

  const UpdateSourceName(this._repository);

  Future<void> execute(String sourceId, String newName) async {
    final sources = await _repository.getSources();
    final source = sources.firstWhere((s) => s.id == sourceId);
    await _repository.updateSource(source.copyWith(name: newName));
  }
}
