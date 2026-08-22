import 'package:flutter_test/flutter_test.dart';
import 'package:sentry/sentry.dart';

import 'package:newsreader/core/observability/observability_client.dart';
import 'package:newsreader/core/observability/sentry_observability_client.dart';

class _RecordingTransport implements Transport {
  final List<SentryEnvelope> envelopes = [];

  @override
  Future<SentryId?> send(SentryEnvelope envelope) async {
    envelopes.add(envelope);
    return envelope.header.eventId;
  }
}

void main() {
  late _RecordingTransport transport;
  late SentryObservabilityClient sut;

  setUp(() async {
    transport = _RecordingTransport();
    await Sentry.init((options) {
      options.dsn = 'https://public@dummy.ingest.sentry.io/1';
      options.transport = transport;
    });
    sut = SentryObservabilityClient();
  });

  tearDown(() async {
    await Sentry.close();
  });

  test('captureException delega en Sentry.captureException', () async {
    sut.captureException(Exception('boom'), StackTrace.current);
    await Future<void>.delayed(Duration.zero);

    expect(transport.envelopes, isNotEmpty);
  });

  test('captureMessage delega en Sentry.captureMessage', () async {
    sut.captureMessage('algo pasó', level: ObservabilityLevel.warning);
    await Future<void>.delayed(Duration.zero);

    expect(transport.envelopes, isNotEmpty);
  });

  test('setUserId(id) asocia el id de usuario al scope', () async {
    sut.setUserId('user-1');

    late SentryUser? user;
    await Sentry.configureScope((scope) => user = scope.user);

    expect(user?.id, 'user-1');
  });

  test('setUserId(null) no deja email ni ningún otro dato de PII en el scope',
      () async {
    sut.setUserId('user-1');
    sut.setUserId(null);

    late SentryUser? user;
    await Sentry.configureScope((scope) => user = scope.user);

    expect(user, isNull);
  });
}
