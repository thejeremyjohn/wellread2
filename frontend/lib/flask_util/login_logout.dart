import 'package:flutter/material.dart';
import 'package:wellread2frontend/constants.dart';
import 'package:wellread2frontend/flask_util/flask_constants.dart';
import 'package:wellread2frontend/flask_util/flask_response.dart';
import 'package:wellread2frontend/pages/login_page.dart';

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
  if (kNavigatorKey.currentState != null) {
    await kNavigatorKey.currentState!.pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }
}
