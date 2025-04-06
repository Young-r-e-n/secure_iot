import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:security_iot/screens/dashboard/dashboardviews/controls_screen.dart';
import 'package:security_iot/screens/dashboard/dashboardviews/home_screen.dart';
import 'package:security_iot/screens/dashboard/dashboardviews/logs_screen.dart';
import 'dart:convert';
import 'package:security_iot/screens/dashboard/dashboardviews/manage_users.dart';
import 'package:security_iot/screens/dashboard/dashboardviews/notifications_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  final String role;

  const DashboardScreen({super.key, required this.role});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final String baseUrl = 'https://clarence.fhmconsultants.com/api';

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        await prefs.clear();
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed, please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text('Dashboard - ${widget.role}', style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),),
        backgroundColor: Color(0xFF1E40AF),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: _logout,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
          if (index == 5) _logout();
        });
      },
      selectedItemColor: Color(0xFF1E40AF),
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
   items: [
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),

    if (widget.role == 'Admin')
      BottomNavigationBarItem(
        icon: Icon(Icons.devices),
        label: 'Control',
      ),

    if (widget.role == 'Admin')
      BottomNavigationBarItem(
        icon: Icon(Icons.file_copy),
        label: 'Logs',
      ),

    BottomNavigationBarItem(
      icon: Icon(Icons.notification_important),
      label: 'Notifications',
    ),

    BottomNavigationBarItem(
      icon: Icon(Icons.group),
      label: 'Users',
    ),

    BottomNavigationBarItem(
      icon: Icon(Icons.exit_to_app),
      label: 'Logout',
    ),
  ],
    );
  }

  Widget _buildBody() => _getRoleBasedWidget(_currentIndex);

  Widget _getRoleBasedWidget(int index) {
    if (widget.role != 'Admin') {
      if (index == 0) return  HomeScreen();
      if (index == 1) return LogsScreen();
    }

    switch (index) {
      case 0: return HomeScreen();
      case 1: return ControlsScreen();
      case 2: return LogsScreen();
      case 3: return NotificationsScreen();
      case 4: return ManageUsersScreen();
      case 5: return Center(child: Text('Logging out...'));
      default: return Center(child: Text('Invalid Option'));
    }
  }
}
