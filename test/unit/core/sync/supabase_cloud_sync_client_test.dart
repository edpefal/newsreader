import 'package:flutter_test/flutter_test.dart';

import 'package:newsreader/core/sync/supabase_cloud_sync_client.dart';

void main() {
  group('groupRowsByPayload', () {
    test('agrupa en un solo grupo filas con el mismo payload', () {
      final rows = [
        {'id': 'a1', 'deleted_at': '2026-01-01T00:00:00.000Z'},
        {'id': 'a2', 'deleted_at': '2026-01-01T00:00:00.000Z'},
        {'id': 'a3', 'deleted_at': '2026-01-01T00:00:00.000Z'},
      ];

      final groups = groupRowsByPayload(rows);

      expect(groups, hasLength(1));
      expect(groups.single.payload, {'deleted_at': '2026-01-01T00:00:00.000Z'});
      expect(groups.single.ids, ['a1', 'a2', 'a3']);
    });

    test('separa en grupos distintos filas con payloads distintos', () {
      final rows = [
        {'id': 'a1', 'is_read': true},
        {'id': 'a2', 'is_read': false},
        {'id': 'a3', 'is_read': true},
      ];

      final groups = groupRowsByPayload(rows);

      expect(groups, hasLength(2));
      final readGroup = groups.firstWhere((g) => g.payload['is_read'] == true);
      final unreadGroup = groups.firstWhere((g) => g.payload['is_read'] == false);
      expect(readGroup.ids, ['a1', 'a3']);
      expect(unreadGroup.ids, ['a2']);
    });

    test('no mezcla datos entre filas con distintos campos', () {
      final rows = [
        {'id': 'a1', 'is_read': true, 'read_at': '2026-01-01T00:00:00.000Z'},
        {'id': 'a2', 'is_read': true, 'read_at': '2026-01-02T00:00:00.000Z'},
      ];

      final groups = groupRowsByPayload(rows);

      expect(groups, hasLength(2));
      expect(
        groups.map((g) => g.payload['read_at']),
        containsAll(['2026-01-01T00:00:00.000Z', '2026-01-02T00:00:00.000Z']),
      );
    });

    test('lista vacía produce ningún grupo', () {
      expect(groupRowsByPayload([]), isEmpty);
    });
  });
}
