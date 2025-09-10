import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wellread2frontend/constants.dart';
import 'package:wellread2frontend/flask_util/flask_constants.dart';
import 'package:wellread2frontend/flask_util/flask_methods.dart';
import 'package:wellread2frontend/flask_util/login_logout.dart';
import 'package:http_interceptor/http_interceptor.dart';
import 'package:http/http.dart' as http;
import 'package:wellread2frontend/providers/user_state.dart';

class ExpiredTokenRetryPolicy extends RetryPolicy {
  @override
  Future<bool> shouldAttemptRetryOnResponse(http.BaseResponse response) async {
    if (response.statusCode == 440 &&
        !response.request!.url.path.endsWith('/login_refresh')) {
      final endpoint = Uri.parse('$flaskServer/login_refresh');
      String? refreshToken = await storage.read(key: 'refreshToken');
      final headers = {'Authorization': 'Bearer $refreshToken'};
      final r = await flaskPost(endpoint, headers: headers);

      if (r.isOk) {
        // only needed if implementing UserState provider
        BuildContext? context = kRootNavKey.currentContext;
        if (context != null && context.mounted) {
          context.read<UserState>().setUserFromJson(r.data['user']);
        }
        // always needed
        await storage.write(key: 'accessToken', value: r.data['access_token']);

        return true;
      }
      logout();
      return false;
    }
    return false;
  }
}
