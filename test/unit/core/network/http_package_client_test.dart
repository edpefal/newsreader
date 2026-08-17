import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:newsreader/core/network/http_package_client.dart';

void main() {
  group('HttpPackageClient', () {
    test('get envía el header Accept: */* en toda solicitud', () async {
      http.Request? capturedRequest;
      final mockClient = MockClient((request) async {
        capturedRequest = request;
        return http.Response('contenido', 200);
      });
      final client = HttpPackageClient(client: mockClient);

      final body = await client.get('https://example.com/rss/');

      expect(body, 'contenido');
      expect(capturedRequest?.headers['Accept'], '*/*');
    });
  });
}
