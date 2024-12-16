import 'package:flutter/material.dart';

import '../models/user.dart';

class UserProvider extends ChangeNotifier {
  User? _user;

  User? get user => _user;

  void setUser(User newUser) {
    _user = newUser;
    notifyListeners(); // Notify listeners that the user data has changed
  }

  void clearUser() {
    _user = null;
    notifyListeners(); // Notify listeners that the user has been cleared
  }

  void updateUser({
    String? email,
    String? password,
    String? role,
    String? id,
  }) {
    if (_user != null) {
      _user = _user!.copyWith(
        email: email,
        password: password,
        role: role,
        id: id,
      );
      notifyListeners(); // Notify listeners that the user data has been updated
    }
  }
}
