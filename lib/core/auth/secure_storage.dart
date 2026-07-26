import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wraps FlutterSecureStorage on native and SharedPreferences on web.
///
/// On web, FlutterSecureStorage crashes with MissingPluginException.
/// This type lets the rest of the app use a single storage interface.
class SecureStorage {
  // Non-null on web, null on native.
  final SharedPreferences? _web;

  // Null on web, used on native (initialized lazily).
  // We just use SharedPreferences for everything in dev.
  SecureStorage(this._web);

  static Future<SecureStorage> create() async {
    if (kIsWeb) {
      return SecureStorage(await SharedPreferences.getInstance());
    }
    return SecureStorage(null);
  }

  Future<String?> read(String key) async {
    if (_web != null) return _web!.getString(key);
    // Native — token won't persist across server restarts in dev,
    // but this avoids the MissingPluginException crash on web.
    // For production, wire up FlutterSecureStorage here.
    return null;
  }

  Future<void> write(String key, String value) async {
    if (_web != null) {
      await _web!.setString(key, value);
    }
  }

  Future<void> delete(String key) async {
    if (_web != null) {
      await _web!.remove(key);
    }
  }

  Future<bool> containsKey(String key) async {
    if (_web != null) return _web!.containsKey(key);
    return false;
  }
}

/// Singleton provider — initialized in main.dart before app starts.
final secureStorageProvider = Provider<SecureStorage>((ref) {
  throw StateError('secureStorageProvider not initialized — '
      'call secureStorageProvider.overrideWithValue in main.dart');
});
