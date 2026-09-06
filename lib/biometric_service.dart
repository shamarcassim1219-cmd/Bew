import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static const _enabledKey = 'biometric_login_enabled';
  static const _tokenKey = 'biometric_auth_token';

  static final LocalAuthentication _auth = LocalAuthentication();
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported && canCheck;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isEnabled() async {
    return (await _storage.read(key: _enabledKey)) == 'true';
  }

  static Future<bool> enable(String token) async {
    if (!await isAvailable()) return false;
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Confirm your identity to enable biometric login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      if (!authenticated) return false;
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _enabledKey, value: 'true');
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> disable() async {
    await _storage.delete(key: _enabledKey);
    await _storage.delete(key: _tokenKey);
  }

  static Future<String?> authenticateAndGetToken() async {
    if (!await isEnabled()) return null;
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Use your fingerprint or face to sign in',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      if (!authenticated) return null;
      return await _storage.read(key: _tokenKey);
    } catch (_) {
      return null;
    }
  }
}
