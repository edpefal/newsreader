import 'package:uuid/uuid.dart';

import 'package:newsreader/core/utils/id_generator.dart';

class UuidIdGenerator implements IdGenerator {
  const UuidIdGenerator();

  @override
  String generate() => const Uuid().v4();

  @override
  String generateFromSeed(String seed) =>
      const Uuid().v5(Namespace.url.value, seed);
}
