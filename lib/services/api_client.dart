import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_exception.dart';

/// One place that talks HTTP to the Java backend.
///
/// Every request:
///   1. adds  Content-Type: application/json
///   2. adds  `Authorization: Bearer <token>`  (if we're logged in)
///   3. turns the JSON answer into a Dart Map
///   4. turns error answers into an ApiException
class ApiClient {
  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  /// Set after login, cleared on logout.
  String? token;

  Future<Map<String, dynamic>> get(String path) => _send('GET', path);

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) =>
      _send('POST', path, body: body);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final request = http.Request(method, Uri.parse('${ApiConfig.baseUrl}$path'));
    request.headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final http.Response response;
    try {
      final streamed = await _http.send(request).timeout(ApiConfig.timeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException.network('The server took too long to answer.');
    } on http.ClientException {
      throw ApiException.network();
    }

    final Map<String, dynamic> json = _decode(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    }
    throw ApiException.fromJson(response.statusCode, json);
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.bodyBytes.isEmpty) return {};
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return decoded is Map<String, dynamic> ? decoded : {'data': decoded};
    } on FormatException {
      return {'message': 'Unexpected response from server (${response.statusCode})'};
    }
  }
}
