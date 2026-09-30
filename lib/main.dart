import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/auth/auth_gate.dart';
import 'services/api_client.dart';
import 'services/auth_api.dart';
import 'services/booking_api.dart';
import 'services/session_storage.dart';
import 'state/session_controller.dart';
import 'state/theme_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiClient = ApiClient();
  final authApi = AuthApi(apiClient);
  final bookingApi = BookingApi(apiClient); // shares the auth token held by apiClient
  final session = SessionController(
    apiClient: apiClient,
    authApi: authApi,
    storage: SessionStorage(),
  );
  final themeController = ThemeController();

  await Future.wait([themeController.load(), session.restore()]);

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthApi>.value(value: authApi),
        Provider<BookingApi>.value(value: bookingApi),
        ChangeNotifierProvider<SessionController>.value(value: session),
        ChangeNotifierProvider<ThemeController>.value(value: themeController),
      ],
      child: const GymBookingApp(),
    ),
  );
}

class GymBookingApp extends StatelessWidget {
  const GymBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeController>().mode;

    return MaterialApp(
      title: 'Gym Booking',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const AuthGate(),
    );
  }
}
