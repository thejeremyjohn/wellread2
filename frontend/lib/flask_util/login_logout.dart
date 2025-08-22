import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:wellread2frontend/constants.dart';
import 'package:wellread2frontend/flask_util/flask_constants.dart';
import 'package:wellread2frontend/flask_util/flask_response.dart';

Future<FlaskResponse> login(String email, String password) async {
  final endpoint = Uri.parse('$flaskServer/login');
  final body = {'email': email, 'password': password};
  final r = await client.post(endpoint, body: body) as FlaskResponse;
  if (r.isOk) {
    await storage.write(key: 'accessToken', value: r.data['access_token']);
    await storage.write(key: 'refreshToken', value: r.data['refresh_token']);
  }
  return r;
}

Future<void> logout() async {
  await storage.deleteAll();
  BuildContext? context = kRootNavKey.currentContext;
  if (context != null && context.mounted) context.go('/login');
}

Future<bool> isLoggedIn() async =>
    await storage.containsKey(key: 'accessToken');
