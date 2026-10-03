import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_booking/services/api_client.dart';
import 'package:gym_booking/services/auth_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('verifying the email sends the password chosen at sign-up along with the code', () async {
    late http.Request sent;
    final api = AuthApi(ApiClient(httpClient: MockClient((request) async {
      sent = request;
      return http.Response(
        jsonEncode({
          'token': 'access',
          'refreshToken': 'refresh',
          'user': {'id': 9, 'fullName': 'Malik', 'email': 'malik@test.com', 'role': 'MEMBER'},
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    })));

    final result = await api.verifyEmail(email: 'malik@test.com', code: '123456', password: 'Secret1234');

    expect(sent.url.path, '/api/auth/verify');
    expect(jsonDecode(sent.body), {'email': 'malik@test.com', 'code': '123456', 'password': 'Secret1234'});
    expect(result.user.fullName, 'Malik');
  });
}
