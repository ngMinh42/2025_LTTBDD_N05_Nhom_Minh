import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/main_navigation.dart';
import 'screens/pin_lock_screen.dart';
import 'screens/login_page.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getInitialScreen() async {
    final authService = AuthService();
    final prefs = await SharedPreferences.getInstance();

    final isLoggedIn = await authService.isLoggedIn();
    final hasPin = prefs.getString('app_pin') != null;

    print('Debug: isLoggedIn = $isLoggedIn, hasPin = $hasPin');

    if (!isLoggedIn) {
      return LoginPage(
        onLoginSuccess: () {
          runApp(const MyApp());
        },
      );
    }

    if (hasPin) {
      return const PinLockScreen(mode: 'verify');
    } else {
      return const MainNavigation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {'/main': (_) => const MainNavigation()},
      home: FutureBuilder<Widget>(
        future: _getInitialScreen(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data!;
        },
      ),
    );
  }
}
