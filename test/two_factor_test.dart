import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_booking/models/app_user.dart';
import 'package:gym_booking/models/two_factor.dart';
import 'package:gym_booking/screens/auth/two_factor_code_screen.dart';
import 'package:gym_booking/screens/auth/two_factor_setup_screen.dart';
import 'package:gym_booking/services/api_client.dart';
import 'package:gym_booking/services/auth_api.dart';
import 'package:gym_booking/services/session_storage.dart';
import 'package:gym_booking/state/session_controller.dart';
import 'package:gym_booking/utils/validators.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

http.Response reply(int status, Map<String, dynamic> body) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

void main() {
  test('login answers with a session, a code step, or the setup an admin must do first', () async {
    final api = AuthApi(ApiClient(httpClient: MockClient((request) async {
      final email = (jsonDecode(request.body) as Map<String, dynamic>)['email'];
      if (email == 'admin@gym.com') return reply(200, {'twoFactor': 'SETUP_REQUIRED', 'challengeToken': 'c-admin'});
      if (email == 'malik@test.com') return reply(200, {'twoFactor': 'CODE_REQUIRED', 'challengeToken': 'c-malik'});
      return reply(200, {
        'token': 'access',
        'refreshToken': 'refresh',
        'user': {'id': 1, 'fullName': 'Sara Haddad', 'email': email, 'role': 'TRAINER', 'twoFactorEnabled': false},
      });
    })));

    expect(await api.login(email: 'sara.trainer@gym.com', password: 'x'),
        isA<LoggedIn>().having((r) => r.session.token, 'token', 'access'));
    expect(
        await api.login(email: 'malik@test.com', password: 'x'),
        isA<TwoFactorChallenge>()
            .having((r) => r.setupRequired, 'setupRequired', false)
            .having((r) => r.challengeToken, 'challengeToken', 'c-malik'));
    expect(await api.login(email: 'admin@gym.com', password: 'x'),
        isA<TwoFactorChallenge>().having((r) => r.setupRequired, 'setupRequired', true));
  });

  test('setup key is shown in groups of 4; users saved before this version have two-factor off', () {
    const setup = TwoFactorSetup(secret: 'JBSWY3DPEHPK3PXPJBSWY3DPEHPK3PXP', otpauthUri: 'otpauth://totp/x');
    expect(setup.groupedSecret, 'JBSW Y3DP EHPK 3PXP JBSW Y3DP EHPK 3PXP');

    final oldUser = AppUser.fromJson({'id': 1, 'fullName': 'Malik', 'email': 'm@test.com', 'role': 'ADMIN'});
    expect(oldUser.twoFactorEnabled, isFalse);
    expect(oldUser.mustUseTwoFactor, isTrue);
    expect(AppUser.fromJson(oldUser.withTwoFactor(true).toJson()).twoFactorEnabled, isTrue);
  });

  test('code fields accept app codes and recovery codes, with or without the dash', () {
    expect(Validators.twoFactorCode('123456'), isNull);
    expect(Validators.twoFactorCode('k7m2p-x9qrt'), isNull);
    expect(Validators.twoFactorCode('K7M2PX9QRT'), isNull);
    expect(Validators.twoFactorCode('12345'), isNotNull);
    expect(Validators.recoveryCode('k7m2p-x9qrt'), isNull);
    expect(Validators.recoveryCode('123456'), isNotNull);
  });

  testWidgets('setup: a code from the app turns it on, then the recovery codes are shown', (tester) async {
    String? sentCode;
    var done = false;
    await tester.pumpWidget(MaterialApp(
      home: TwoFactorSetupScreen(
        setup: const TwoFactorSetup(
          secret: 'JBSWY3DPEHPK3PXPJBSWY3DPEHPK3PXP',
          otpauthUri: 'otpauth://totp/Gym%20Booking:malik%40test.com?secret=JBSWY3DPEHPK3PXPJBSWY3DPEHPK3PXP',
        ),
        confirm: (code) async {
          sentCode = code;
          return ['abcde-fghjk', 'mnpqr-stuvw'];
        },
        onDone: (_) async => done = true,
      ),
    ));
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('JBSW Y3DP EHPK 3PXP JBSW Y3DP EHPK 3PXP'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.ensureVisible(find.text('Turn on'));
    await tester.tap(find.text('Turn on'));
    await tester.pumpAndSettle();

    expect(sentCode, '123456');
    expect(find.text('abcde-fghjk'), findsOneWidget);
    expect(find.text('mnpqr-stuvw'), findsOneWidget);
    expect(done, isFalse, reason: 'only the button leaves the codes screen');

    await tester.ensureVisible(find.text('I saved my recovery codes'));
    await tester.tap(find.text('I saved my recovery codes'));
    await tester.pump();
    expect(done, isTrue);
  });

  testWidgets('code step: a recovery code can be used instead, and errors are shown', (tester) async {
    final requests = <http.Request>[];
    final client = ApiClient(httpClient: MockClient((request) async {
      requests.add(request);
      return reply(400, {'code': 'INVALID_TWO_FACTOR_CODE', 'message': 'The code is not correct.'});
    }));
    final api = AuthApi(client);

    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<AuthApi>.value(value: api),
        ChangeNotifierProvider(
            create: (_) => SessionController(apiClient: client, authApi: api, storage: SessionStorage())),
      ],
      child: const MaterialApp(home: TwoFactorCodeScreen(challengeToken: 'challenge-1')),
    ));

    await tester.tap(find.text("Don't have your phone? Use a recovery code"));
    await tester.pump();
    expect(find.text('Recovery code'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'k7m2p-x9qrt');
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    expect(requests.single.url.path, '/api/auth/login/2fa');
    expect(jsonDecode(requests.single.body), {'challengeToken': 'challenge-1', 'code': 'k7m2p-x9qrt'});
    expect(find.text('The code is not correct.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5)); // let the message disappear
  });
}
