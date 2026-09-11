import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum NativeGoogleAuthFailure {
  cancelled,
  configuration,
  unavailable,
  timedOut,
  missingToken,
  failed,
}

class NativeGoogleAuthException implements Exception {
  const NativeGoogleAuthException(this.failure);

  final NativeGoogleAuthFailure failure;
}

class NativeGoogleTokens {
  const NativeGoogleTokens({required this.idToken, this.accessToken});

  final String idToken;
  final String? accessToken;
}

abstract interface class GoogleAuthClient {
  Future<NativeGoogleTokens> authenticate();

  Future<void> signOut();
}

/// Native Google authentication gateway for Android and iOS.
///
/// Google Sign-In 7.x requires one explicit initialization before any other
/// operation. The OAuth client identifiers are public configuration values,
/// but are still kept outside source control so each build environment can use
/// its own Google/Firebase project.
class NativeGoogleAuthClient implements GoogleAuthClient {
  NativeGoogleAuthClient({GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  static const _authorizationScopes = <String>[];
  static const _accountPickerTimeout = Duration(seconds: 45);
  static const _silentAuthorizationTimeout = Duration(seconds: 5);

  final GoogleSignIn _googleSignIn;
  Future<void>? _initialization;

  @override
  Future<NativeGoogleTokens> authenticate() async {
    await _ensureInitialized();

    if (!_googleSignIn.supportsAuthenticate()) {
      throw const NativeGoogleAuthException(
        NativeGoogleAuthFailure.unavailable,
      );
    }

    try {
      final account = await _googleSignIn
          .authenticate(scopeHint: _authorizationScopes)
          .timeout(
            _accountPickerTimeout,
            onTimeout: () => throw const NativeGoogleAuthException(
              NativeGoogleAuthFailure.timedOut,
            ),
          );

      // Supabase authenticates Google with the ID token. An access token is
      // useful when Google can return one silently, but it is optional in
      // GoTrue. Never launch a second consent prompt for an empty scope list:
      // some Android credential-manager versions can leave that future open.
      GoogleSignInClientAuthorization? authorization;
      try {
        authorization = await account.authorizationClient
            .authorizationForScopes(_authorizationScopes)
            .timeout(_silentAuthorizationTimeout, onTimeout: () => null);
      } catch (_) {
        authorization = null;
      }

      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const NativeGoogleAuthException(
          NativeGoogleAuthFailure.missingToken,
        );
      }

      return NativeGoogleTokens(
        idToken: idToken,
        accessToken: authorization?.accessToken,
      );
    } on NativeGoogleAuthException {
      rethrow;
    } on GoogleSignInException catch (error) {
      debugPrint('Native Google sign-in failed: ${error.code.name}');
      throw NativeGoogleAuthException(_failureFor(error.code));
    } catch (_) {
      throw const NativeGoogleAuthException(NativeGoogleAuthFailure.failed);
    }
  }

  @override
  Future<void> signOut() async {
    await _ensureInitialized();
    await _googleSignIn.signOut();
  }

  Future<void> _ensureInitialized() {
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      throw const NativeGoogleAuthException(
        NativeGoogleAuthFailure.unavailable,
      );
    }

    final serverClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim() ?? '';
    final iosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID']?.trim() ?? '';
    if (serverClientId.isEmpty ||
        (defaultTargetPlatform == TargetPlatform.iOS && iosClientId.isEmpty)) {
      throw const NativeGoogleAuthException(
        NativeGoogleAuthFailure.configuration,
      );
    }

    try {
      await _googleSignIn.initialize(
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? iosClientId
            : null,
        serverClientId: serverClientId,
      );
    } on GoogleSignInException catch (error) {
      throw NativeGoogleAuthException(_failureFor(error.code));
    } catch (_) {
      throw const NativeGoogleAuthException(
        NativeGoogleAuthFailure.configuration,
      );
    }
  }

  NativeGoogleAuthFailure _failureFor(GoogleSignInExceptionCode code) {
    return switch (code) {
      GoogleSignInExceptionCode.canceled => NativeGoogleAuthFailure.cancelled,
      GoogleSignInExceptionCode.clientConfigurationError ||
      GoogleSignInExceptionCode.providerConfigurationError =>
        NativeGoogleAuthFailure.configuration,
      GoogleSignInExceptionCode.uiUnavailable =>
        NativeGoogleAuthFailure.unavailable,
      _ => NativeGoogleAuthFailure.failed,
    };
  }
}
