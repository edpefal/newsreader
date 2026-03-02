import 'package:uuid/uuid.dart';

import 'package:newsreader/core/utils/id_generator.dart';

class UuidIdGenerator implements IdGenerator {
  const UuidIdGenerator();

  @override
  String generate() => const Uuid().v4();
}
