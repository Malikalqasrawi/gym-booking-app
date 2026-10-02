import 'package:flutter/material.dart';
import 'package:phone_form_field/phone_form_field.dart';

import '../theme/app_theme.dart';
import '../utils/phones.dart';

/// A phone number with a country picker, Jordan first. The number is checked against the chosen
/// country's rules. [mobileOnly] also refuses landlines, since a code can't be texted to them.
class PhoneNumberField extends StatelessWidget {
  const PhoneNumberField({
    super.key,
    required this.controller,
    this.label = 'Phone number',
    this.mobileOnly = true,
    this.isRequired = true,
    this.autofocus = false,
    this.textInputAction,
    this.onSubmitted,
  });

  final PhoneController controller;
  final String label;
  final bool mobileOnly;
  final bool isRequired;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return PhoneFormField(
      controller: controller,
      autofocus: autofocus,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
      autofillHints: const [AutofillHints.telephoneNumber],
      autovalidateMode: AutovalidateMode.disabled, // checked on submit, like the other fields
      countrySelectorNavigator: const CountrySelectorNavigator.draggableBottomSheet(
        favorites: Phones.favoriteCountries,
      ),
      validator: PhoneValidator.compose([
        if (isRequired) PhoneValidator.required(context, errorText: 'Phone number is required'),
        mobileOnly
            ? PhoneValidator.validMobile(context, errorText: 'Enter a valid mobile number for this country')
            : PhoneValidator.valid(context, errorText: 'Enter a valid phone number for this country'),
      ]),
      decoration: AppTheme.input(context, label: label, icon: Icons.phone_outlined),
    );
  }
}
