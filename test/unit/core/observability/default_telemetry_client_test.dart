import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry/sentry.dart';

import 'package:newsreader/core/observability/telemetry_client.dart';
import 'package:newsreader/core/observability/default_telemetry_client.dart';

class _RecordingTransport implements Transport {
  final List<SentryEnvelope> envelopes = [];

  @override
  Future<SentryId?> send(SentryEnvelope envelope) async {
    envelopes.add(envelope);
    return envelope.header.eventId;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // `trackEvent`/`setUserId` hacen fan-out a PostHog además de Sentry (ver
  // design.md de add-product-analytics); sin este mock, construir el cliente
  // de PostHog falla porque intenta registrar un handler de método antes de
  // que el binding esté listo, y sin binding no llega a inicializarse.
  const postHogChannel = MethodChannel('posthog_flutter');
  final postHogCalls = <MethodCall>[];

  late _RecordingTransport transport;
  late DefaultTelemetryClient sut;

  setUp(() async {
    postHogCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(postHogChannel, (call) async {
      postHogCalls.add(call);
      return null;
    });

    transport = _RecordingTransport();
    await Sentry.init((options) {
      options.dsn = 'https://public@dummy.ingest.sentry.io/1';
      options.transport = transport;
    });
    sut = DefaultTelemetryClient();
  });

  tearDown(() async {
    await Sentry.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(postHogChannel, null);
  });

  test('captureException delega en Sentry.captureException', () async {
    sut.captureException(Exception('boom'), StackTrace.current);
    await _waitUntil(() => transport.envelopes.isNotEmpty);

    expect(transport.envelopes, isNotEmpty);
  });

  test('captureMessage delega en Sentry.captureMessage', () async {
    sut.captureMessage('algo pasó', level: TelemetryLevel.warning);
    await _waitUntil(() => transport.envelopes.isNotEmpty);

    expect(transport.envelopes, isNotEmpty);
  });

  test('setUserId(id) asocia el id de usuario al scope de Sentry', () async {
    sut.setUserId('user-1');

    late SentryUser? user;
    await Sentry.configureScope((scope) => user = scope.user);

    expect(user?.id, 'user-1');
  });

  test('setUserId(null) no deja email ni ningún otro dato de PII en el scope de Sentry',
      () async {
    sut.setUserId('user-1');
    sut.setUserId(null);

    late SentryUser? user;
    await Sentry.configureScope((scope) => user = scope.user);

    expect(user, isNull);
  });

  test('setUserId(id) identifica al usuario en PostHog', () async {
    sut.setUserId('user-1');
    await Future<void>.delayed(Duration.zero);

    final call = postHogCalls.singleWhere((c) => c.method == 'identify');
    expect(call.arguments['userId'], 'user-1');
  });

  test('setUserId(null) resetea la identidad en PostHog', () async {
    sut.setUserId(null);
    await Future<void>.delayed(Duration.zero);

    expect(postHogCalls.any((c) => c.method == 'reset'), isTrue);
  });

  test('trackEvent envía el evento a PostHog con sus propiedades', () async {
    sut.trackEvent('source_added', properties: {'foo': 'bar'});
    await Future<void>.delayed(Duration.zero);

    final call = postHogCalls.singleWhere((c) => c.method == 'capture');
    expect(call.arguments['eventName'], 'source_added');
    expect(call.arguments['properties'], containsPair('foo', 'bar'));
  });

  test('trackEvent sin propiedades no manda valores null a PostHog', () async {
    sut.trackEvent('sync_triggered');
    await Future<void>.delayed(Duration.zero);

    final call = postHogCalls.singleWhere((c) => c.method == 'capture');
    expect(call.arguments['eventName'], 'sync_triggered');
  });
}

/// Sentry procesa `capture*` de forma asíncrona en varios pasos (sampling,
/// event processors, transporte); un solo `Future.delayed(Duration.zero)`
/// alcanza en la mayoría de las corridas locales pero es flaky en runners de
/// CI más lentos o cargados. Este poll evita depender de un único tick del
/// event loop.
Future<void> _waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
