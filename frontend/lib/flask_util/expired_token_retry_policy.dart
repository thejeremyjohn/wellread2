import 'package:wellread2frontend/flask_util/flask_constants.dart';
import 'package:wellread2frontend/flask_util/flask_response.dart';
import 'package:wellread2frontend/flask_util/login_logout.dart';
import 'package:http_interceptor/http_interceptor.dart';
import 'package:http/http.dart' as http;

class ExpiredTokenRetryPolicy extends RetryPolicy {
  @override
  Future<bool> shouldAttemptRetryOnResponse(http.BaseResponse response) async {
    if (response.statusCode == 440 &&
        !response.request!.url.path.endsWith('/login_refresh')) {
      final endpoint = Uri.parse('$flaskServer/login_refresh');
      String? refreshToken = await storage.read(key: 'refreshToken');
      final headers = {'Authorization': 'Bearer $refreshToken'};
      final r = await client.post(endpoint, headers: headers) as FlaskResponse;

      if (r.isOk) {
        await storage.write(key: 'accessToken', value: r.data['access_token']);
        return true;
      }
      logout();
      return false;
    }
    return false;
  }
}
