import 'package:flutter/material.dart';
import 'package:wellread2frontend/constants.dart';
import 'package:wellread2frontend/flask_util/flask_methods.dart';
import 'package:wellread2frontend/models/user.dart';

class UserState extends ChangeNotifier {
  bool _isUser = false;
  Future<bool> get isUser async {
    if (!_isUser) {
      // refresh user
      final endpoint = flaskUri('/login_refresh');
      String? refreshToken = await storage.read(key: 'refreshToken');
      final headers = {'Authorization': 'Bearer $refreshToken'};
      final r = await flaskPost(endpoint, headers: headers);
      if (r.isOk) setUserFromJson(r.data['user']);
      return _isUser;
    }
    return _isUser;
  }

  late User _user;
  User get user => _user;

  set user(User u) {
    _user = u;
    _isUser = true;
    notifyListeners();
  }

  setUserFromJson(Map<String, dynamic> json) => user = User.fromJson(json);
}
