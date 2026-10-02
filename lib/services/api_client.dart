import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_exception.dart';

/// JSON HTTP client for the backend. Sends the access token, renews it with the refresh token
/// when the backend answers 401, and maps error responses to [ApiException].
class ApiClient {
  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  /// Short-lived access token, sent with every request.
  String? token;

  /// Traded for a new [token] and [refreshToken] once the access token is rejected.
  String? refreshToken;

  /// Called with the new pair after a refresh, so it can be saved.
  void Function(String token, String refreshToken)? onTokensRefreshed;

  /// Called when the session can't be renewed any more, e.g. after "log out of all devices".
  void Function()? onSessionEnded;

  /// The refresh in progress, shared by all requests that got a 401 at the same time. A refresh
  /// token works only once, so two parallel refreshes would end the session.
  Future<bool>? _refreshing;

  Future<Map<String, dynamic>> get(String path) => _send('GET', path);

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) =>
      _send('POST', path, body: body);

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) =>
      _send('PUT', path, body: body);

  Future<Map<String, dynamic>> delete(String path) => _send('DELETE', path);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final sentToken = token;
    var response = await _request(method, path, body, withToken: true);

    if (response.statusCode == 401 && sentToken != null && refreshToken != null) {
      // Another request may already have renewed the token while this one was on its way.
      final renewed = token != sentToken || await _refreshOnce();
      if (renewed) {
        response = await _request(method, path, body, withToken: true);
      } else {
        onSessionEnded?.call();
      }
    }

    final Map<String, dynamic> json = _decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    }
    throw ApiException.fromJson(response.statusCode, json);
  }

  Future<bool> _refreshOnce() {
    return _refreshing ??= _refresh().whenComplete(() {
      _refreshing = null;
    });
  }

  /// True if the tokens were renewed, false if the backend refused the refresh token. Other
  /// failures (no network, rate limit) throw, so a bad connection doesn't log anyone out.
  Future<bool> _refresh() async {
    final current = refreshToken;
    if (current == null) return false;

    final response = await _request('POST', '/api/auth/refresh', {'refreshToken': current}, withToken: false);
    final json = _decode(response);
    if (response.statusCode == 400 || response.statusCode == 401) return false;
    if (response.statusCode != 200) throw ApiException.fromJson(response.statusCode, json);

    final newToken = json['token'] as String?;
    final newRefreshToken = json['refreshToken'] as String?;
    if (newToken == null || newRefreshToken == null) return false;
    token = newToken;
    refreshToken = newRefreshToken;
    onTokensRefreshed?.call(newToken, newRefreshToken);
    return true;
  }

  Future<http.Response> _request(
    String method,
    String path,
    Map<String, dynamic>? body, {
    required bool withToken,
  }) async {
    final request = http.Request(method, Uri.parse('${ApiConfig.baseUrl}$path'));
    request.headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final current = token;
    if (withToken && current != null) {
      request.headers['Authorization'] = 'Bearer $current';
    }

    try {
      final streamed = await _http.send(request).timeout(ApiConfig.timeout);
      return await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException.network('The server took too long to answer.');
    } on http.ClientException {
      throw ApiException.network();
    }
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
