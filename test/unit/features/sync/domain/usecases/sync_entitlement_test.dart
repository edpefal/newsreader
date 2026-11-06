import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/core/sync/cloud_sync_client.dart';
import 'package:newsreader/features/sync/domain/usecases/sync_entitlement.dart';

class MockCloudSyncClient extends Mock implements CloudSyncClient {}

void main() {
  late MockCloudSyncClient cloudSyncClient;
  late SyncEntitlement syncEntitlement;

  setUp(() {
    cloudSyncClient = MockCloudSyncClient();
    syncEntitlement = SyncEntitlement(cloudSyncClient);
  });

  test('pide al backend sincronizar el entitlement y devuelve true', () async {
    when(() => cloudSyncClient.syncEntitlement()).thenAnswer((_) async {});

    expect(await syncEntitlement.execute(), isTrue);
    verify(() => cloudSyncClient.syncEntitlement()).called(1);
  });

  test('si falla (sin red) no propaga el error y devuelve false', () async {
    when(
      () => cloudSyncClient.syncEntitlement(),
    ).thenThrow(const CloudSyncException('sin red', AppErrorCode.network));

    expect(await syncEntitlement.execute(), isFalse);
  });
}
