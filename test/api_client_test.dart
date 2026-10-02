import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_booking/services/api_client.dart';
import 'package:gym_booking/services/api_exception.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response reply(int status, Map<String, dynamic> body) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

void main() {
  test('an expired access token is renewed once and the request retried', () async {
    final seen = <String>[];
    final client = ApiClient(httpClient: MockClient((request) async {
      seen.add('${request.url.path} ${request.headers['Authorization'] ?? '-'}');
      if (request.url.path == '/api/auth/refresh') {
        expect(jsonDecode(request.body), {'refreshToken': 'refresh-1'});
        return reply(200, {'token': 'access-2', 'refreshToken': 'refresh-2'});
      }
      return request.headers['Authorization'] == 'Bearer access-2'
          ? reply(200, {'fullName': 'Malik'})
          : reply(401, {'code': 'UNAUTHORIZED', 'message': 'Your session has ended. Please log in again.'});
    }))
      ..token = 'access-1'
      ..refreshToken = 'refresh-1';
    final saved = <String>[];
    client.onTokensRefreshed = (token, refreshToken) => saved.addAll([token, refreshToken]);

    final me = await client.get('/api/users/me');

    expect(me['fullName'], 'Malik');
    expect(seen, ['/api/users/me Bearer access-1', '/api/auth/refresh -', '/api/users/me Bearer access-2']);
    expect(client.token, 'access-2');
    expect(client.refreshToken, 'refresh-2');
    expect(saved, ['access-2', 'refresh-2']);
  });

  test('requests that fail at the same time share one refresh', () async {
    var refreshes = 0;
    final client = ApiClient(httpClient: MockClient((request) async {
      if (request.url.path == '/api/auth/refresh') {
        refreshes++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return reply(200, {'token': 'access-2', 'refreshToken': 'refresh-2'});
      }
      return request.headers['Authorization'] == 'Bearer access-2' ? reply(200, {}) : reply(401, {});
    }))
      ..token = 'access-1'
      ..refreshToken = 'refresh-1';

    await Future.wait([client.get('/api/bookings/mine'), client.get('/api/branches'), client.get('/api/users/me')]);

    expect(refreshes, 1, reason: 'a refresh token works only once');
  });

  test('a refused refresh token ends the session', () async {
    final client = ApiClient(httpClient: MockClient((request) async =>
        reply(401, {'code': 'SESSION_ENDED', 'message': 'Your session has ended. Please log in again.'})))
      ..token = 'access-1'
      ..refreshToken = 'refresh-1';
    var ended = false;
    client.onSessionEnded = () => ended = true;

    await expectLater(client.get('/api/users/me'), throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)));
    expect(ended, isTrue);
  });

  test('no network during the refresh keeps the session', () async {
    final client = ApiClient(httpClient: MockClient((request) async {
      if (request.url.path == '/api/auth/refresh') throw http.ClientException('offline');
      return reply(401, {});
    }))
      ..token = 'access-1'
      ..refreshToken = 'refresh-1';
    var ended = false;
    client.onSessionEnded = () => ended = true;

    await expectLater(client.get('/api/users/me'), throwsA(isA<ApiException>().having((e) => e.isNetworkError, 'network', true)));
    expect(ended, isFalse);
    expect(client.refreshToken, 'refresh-1');
  });
}
