/// Selecciona el backend de Supabase contra el que corre la app, según el
/// dart-define `APP_ENV` (`dev` por defecto). Ver
/// `openspec/changes/split-dev-prod-backend-config/design.md`.
///
/// `dev` es el default seguro: un `flutter run` normal nunca pega a prod sin
/// que alguien lo pida explícitamente con `--dart-define=APP_ENV=prod`.
class AppConfig {
  AppConfig._();

  static const String _env =
      String.fromEnvironment('APP_ENV', defaultValue: 'dev');

  static const bool isProd = _env == 'prod';

  // TODO(split-dev-prod-backend-config): reemplazar por la URL/anon key
  // reales del proyecto Supabase "dev" una vez creado (tasks.md, sección 2).
  static const String _devSupabaseUrl = 'https://TODO-dev.supabase.co';
  static const String _devSupabaseAnonKey = 'TODO-dev-anon-key';

  static const String _prodSupabaseUrl =
      'https://avyaxzhdilhufyimrzzb.supabase.co';
  static const String _prodSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF2eWF4emhkaWxodWZ5aW1yenpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM3OTE1MTMsImV4cCI6MjA5OTM2NzUxM30.LfgL2Arsth-br6qoAUzbAYhMFtiVCXnrnpoWU59Xzh0';

  static const String supabaseUrl = isProd ? _prodSupabaseUrl : _devSupabaseUrl;
  static const String supabaseAnonKey =
      isProd ? _prodSupabaseAnonKey : _devSupabaseAnonKey;
}
