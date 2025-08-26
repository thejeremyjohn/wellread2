import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_interceptor/http/intercepted_client.dart';
import 'package:wellread2frontend/flask_util/auth_api_interceptor.dart';
import 'package:wellread2frontend/flask_util/expired_token_retry_policy.dart';
import 'package:wellread2frontend/flask_util/flask_constants.dart';
import 'package:wellread2frontend/flask_util/flask_response.dart';

Uri flaskUri(
  String? path, {
  Map<String, dynamic> queryParameters = const {},
  List<String> addProps = const [],
  List<String> expand = const [],
}) {
  if (addProps.isNotEmpty) queryParameters['add_props'] = addProps.join(',');
  if (expand.isNotEmpty) queryParameters['expand'] = expand.join(',');
  return Uri(
    scheme: flaskScheme,
    host: flaskHost,
    port: flaskPort,
    path: path,
    queryParameters: queryParameters,
  );
}

http.Client _client = InterceptedClient.build(
  interceptors: [AuthApiInterceptor()],
  retryPolicy: ExpiredTokenRetryPolicy(),
  client: http.Client(),
);

Future<FlaskResponse> flaskGet(Uri url, {Map<String, String>? headers}) async {
  return await _client.get(url, headers: headers) as FlaskResponse;
}

Future<FlaskResponse> flaskPost(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) async {
  return await _client.post(
        url,
        headers: headers,
        body: body,
        encoding: encoding,
      )
      as FlaskResponse;
}

Future<FlaskResponse> flaskPut(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) async {
  return await _client.put(
        url,
        headers: headers,
        body: body,
        encoding: encoding,
      )
      as FlaskResponse;
}

Future<FlaskResponse> flaskDelete(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) async {
  return await _client.delete(
        url,
        headers: headers,
        body: body,
        encoding: encoding,
      )
      as FlaskResponse;
}
