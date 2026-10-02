import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_booking/screens/auth/forgot_password_screen.dart';
import 'package:gym_booking/screens/home/main_shell.dart';
import 'package:gym_booking/services/api_client.dart';
import 'package:gym_booking/services/auth_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('forgot password: sending the code shows the reset form', (tester) async {
    final requests = <http.Request>[];
    final api = AuthApi(ApiClient(httpClient: MockClient((request) async {
      requests.add(request);
      return http.Response(
        jsonEncode({'message': 'If an account exists for this email, we sent it a code to reset the password.'}),
        200,
        headers: {'content-type': 'application/json'},
      );
    })));

    await tester.pumpWidget(Provider<AuthApi>.value(
      value: api,
      child: const MaterialApp(home: ForgotPasswordScreen(email: 'malik@test.com')),
    ));
    expect(find.text('Send code'), findsOneWidget);

    await tester.tap(find.text('Send code'));
    // A few frames for the request, the response and the rebuild; no time passes, so the countdown stays at 60.
    for (var i = 0; i < 5 && find.text('Change password').evaluate().isEmpty; i++) {
      await tester.pump();
    }

    expect(requests.single.url.path, '/api/auth/forgot-password');
    expect(jsonDecode(requests.single.body), {'email': 'malik@test.com'});
    expect(find.text('Change password'), findsOneWidget);
    expect(find.text('Resend in 60s'), findsOneWidget);

    // Let the resend countdown finish so no timer is left running.
    await tester.pump(const Duration(seconds: 61));
    expect(find.text('Resend code'), findsOneWidget);
  });

  testWidgets('TabSwitcher.goTo reaches the shell from inside a tab', (tester) async {
    AppTab? selected;
    await tester.pumpWidget(MaterialApp(
      home: TabSwitcher(
        select: (tab) => selected = tab,
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () => TabSwitcher.goTo(context, AppTab.bookings),
            child: const Text('My bookings'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('My bookings'));
    expect(selected, AppTab.bookings);
  });
}
