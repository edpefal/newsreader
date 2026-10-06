import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:newsreader/core/sync/remote_source_checker.dart';

class SupabaseRemoteSourceChecker implements RemoteSourceChecker {
  final sb.SupabaseClient _supabase;

  /// Más corto que el timeout de sincronización (30s): esta consulta bloquea
  /// el botón de agregar fuente, y como es de mejor esfuerzo, un timeout
  /// equivale a "no se pudo comprobar" y se sigue con la verificación local.
  static const _timeout = Duration(seconds: 5);

  SupabaseRemoteSourceChecker({sb.SupabaseClient? supabase})
    : _supabase = supabase ?? sb.Supabase.instance.client;

  @override
  Future<bool> existsActive(String feedUrl) async {
    try {
      if (_supabase.auth.currentUser == null) return false;
      // RLS limita la consulta a las fuentes del usuario actual.
      final rows = await _supabase
          .from('sources')
          .select('id')
          .eq('feed_url', feedUrl)
          .filter('deleted_at', 'is', null)
          .limit(1)
          .timeout(_timeout);
      return (rows as List).isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
