import 'package:http/http.dart' as http;
import 'package:wellread2frontend/flask_util/auth_api_interceptor.dart';
import 'package:wellread2frontend/flask_util/expired_token_retry_policy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_interceptor/http/intercepted_client.dart';

const flaskServer = 'http://localhost:5000';
const storage = FlutterSecureStorage();

http.Client client = InterceptedClient.build(
  interceptors: [AuthApiInterceptor()],
  retryPolicy: ExpiredTokenRetryPolicy(),
  client: http.Client(),
);
