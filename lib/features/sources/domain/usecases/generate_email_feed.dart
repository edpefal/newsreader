import 'package:newsreader/core/email_feed/email_feed_generator.dart';

class GenerateEmailFeed {
  final EmailFeedGenerator _emailFeedGenerator;

  const GenerateEmailFeed(this._emailFeedGenerator);

  Future<GeneratedEmailFeed> execute({String? label}) {
    return _emailFeedGenerator.generate(label: label);
  }
}
