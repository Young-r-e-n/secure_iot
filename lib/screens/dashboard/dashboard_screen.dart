import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:security_iot/screens/dashboard/dashboardviews/control_and_alert_screen.dart';
import 'package:security_iot/screens/dashboard/dashboardviews/home_screen.dart';
import 'package:security_iot/screens/dashboard/dashboardviews/logs_screen.dart';
import 'dart:convert';
import 'package:security_iot/screens/dashboard/dashboardviews/manage_users.dart';
import 'package:security_iot/screens/dashboard/dashboardviews/notifications_screen.dart';
import 'package:security_iot/services/network_service.dart';
import 'package:shared_preferences/shared_preferences.dart';



class DashboardScreen extends StatefulWidget {
  final String role;

  const DashboardScreen({super.key, required this.role});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  NetworkService? networkService;
  bool _isLoadingService = true;

  int _currentIndex = 0;
  final String baseUrl = 'https://clarence.fhmconsultants.com/api';



@override
void initState() {
  super.initState();
  _initializeNetworkService();
}

Future<void> _initializeNetworkService() async {
  try {
    final service = await NetworkService.create();
    setState(() {
      networkService = service;
      _isLoadingService = false;
    });
  } catch (e) {
    setState(() {
      _isLoadingService = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to initialize network service: $e')),
    );
  }
}




Future<void> _logout() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if 'access_token' and 'base_url' are stored, then remove them
    bool hasAccessToken = prefs.containsKey('access_token');
    bool hasBaseUrl = prefs.containsKey('base_url');
    
    if (hasAccessToken) {
      await prefs.remove('access_token');
    }
    if (hasBaseUrl) {
      await prefs.remove('base_url');
    }
    
    // Navigate to login screen after clearing data
    Navigator.pushReplacementNamed(context, '/login');
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Logout error: $e')),
    );
  }
}


  @override
Widget build(BuildContext context) {
  if (_isLoadingService) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  return Scaffold(
    backgroundColor: Colors.blue.shade50,
    appBar: AppBar(
      title: Text('Dashboard - ${widget.role}', style: const TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF1E40AF),
      actions: [
        IconButton(
          icon: const Icon(Icons.exit_to_app),
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
  if (index == 5 || (index == 2 && widget.role != 'Admin')) {
    _logout();
  } else {
    setState(() {
      _currentIndex = index;
    });
  }
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
  if (widget.role == 'Admin')
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
    if (index == 0) return HomeScreen();
    if (index == 1) return NotificationsScreen();
    
  }

  switch (index) {
    case 0: return HomeScreen();
    case 1:  if (networkService != null) {
        return ControlAndAlertScreen(networkService: networkService!);
      } else {
        return const Center(child: Text('Network Service not available'));
      }
    case 2: return LogsScreen();
    case 3: return NotificationsScreen();
    case 4: return ManageUsersScreen();
    default: return const Center(child: Text('Invalid Option'));
  }
}

}
