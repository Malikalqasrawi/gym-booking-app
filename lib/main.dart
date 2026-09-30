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

  // 1. Create the objects the whole app shares (one of each)
  final apiClient = ApiClient();
  final authApi = AuthApi(apiClient);
  final bookingApi = BookingApi(apiClient);   // same ApiClient → same login token
  final session = SessionController(
    apiClient: apiClient,
    authApi: authApi,
    storage: SessionStorage(),
  );
  final themeController = ThemeController();

  // 2. Load saved settings: theme choice + "am I still logged in?"
  await Future.wait([themeController.load(), session.restore()]);

  // 3. Provide them to every screen below (screens use context.read / context.watch)
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
    // Rebuilds when the user taps the sun/moon button
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
