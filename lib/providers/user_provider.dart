import 'package:flutter/foundation.dart';
import '../models/user.dart';

class UserProvider extends ChangeNotifier {
  User _currentUser;
  User get currentUser => _currentUser;
  set currentUser(User currentUser) {
    _currentUser = currentUser;
    notifyListeners();
  }

  List<User> _userList = [];
  List<User> get userList => _userList;
  set userList(List<User> userList) {
    _userList = userList;
    notifyListeners();
  }
}
