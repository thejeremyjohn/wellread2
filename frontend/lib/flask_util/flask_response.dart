import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FlaskResponse extends http.Response {
  late Map<String, dynamic> data;
  late String status;
  late String? error;
  bool get isOk => status == 'ok';

  FlaskResponse(http.Response response)
    : super(response.body, response.statusCode, headers: response.headers) {
    data = jsonDecode(response.body);
    status = data['status']!;
    error = data['error'];
  }

  void showSnackBar(
    BuildContext context, {
    String customMessageOnSuccess = '',
  }) {
    bool success = isOk;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isOk && customMessageOnSuccess.isNotEmpty
              ? customMessageOnSuccess
              : '$status${success ? '' : ' --> $error'}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
}
