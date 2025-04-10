import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ✅ Add this
import 'package:security_iot/providers/app_state.dart'; // ✅ Import your AppState class
import 'package:security_iot/screens/dashboard/dashboard_screen.dart';
import 'package:security_iot/screens/login%20and%20signup/login_and%20_register.dart';
import 'package:security_iot/screens/onboarding/onboarding_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(), // ✅ Provide your AppState here
      child: MaterialApp(
        title: 'Server_security',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        initialRoute: '/dashboard',
        routes: {
          '/': (context) => OnboardingScreen(),
          '/login': (context) => LoginRegisterScreen(),
          '/dashboard': (context) => DashboardScreen(role: 'Admin'),
        },
      ),
    );
  }
}
