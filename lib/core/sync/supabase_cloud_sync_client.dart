import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:newsreader/core/sync/cloud_sync_client.dart';

class SupabaseCloudSyncClient implements CloudSyncClient {
  final sb.SupabaseClient _supabase;

  // PostgREST devuelve como mucho esta cantidad de filas por consulta si no
  // se pagina explícitamente (confirmado en producción: una cuenta con
  // 1032 artículos perdía en silencio los que quedaban después de la fila
  // 1000 en una resincronización completa). `fetchChangedSince` pagina con
  // `.range()` para traer siempre todo lo que corresponde.
  static const _pageSize = 1000;

  SupabaseCloudSyncClient({sb.SupabaseClient? supabase})
    : _supabase = supabase ?? sb.Supabase.instance.client;

  @override
  Future<void> upsert(String table, List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    try {
      await _supabase.from(table).upsert(rows);
    } catch (e) {
      throw CloudSyncException(e.toString());
    }
  }

  @override
  Future<void> updatePartial(
    String table,
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return;
    try {
      for (final row in rows) {
        final id = row['id'];
        final payload = Map<String, dynamic>.from(row)..remove('id');
        await _supabase.from(table).update(payload).eq('id', id);
      }
    } catch (e) {
      throw CloudSyncException(e.toString());
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchChangedSince(
    String table,
    DateTime? since,
  ) async {
    try {
      final all = <Map<String, dynamic>>[];
      var offset = 0;
      while (true) {
        final query = _supabase.from(table).select();
        final filtered = since == null
            ? query
            : query.gt('updated_at', since.toIso8601String());
        final page = await filtered
            .order('updated_at', ascending: true)
            .range(offset, offset + _pageSize - 1);
        final rows = List<Map<String, dynamic>>.from(page as List);
        all.addAll(rows);
        if (rows.length < _pageSize) break;
        offset += _pageSize;
      }
      return all;
    } catch (e) {
      throw CloudSyncException(e.toString());
    }
  }
}
