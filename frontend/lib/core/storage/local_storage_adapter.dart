import 'local_storage_stub.dart'
    if (dart.library.html) 'local_storage_web.dart' as platform_storage;

/// Adaptador multiplataforma para persistência chave-valor simples (localStorage no Web, in-memory stub fora).
class LocalStorageAdapter {
  LocalStorageAdapter._();

  static String? getString(String key) {
    return platform_storage.readStorageString(key);
  }

  static void setString(String key, String value) {
    platform_storage.writeStorageString(key, value);
  }

  static void remove(String key) {
    platform_storage.removeStorageString(key);
  }
}
