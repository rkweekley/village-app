import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wraps FlutterSecureStorage on native and SharedPreferences on web.
///
/// On web, FlutterSecureStorage throws MissingPluginException, so we use
/// SharedPreferences (localStorage) for web and FlutterSecureStorage (Keychain
/// / EncryptedSharedPreferences) for Android/iOS native.
class SecureStorage {
  final SharedPreferences? _web;
  final FlutterSecureStorage? _native;

  SecureStorage(this._web, this._native);

  static Future<SecureStorage> create() async {
    if (kIsWeb) {
      return SecureStorage(await SharedPreferences.getInstance(), null);
    }
    return SecureStorage(null, const FlutterSecureStorage());
  }

  Future<String?> read(String key) async {
    if (_web != null) return _web.getString(key);
    return await _native?.read(key: key);
  }

  Future<void> write(String key, String value) async {
    if (_web != null) {
      await _web.setString(key, value);
    } else {
      await _native?.write(key: key, value: value);
    }
  }

  Future<void> delete(String key) async {
    if (_web != null) {
      await _web.remove(key);
    } else {
      await _native?.delete(key: key);
    }
  }

  Future<bool> containsKey(String key) async {
    if (_web != null) return _web.containsKey(key);
    return await _native?.containsKey(key: key) ?? false;
  }
}

/// Singleton provider — initialized in main.dart before app starts.
final secureStorageProvider = Provider<SecureStorage>((ref) {
  throw StateError('secureStorageProvider not initialized — '
      'call secureStorageProvider.overrideWithValue in main.dart');
});
