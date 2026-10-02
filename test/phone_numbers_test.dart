import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_booking/models/app_user.dart';
import 'package:gym_booking/services/api_client.dart';
import 'package:gym_booking/services/auth_api.dart';
import 'package:gym_booking/utils/phones.dart';
import 'package:gym_booking/widgets/phone_number_field.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:phone_form_field/phone_form_field.dart';

http.Response reply(int status, Map<String, dynamic> body) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

const _member = {
  'id': 3,
  'fullName': 'Malik Qasrawi',
  'email': 'malik@test.com',
  'phone': '+962791234567',
  'phoneVerified': false,
  'role': 'MEMBER',
};

void main() {
  test('saved numbers are shown with their country code; old ones without it are Jordanian', () {
    expect(Phones.display('+962791234567'), '+962 7 9123 4567');
    expect(Phones.display('0791234567'), '+962 7 9123 4567');
    expect(Phones.display('+966501234567'), '+966 50 123 4567');
    expect(Phones.display('12345'), '12345', reason: 'not a valid number: shown as it was saved');
    expect(Phones.controller().value.isoCode, IsoCode.JO, reason: 'Jordan is picked by default');
    expect(Phones.controller('+966501234567').value.isoCode, IsoCode.SA);
  });

  test('a member must confirm their phone before booking; trainers don\'t', () {
    final member = AppUser.fromJson(_member);
    expect(member.mustConfirmPhone, isTrue);
    expect(AppUser.fromJson({..._member, 'phoneVerified': true}).mustConfirmPhone, isFalse);
    expect(AppUser.fromJson({..._member, 'role': 'TRAINER'}).mustConfirmPhone, isFalse);
    expect(AppUser.fromJson(member.withTwoFactor(true).toJson()).mustConfirmPhone, isTrue,
        reason: 'kept when the user is saved on the phone');
  });

  test('the code is requested and confirmed through the API', () async {
    final requests = <http.Request>[];
    final api = AuthApi(ApiClient(httpClient: MockClient((request) async {
      requests.add(request);
      return request.url.path.endsWith('/code')
          ? reply(200, {'phone': '+962791234567', 'resendAfterSeconds': 60, 'expiresInMinutes': 10})
          : reply(200, {..._member, 'phoneVerified': true});
    })));

    expect(await api.sendPhoneCode(), 60);
    expect(requests.last.url.path, '/api/users/me/phone/code');

    final user = await api.confirmPhone('123456');
    expect(requests.last.url.path, '/api/users/me/phone/confirm');
    expect(jsonDecode(requests.last.body), {'code': '123456'});
    expect(user.phoneVerified, isTrue);
  });

  group('PhoneNumberField', () {
    late PhoneController controller;
    late GlobalKey<FormState> form;

    Future<void> show(WidgetTester tester, {bool mobileOnly = true}) async {
      controller = Phones.controller();
      form = GlobalKey<FormState>();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Form(key: form, child: PhoneNumberField(controller: controller, mobileOnly: mobileOnly)),
        ),
      ));
    }

    testWidgets('a Jordanian mobile number is accepted and sent with +962', (tester) async {
      await show(tester);
      expect(find.text('+ 962'), findsOneWidget, reason: 'Jordan by default');

      await tester.enterText(find.byType(TextField), '0791234567');
      await tester.pump();
      expect(form.currentState!.validate(), isTrue);
      expect(controller.value.international, '+962791234567');
    });

    testWidgets('076 is not a Jordanian mobile number, and a landline gets no SMS', (tester) async {
      await show(tester);
      await tester.enterText(find.byType(TextField), '0761234567');
      await tester.pump();
      expect(form.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Enter a valid mobile number for this country'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '064612345');
      await tester.pump();
      expect(form.currentState!.validate(), isFalse, reason: 'landline');
    });

    testWidgets('a branch may use a landline', (tester) async {
      await show(tester, mobileOnly: false);
      await tester.enterText(find.byType(TextField), '064612345');
      await tester.pump();
      expect(form.currentState!.validate(), isTrue);
      expect(controller.value.international, '+96264612345');
    });
  });
}
