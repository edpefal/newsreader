import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/core/observability/observability_client.dart';

/// client ID "web" de Google configurado en Supabase Auth. Se usa como
/// serverClientId para que Google emita un ID token válido para el
/// intercambio con Supabase (`signInWithIdToken`), además del client ID
/// nativo de cada plataforma configurado en Google Cloud Console.
const _googleServerClientId =
    '804701846700-7tqci3mkk2m56v8ph5vaac3ap10jlm3i.apps.googleusercontent.com';

class SupabaseAuthClient implements AuthClient {
  final sb.SupabaseClient _supabase;
  final GoogleSignIn _googleSignIn;
  final ObservabilityClient _observabilityClient;

  SupabaseAuthClient({
    required ObservabilityClient observabilityClient,
    sb.SupabaseClient? supabase,
    GoogleSignIn? googleSignIn,
  })  : _observabilityClient = observabilityClient,
        _supabase = supabase ?? sb.Supabase.instance.client,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              serverClientId: _googleServerClientId,
              scopes: ['email'],
            );

  @override
  Stream<bool> get authStateChanges => _supabase.auth.onAuthStateChange
      .map((event) => event.session != null);

  @override
  bool get isSignedIn => _supabase.auth.currentSession != null;

  @override
  String? get currentUserId => _supabase.auth.currentUser?.id;

  @override
  String? get currentAccessToken => _supabase.auth.currentSession?.accessToken;

  @override
  Future<AuthResult> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return AuthResult.cancelled;

      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        throw const AuthException(AppErrorCode.googleTokenMissing);
      }

      await _supabase.auth.signInWithIdToken(
        provider: sb.OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );
      return AuthResult.success;
    } on AuthException {
      rethrow;
    } catch (e, st) {
      _observabilityClient.captureException(e, st);
      throw const AuthException(AppErrorCode.unknown);
    }
  }

  @override
  Future<AuthResult> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const AuthException(AppErrorCode.appleTokenMissing);
      }

      await _supabase.auth.signInWithIdToken(
        provider: sb.OAuthProvider.apple,
        idToken: idToken,
      );
      return AuthResult.success;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return AuthResult.cancelled;
      }
      throw const AuthException(AppErrorCode.authProviderError);
    } on AuthException {
      rethrow;
    } catch (e, st) {
      _observabilityClient.captureException(e, st);
      throw const AuthException(AppErrorCode.unknown);
    }
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _supabase.auth.signOut();
  }
}
