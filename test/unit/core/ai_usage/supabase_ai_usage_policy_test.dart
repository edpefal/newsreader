import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/ai_usage/supabase_ai_usage_policy.dart';
import 'package:newsreader/core/constants/app_constants.dart';
import 'package:newsreader/core/sync/cloud_sync_client.dart';

class MockCloudSyncClient extends Mock implements CloudSyncClient {}

void main() {
  late MockCloudSyncClient mockCloudSyncClient;
  late SupabaseAiUsagePolicy sut;

  setUp(() {
    mockCloudSyncClient = MockCloudSyncClient();
    sut = SupabaseAiUsagePolicy(mockCloudSyncClient);
  });

  test('arma el status a partir de la fila devuelta por CloudSyncClient',
      () async {
    when(() => mockCloudSyncClient.fetchChangedSince('ai_usage_daily', null))
        .thenAnswer((_) async => [
              {
                'user_id': 'u1',
                'day': '2026-08-22',
                'words_used': 6300,
                'updated_at': '2026-08-22T10:00:00Z',
              },
            ]);

    final status = await sut.getStatus();

    expect(status.wordsUsed, 6300);
    expect(status.wordLimit, AppConstants.aiUsageDailyWordLimit);
    expect(status.resetsAt, DateTime.utc(2026, 8, 23));
  });

  test('devuelve 0 palabras usadas si el usuario no tiene fila todavía',
      () async {
    when(() => mockCloudSyncClient.fetchChangedSince('ai_usage_daily', null))
        .thenAnswer((_) async => []);

    final status = await sut.getStatus();

    expect(status.wordsUsed, 0);
    expect(status.wordLimit, AppConstants.aiUsageDailyWordLimit);
  });
}
