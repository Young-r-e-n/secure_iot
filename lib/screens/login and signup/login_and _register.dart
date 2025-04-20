import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:security_iot/screens/url_setup_screen.dart';
import 'dart:convert';


class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  _LoginRegisterScreenState createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen> {
  bool isRegistering = false;
  String _role = 'Staff';
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  String message = '';

Future<void> authenticate(String action) async {
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    _isLoading = true;
    message = '';
  });

  try {
    final response = await http.post(
      Uri.parse('https://clarence.fhmconsultants.com/api/db.php?action=$action'),
      body: {
        'name': _nameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'role': _role,
      },
    );

    //print('Raw Response: ${response.body}');  // Debugging step

    final responseData = json.decode(response.body);
   // print('Decoded Response: $responseData'); // Debugging step

    if (responseData.containsKey('success') && responseData['success']) {
      if (action == 'login') {
        Navigator.pushReplacement(
            context,
  MaterialPageRoute(
    builder: (context) => UrlSetupScreen(role: responseData['role']),
  ),
        );
      } else {
        setState(() => message = responseData['message']);
      }
    } else {
      setState(() => message = responseData['message'] ?? 'Unexpected error.');
    }
  } catch (e) {
    print('Error caught: $e'); // Debugging step
    setState(() => message = 'An error occurred. Please try again.');
  } finally {
    setState(() => _isLoading = false);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E40AF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.security_rounded, size: 80, color: Colors.white),
                    SizedBox(height: 24),
                    Text(
                      isRegistering ? 'Register' : 'Login',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32),
                    if (isRegistering) _buildTextField(_nameController, 'Name', Icons.person),
                    _buildTextField(_emailController, 'Email', Icons.email),
                    _buildTextField(_passwordController, 'Password', Icons.lock, isPassword: true),
                    if (isRegistering) _buildRoleDropdown(),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : () => authenticate(isRegistering ? 'register' : 'login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Color(0xFF1E40AF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E40AF)))
                          : Text(isRegistering ? 'Register' : 'Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() => isRegistering = !isRegistering),
                      child: Text(
                        isRegistering ? 'Already have an account? Login' : 'Don’t have an account? Register',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ),
                    if (message.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text(message, style: TextStyle(color: Colors.red, fontSize: 14), textAlign: TextAlign.center),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          labelText: label,
          labelStyle: TextStyle(color: Colors.white),
          prefixIcon: Icon(icon, color: Colors.white),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
        style: TextStyle(color: Colors.white),
        validator: (value) => value == null || value.isEmpty ? 'Please enter your $label' : null,
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: _role,
        dropdownColor: Color(0xFF1E40AF),
        items: ['Staff', 'Security'].map((String role) {
          return DropdownMenuItem<String>(
            value: role,
            child: Text(role, style: TextStyle(color: Colors.white)),
          );
        }).toList(),
        onChanged: (String? newValue) => setState(() => _role = newValue!),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          labelText: 'Role',
          labelStyle: TextStyle(color: Colors.white),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
