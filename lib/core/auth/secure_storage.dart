import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wraps FlutterSecureStorage on native and SharedPreferences on web.
///
/// On web, FlutterSecureStorage throws MissingPluginException, so we use
/// SharedPreferences (localStorage) for web and FlutterSecureStorage (Keychain
/// / EncryptedSharedPreferences) for Android/iOS native.
///
/// All native operations are wrapped in try/catch: flutter_secure_storage has
/// a known Android keystore bug where reads throw after a cold restart
/// ("Reset KeyStore" / EncryptedSharedPreferences failure). A storage failure
/// must never hang the auth flow — treat it as "no token".
class SecureStorage {
  final SharedPreferences? _web;
  final FlutterSecureStorage? _native;

  SecureStorage(this._web, this._native);

  static Future<SecureStorage> create() async {
    // SECURITY NOTE: On web, tokens are stored in localStorage (SharedPreferences).
    // This is readable by any JS on the page. Mitigations:
    // - JWT access tokens are short-lived (15 min)
    // - CSP in nginx.conf blocks inline scripts
    // - Long-term: migrate to HttpOnly cookie / BFF pattern
    if (kIsWeb) {
      return SecureStorage(await SharedPreferences.getInstance(), null);
    }
    return SecureStorage(null, const FlutterSecureStorage());
  }

  Future<String?> read(String key) async {
    if (_web != null) return _web.getString(key);
    try {
      return await _native?.read(key: key);
    } catch (e) {
      debugPrint('[SecureStorage] read($key) failed: $e');
      return null;
    }
  }

  Future<void> write(String key, String value) async {
    if (_web != null) {
      await _web.setString(key, value);
    } else {
      try {
        await _native?.write(key: key, value: value);
      } catch (e) {
        debugPrint('[SecureStorage] write($key) failed: $e');
        // Last-resort fallback: delete corrupted store so next write works.
        try {
          await _native?.deleteAll();
          await _native?.write(key: key, value: value);
        } catch (_) {}
      }
    }
  }

  Future<void> delete(String key) async {
    if (_web != null) {
      await _web.remove(key);
    } else {
      try {
        await _native?.delete(key: key);
      } catch (e) {
        debugPrint('[SecureStorage] delete($key) failed: $e');
      }
    }
  }

  Future<bool> containsKey(String key) async {
    if (_web != null) return _web.containsKey(key);
    try {
      return await _native?.containsKey(key: key) ?? false;
    } catch (e) {
      debugPrint('[SecureStorage] containsKey($key) failed: $e');
      return false;
    }
  }
}

/// Singleton provider — initialized in main.dart before app starts.
final secureStorageProvider = Provider<SecureStorage>((ref) {
  throw StateError('secureStorageProvider not initialized — '
      'call secureStorageProvider.overrideWithValue in main.dart');
});
