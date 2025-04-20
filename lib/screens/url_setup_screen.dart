import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:security_iot/screens/dashboard/dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UrlSetupScreen extends StatefulWidget {
  final String role;

  const UrlSetupScreen({super.key, required this.role});

  @override
  State<UrlSetupScreen> createState() => _UrlSetupScreenState();
}

class _UrlSetupScreenState extends State<UrlSetupScreen> {
  bool isLoading = true;
  String? error;

  final String baseUrl = 'https://big-wallaby-great.ngrok-free.app/api/v1';
  //  final String baseUrl = 'http://127.0.0.1:8000/api/v1';

  @override
  void initState() {
    super.initState();
    _saveUrlAndAuthenticate(); // Auto-trigger on screen load
  }

  Future<void> _saveUrlAndAuthenticate() async {
    try {
      final tokenUrl = Uri.parse('$baseUrl/token');
      final response = await http.post(
        tokenUrl,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: 'username=admin&password=admin123',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final accessToken = data['access_token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('base_url', baseUrl);
        await prefs.setString('access_token', accessToken);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen(role: widget.role)),
        );
      } else {
        setState(() {
          error = 'Authentication failed: ${response.body}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Authenticating...")),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 40),
                  const SizedBox(height: 16),
                  Text(error ?? 'Unknown error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                ],
              ),
      ),
    );
  }
}
