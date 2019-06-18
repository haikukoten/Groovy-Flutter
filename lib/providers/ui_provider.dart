import 'package:flutter/foundation.dart';

class UIProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  set isLoading(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }

  bool _isLightTheme = false;
  bool get isLightTheme => _isLightTheme;
  set isLightTheme(bool isLightTheme) {
    _isLightTheme = isLightTheme;
    notifyListeners();
  }
}
