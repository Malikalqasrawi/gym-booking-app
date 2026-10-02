import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_booking/models/app_user.dart';
import 'package:gym_booking/services/api_client.dart';
import 'package:gym_booking/services/auth_api.dart';
import 'package:gym_booking/widgets/social_sign_in_buttons.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response reply(int status, Map<String, dynamic> body) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

const _googleMember = {
  'id': 7,
  'fullName': 'Malik Qasrawi',
  'email': 'malik@gmail.com',
  'phone': null,
  'role': 'MEMBER',
  'title': 'Member',
  'twoFactorEnabled': false,
  'hasPassword': false,
};

void main() {
  test('Google sign-in sends the ID token and reads a session or the code step', () async {
    final sent = <dynamic>[];
    var withTwoFactor = false;
    final api = AuthApi(ApiClient(httpClient: MockClient((request) async {
      sent.add(jsonDecode(request.body));
      expect(request.url.path, '/api/auth/google');
      return withTwoFactor
          ? reply(200, {'twoFactor': 'CODE_REQUIRED', 'challengeToken': 'c-1'})
          : reply(200, {'token': 'access', 'refreshToken': 'refresh', 'user': _googleMember});
    })));

    final session = await api.loginWithGoogle('google-id-token');
    expect(sent.single, {'idToken': 'google-id-token'});
    expect(session, isA<LoggedIn>().having((r) => r.session.user.needsPhone, 'needsPhone', isTrue));

    withTwoFactor = true;
    expect(await api.loginWithGoogle('google-id-token'),
        isA<TwoFactorChallenge>().having((r) => r.challengeToken, 'challengeToken', 'c-1'));
  });

  test('a Google member has no password and no phone until they add them', () {
    final user = AppUser.fromJson(_googleMember);
    expect(user.hasPassword, isFalse);
    expect(user.needsPhone, isTrue);
    expect(AppUser.fromJson(user.toJson()).hasPassword, isFalse, reason: 'kept when the user is saved on the phone');

    final saved = AppUser.fromJson({'id': 1, 'fullName': 'Sara Haddad', 'email': 's@gym.com', 'phone': '', 'role': 'TRAINER'});
    expect(saved.hasPassword, isTrue, reason: 'users saved before this version had passwords');
    expect(saved.needsPhone, isFalse, reason: 'only members are asked for a phone number');
  });

  test('the phone number is saved with PUT /api/users/me/phone', () async {
    late http.Request sent;
    final api = AuthApi(ApiClient(httpClient: MockClient((request) async {
      sent = request;
      return reply(200, {..._googleMember, 'phone': '0791234567'});
    })));

    final user = await api.updatePhone('0791234567');
    expect(sent.method, 'PUT');
    expect(sent.url.path, '/api/users/me/phone');
    expect(jsonDecode(sent.body), {'phone': '0791234567'});
    expect(user.needsPhone, isFalse);
  });

  testWidgets('without client IDs the Google button explains that it is not set up', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SocialSignInButtons())));
    await tester.tap(find.text('Google'));
    await tester.pump();
    expect(find.text("Google sign-in isn't set up in this build of the app."), findsOneWidget);
    await tester.pump(const Duration(seconds: 5)); // let the message disappear
  });
}
