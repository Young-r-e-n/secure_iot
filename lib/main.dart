import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'package:security_iot/providers/app_state.dart'; 
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
      create: (_) => AppState(), // Provide your AppState here
      child: MaterialApp(
        title: 'Server_security',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF1E40AF)),
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
