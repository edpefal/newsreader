import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:newsreader/core/sync/cloud_sync_client.dart';

/// Un grupo de filas que comparten el mismo payload de update (todo salvo
/// `id`), listas para actualizarse con un solo UPDATE ... WHERE id IN (...).
class RowUpdateGroup {
  final Map<String, dynamic> payload;
  final List<dynamic> ids;

  const RowUpdateGroup(this.payload, this.ids);
}

/// Agrupa filas por payload idéntico (todo salvo `id`), preservando el
/// orden de primera aparición de cada grupo. Función pura, sin dependencia
/// del cliente de Supabase, para poder testear el agrupamiento sin mockear
/// la cadena fluida de `postgrest`.
List<RowUpdateGroup> groupRowsByPayload(List<Map<String, dynamic>> rows) {
  final order = <String>[];
  final groups = <String, RowUpdateGroup>{};
  for (final row in rows) {
    final payload = Map<String, dynamic>.from(row)..remove('id');
    final key = jsonEncode(payload);
    final existing = groups[key];
    if (existing == null) {
      order.add(key);
      groups[key] = RowUpdateGroup(payload, [row['id']]);
    } else {
      existing.ids.add(row['id']);
    }
  }
  return order.map((key) => groups[key]!).toList();
}

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
      // Agrupa las filas con payload idéntico (todo salvo `id`) para poder
      // actualizarlas con un solo UPDATE ... WHERE id IN (...) en vez de un
      // request por fila -- un borrado de fuente puede implicar cientos de
      // artículos con el mismo `deleted_at`, y un loop de un request por
      // fila deja todo lo que no llegó a correr sin actualizar si se
      // interrumpe a mitad de camino (red, app a background, cierre).
      for (final group in groupRowsByPayload(rows)) {
        await _supabase
            .from(table)
            .update(group.payload)
            .inFilter('id', group.ids);
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
