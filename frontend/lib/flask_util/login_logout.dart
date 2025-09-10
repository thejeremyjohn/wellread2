import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wellread2frontend/constants.dart';
import 'package:wellread2frontend/flask_util/flask_methods.dart';
import 'package:wellread2frontend/flask_util/flask_response.dart';
import 'package:wellread2frontend/providers/user_state.dart';

Future<FlaskResponse> login(String email, String password) async {
  final endpoint = flaskUri('/login');
  final body = {'email': email, 'password': password};
  final r = await flaskPost(endpoint, body: body);
  if (r.isOk) {
    // only needed if implementing UserState provider
    BuildContext? context = kRootNavKey.currentContext;
    if (context != null && context.mounted) {
      context.read<UserState>().setUserFromJson(r.data['user']);
    }
    // always needed
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

Future<bool> isLoggedIn(BuildContext context) async {
  final List<bool> results = await Future.wait([
    // only needed if implementing UserState provider
    context.read<UserState>().isUser,
    // always needed
    storage.containsKey(key: 'accessToken'),
  ]);
  return results[0] && results[1];
}
