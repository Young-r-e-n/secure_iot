import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isAuthenticated = false;

  Map<String, dynamic>? systemData;
  bool isLoading = true;
  String? error;
  String currentTime = '';

  final Color primaryColor = const Color(0xFF1E40AF);
  final Color cardColor = Colors.white;
  final Color backgroundColor = Color(0xFFF3F4F6);


final TextEditingController _urlController = TextEditingController();
String? _accessToken;

@override
void initState() {
  super.initState();
  _loadAuthData(); // Load saved authentication data

  // Check if URL is available before trying to fetch system status
  if (_urlController.text.isNotEmpty) {
    fetchSystemStatus(); // Only fetch if URL is not empty
  }

  startClock();
}

  void startClock() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        currentTime = TimeOfDay.now().format(context);
      });
    });
  }

Future<void> _loadAuthData() async {
  final prefs = await SharedPreferences.getInstance();
  final savedUrl = prefs.getString('base_url');
  final savedToken = prefs.getString('access_token');

  if (savedUrl != null && savedToken != null) {
    _urlController.text = savedUrl;
    _accessToken = savedToken;
    setState(() {
      isAuthenticated = true;
    });
    fetchSystemStatus(savedUrl);
  }
}


Future<void> authenticateAndFetchStatus() async {
  final url = _urlController.text.trim();
  if (url.isEmpty) return;

  final tokenUrl = Uri.parse('$url/token');
  try {
    final response = await http.post(
      tokenUrl,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: 'username=admin&password=admin123',
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _accessToken = data['access_token'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('base_url', url);
      await prefs.setString('access_token', _accessToken!);

      setState(() {
        isAuthenticated = true;
      });

      fetchSystemStatus(url);
    } else {
      throw Exception('Failed to authenticate: ${response.body}');
    }
  } catch (e) {
    setState(() {
      error = 'Auth error: $e';
      isLoading = false;
    });
  }
}


Future<void> fetchSystemStatus([String? baseUrl]) async {
  setState(() {
    isLoading = true;
    error = null;
  });

try {
  final base = baseUrl ?? _urlController.text.trim();
  final url = Uri.parse('$base/status');
  print('Requesting: $url');

  final headers = <String, String>{};
  if (_accessToken != null && _accessToken!.isNotEmpty) {
    headers['Authorization'] = 'Bearer $_accessToken';
  }

  final response = await http.get(url, headers: headers);
  print('Response: ${response.body}');

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    setState(() {
      systemData = data;
      isLoading = false;
    });
  } else {
    throw Exception('Failed to load system status: ${response.statusCode}');
  }
} catch (e) {
  setState(() {
    error = e.toString();
    isLoading = false;
  });
}

}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
   
      body: Padding(
  padding: const EdgeInsets.all(16),
  child: Column(
  children: [
    if (!isAuthenticated) ...[
      TextField(
        controller: _urlController,
        decoration: InputDecoration(
          labelText: 'Enter Base URL',
          hintText: 'e.g., https://your-api.com',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 10),
      ElevatedButton(
        onPressed: authenticateAndFetchStatus,
        child: const Text('Authenticate & Load System'),
      ),
      const SizedBox(height: 20),
    ],
    Expanded(
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : _buildDashboard(),
    ),
  ],
),
),
    );
  }

  Widget _buildDashboard() {
    final sensors = systemData!['sensors'] as Map<String, dynamic>;
    final pi = systemData!['raspberry_pi'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _clockWidget(),
          const SizedBox(height: 20),

          // System Overview
     _dashboardSection("System Overview", [
  _infoCard(Icons.health_and_safety, "Status", (systemData!['status'] ?? 'N/A').toString()),
  _infoCard(Icons.timer, "Uptime", (systemData!['uptime'] ?? 'N/A').toString()),
  _infoCard(Icons.sd_storage, "Storage Used", (systemData!['storage']?['used'] ?? 'N/A').toString()),
  _infoCard(Icons.warning, "Low Storage", (systemData!['storage']?['low_space'] ?? false) ? "Yes" : "No"),
]),

       _dashboardSection("Raspberry Pi", [
  _infoCard(Icons.online_prediction, "Online", (pi?['is_online'] ?? false) ? "Yes" : "No"),
  _infoCard(Icons.access_time, "Last Heartbeat", (pi?['last_heartbeat'] ?? 'N/A').toString()),
  _infoCard(Icons.memory, "Firmware", (pi?['firmware_version'] ?? 'Unknown').toString()),
  _infoCard(Icons.bar_chart, "Total Events", (pi?['total_events'] ?? 0).toString()),
]),

          _sectionTitle("Sensors"),
          ...sensors.entries.map((entry) => _sensorCard(entry.value)).toList(),
        ],
      ),
    );
  }

  Widget _clockWidget() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text(
              "Live System Time",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              currentTime,
              style: const TextStyle(
                  fontSize: 36,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2),
            ),
          ],
        ),
      );

  Widget _dashboardSection(String title, List<Widget> cards) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: cards,
          ),
          const SizedBox(height: 20),
        ],
      );

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
      );

  Widget _infoCard(IconData icon, String label, String value) => Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: primaryColor, size: 30),
            const SizedBox(height: 10),
            Text(label,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(value,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54)),
          ],
        ),
      );

Widget _sensorCard(dynamic sensor) {
  final isActive = sensor['isActive'] ?? false;
  final error = sensor['error'];

  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    color: Color.fromARGB(255, 255, 255, 255),
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isActive ? Icons.sensors : Icons.sensors_off,
                color: isActive ? Colors.green : Colors.grey,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sensor['name'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green[100] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: isActive ? Colors.green[800] : Colors.grey[800],
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              )
            ],
          ),
          const Divider(height: 20, thickness: 1),
          _infoRow(Icons.access_time, 'Last Check', sensor['last_check']),
          _infoRow(Icons.memory, 'Firmware', sensor['firmware_version'] ?? 'N/A',
              valueColor: Colors.blueGrey[800]),
          _infoRow(Icons.bar_chart, 'Event Count',
              sensor['event_count'].toString()),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Error: $error',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  )
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

Widget _infoRow(IconData icon, String label, String value,
    {Color? valueColor}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: valueColor ?? Colors.black87),
          ),
        ),
      ],
    ),
  );
}
}
