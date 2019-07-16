import 'package:Groovy/services/user_service.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';

class UserProvider extends ChangeNotifier {
  UserService _userService;
  UserService get userService => _userService;
  set userService(UserService userService) {
    _userService = userService;
    notifyListeners();
  }

  User _currentUser;
  User get currentUser => _currentUser;
  set currentUser(User currentUser) {
    _currentUser = currentUser;
    notifyListeners();
  }

  toJSONEncodable(List<User> list) {
    return list.map((User user) {
      return user.toJson();
    }).toList();
  }
}
