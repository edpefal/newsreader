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

  static const String _devSupabaseUrl =
      'https://xgwnxhpdcrghrtdbrmpn.supabase.co';
  static const String _devSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhnd254aHBkY3JnaHJ0ZGJybXBuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY0MDYwODAsImV4cCI6MjEwMTk4MjA4MH0.Jf2OQDF8epNC3sXDOJK7T-sdS_FjfHvDO4IkACmxbgU';

  static const String _prodSupabaseUrl =
      'https://avyaxzhdilhufyimrzzb.supabase.co';
  static const String _prodSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF2eWF4emhkaWxodWZ5aW1yenpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM3OTE1MTMsImV4cCI6MjA5OTM2NzUxM30.LfgL2Arsth-br6qoAUzbAYhMFtiVCXnrnpoWU59Xzh0';

  static const String supabaseUrl = isProd ? _prodSupabaseUrl : _devSupabaseUrl;
  static const String supabaseAnonKey =
      isProd ? _prodSupabaseAnonKey : _devSupabaseAnonKey;

  static const String _devSentryDsn =
      'https://c2a2926296b11986795345a4b2c47cf6@o4511954552946688.ingest.us.sentry.io/4511954576474112';
  static const String _prodSentryDsn =
      'https://203966973282e74abe8b174b6ec6afe4@o4511954552946688.ingest.us.sentry.io/4511954576801792';

  static const String sentryDsn = isProd ? _prodSentryDsn : _devSentryDsn;
}
