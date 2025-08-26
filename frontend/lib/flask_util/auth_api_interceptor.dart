import 'package:flutter/foundation.dart';
import 'package:wellread2frontend/constants.dart';
import 'package:wellread2frontend/flask_util/flask_response.dart';
import 'package:http/http.dart' as http;
import 'package:http_interceptor/http_interceptor.dart';

class AuthApiInterceptor implements InterceptorContract {
  @override
  Future<http.BaseRequest> interceptRequest({
    required http.BaseRequest request,
  }) async {
    try {
      // Skip login and login_refresh(which needs refreshToken) endpoints
      String pathPattern = r'(/login|/login_refresh)';
      if (RegExp(pathPattern).hasMatch(request.url.path)) return request;
      // add accessToken to request headers
      String? accessToken = await storage.read(key: 'accessToken');
      request.headers["Authorization"] = "Bearer $accessToken";
    } catch (e) {
      if (kDebugMode) print(e);
    }
    return request;
  }

  @override
  Future<FlaskResponse> interceptResponse({
    required http.BaseResponse response,
  }) async => FlaskResponse(response as http.Response);

  @override
  Future<bool> shouldInterceptRequest() async => true;

  @override
  Future<bool> shouldInterceptResponse() async => true;
}
