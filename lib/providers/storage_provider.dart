import 'package:flutter/foundation.dart';
import 'package:localstorage/localstorage.dart';

class StorageProvider extends ChangeNotifier {
  LocalStorage _storage = new LocalStorage('groovy');
  LocalStorage get storage => _storage;
  set storage(LocalStorage storage) {
    _storage = storage;
    notifyListeners();
  }

  saveItemToStorage(dynamic provider, List list, String key) {
    _storage.setItem(key, provider.toJSONEncodable(list));
    notifyListeners();
  }
}
