import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A secure storage implementation for Supabase sessions using [FlutterSecureStorage].
///
/// This ensures session tokens are encrypted on-device and are not cleared
/// under typical operating system cache cleanup.
class SecureLocalStorage extends LocalStorage {
  const SecureLocalStorage();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() {
    const storage = FlutterSecureStorage();
    return storage.containsKey(key: supabasePersistSessionKey);
  }

  @override
  Future<String?> accessToken() {
    const storage = FlutterSecureStorage();
    return storage.read(key: supabasePersistSessionKey);
  }

  @override
  Future<void> removePersistedSession() {
    const storage = FlutterSecureStorage();
    return storage.delete(key: supabasePersistSessionKey);
  }

  @override
  Future<void> persistSession(String value) {
    const storage = FlutterSecureStorage();
    return storage.write(key: supabasePersistSessionKey, value: value);
  }
}
