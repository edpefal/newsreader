import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newsreader/core/sharing/file_sharer.dart';
import 'package:newsreader/core/sharing/share_plus_file_sharer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('shares both files with a nonempty origin accepted by iOS', () async {
    final directory = await Directory.systemTemp.createTemp(
      'reevo-export-test',
    );
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
    const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
    addTearDown(() async {
      messenger.setMockMethodCallHandler(shareChannel, null);
      messenger.setMockMethodCallHandler(pathChannel, null);
      await directory.delete(recursive: true);
    });
    messenger.setMockMethodCallHandler(pathChannel, (call) async {
      expect(call.method, 'getTemporaryDirectory');
      return directory.path;
    });

    Map<dynamic, dynamic>? arguments;
    messenger.setMockMethodCallHandler(shareChannel, (call) async {
      expect(call.method, 'shareFiles');
      arguments = call.arguments as Map<dynamic, dynamic>;
      return '';
    });

    const files = [
      SharableFile(
        name: 'fuentes-reevo.opml',
        content: '<opml><head><title>Fuentes de José</title></head></opml>',
        mimeType: 'text/x-opml',
      ),
      SharableFile(
        name: 'favoritos-reevo.json',
        content: '[{"title":"Artículo favorito"}]',
        mimeType: 'application/json',
      ),
    ];
    await SharePlusFileSharer().shareFiles(files);

    expect(arguments, isNotNull);
    expect(arguments!['originX'], greaterThanOrEqualTo(0));
    expect(arguments!['originY'], greaterThanOrEqualTo(0));
    expect(arguments!['originWidth'], greaterThan(0));
    expect(arguments!['originHeight'], greaterThan(0));
    final paths = (arguments!['paths'] as List).cast<String>();
    expect(paths, hasLength(files.length));
    for (var i = 0; i < files.length; i++) {
      expect(paths[i], endsWith('/${files[i].name}'));
      expect(await File(paths[i]).readAsString(), files[i].content);
    }
  });
}
