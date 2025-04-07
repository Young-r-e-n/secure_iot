import 'dart:async';
// import 'dart:convert'; // Remove if not needed elsewhere
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting dates/times
import 'package:provider/provider.dart'; // ✅ Add
import '../../../providers/app_state.dart'; // ✅ Add
import '../../../models/system_status.dart'; // ✅ Add

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Remove internal state managed by AppState
  // Map<String, dynamic>? systemData;
  // bool isLoading = true;
  // String? error;
  String currentTime = '';
  Timer? _clockTimer;

  final Color primaryColor = const Color(0xFF1E40AF);
  final Color cardColor = Colors.white;
  final Color backgroundColor = Color(0xFFF3F4F6);
  final DateFormat _dateTimeFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');
  final DateFormat _timeFormatter = DateFormat('HH:mm:ss');

  @override
  void initState() {
    super.initState();
    // Data fetching is handled by AppState's polling or initial load
    // fetchSystemStatus(); // Remove
    startClock();
    // Fetch initial data if needed (though AppState might handle this on login)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ensure AppState is accessed after the first frame
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.currentStatus == null && !appState.isLoading) {
         appState.fetchSystemStatus(); // Trigger fetch if no status yet
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) { // Check if widget is still mounted
        setState(() {
          currentTime = _timeFormatter.format(DateTime.now());
        });
      }
    });
  }

  // Remove old fetchSystemStatus method
  /*
  Future<void> fetchSystemStatus() async {
    // ... old code ...
  }
  */

  @override
  Widget build(BuildContext context) {
    // Consume AppState
    final appState = context.watch<AppState>();
    final isLoading = appState.isLoading && appState.currentStatus == null; // Show loading only if status is null
    final error = appState.error;
    final systemStatus = appState.currentStatus; // Use the typed model

    return Scaffold(
      backgroundColor: backgroundColor,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          // Show error if there's an error and no status data is available
          : error != null && systemStatus == null
              ? Center(
                  child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error loading system status: $error', 
                    style: TextStyle(color: Colors.red[700]),
                    textAlign: TextAlign.center,
                  ),
                ))
              // Show dashboard if status is available (even if there was a recent error)
              : systemStatus != null
                  ? _buildDashboard(systemStatus)
                  // Handle case where not loading, no error, but status is still null (e.g., after logout)
                  : const Center(child: Text('System status not available.')),
    );
  }

  // Pass SystemStatus model to build methods
  Widget _buildDashboard(SystemStatus systemData) {
    final sensors = systemData.sensors; // Use typed Map<String, SensorStatus>
    final pi = systemData.raspberryPi; // Use typed RaspberryPiStatus
    final storage = systemData.storage;

    return RefreshIndicator( // Add pull-to-refresh
      onRefresh: () => Provider.of<AppState>(context, listen: false).fetchSystemStatus(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), // Ensure scrollable even if content fits
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _clockWidget(),
            const SizedBox(height: 20),

            // System Overview
            _dashboardSection("System Overview", [
              _infoCard(Icons.monitor_heart, "Status", systemData.status, cardColor: _getStatusColor(systemData.status)),
              _infoCard(Icons.timer_outlined, "Uptime", systemData.uptime),
              _infoCard(Icons.sd_storage_outlined, "Storage Used", "${storage['used_gb'] ?? '?'} GB / ${storage['total_gb'] ?? '?'} GB"),
              _infoCard(Icons.disc_full, "Low Storage", (storage['low_space'] ?? false) ? "Yes" : "No", cardColor: (storage['low_space'] ?? false) ? Colors.orange[100] : null),
            ]),

            _dashboardSection("Raspberry Pi", [
              _infoCard(pi.isOnline ? Icons.link : Icons.link_off, "Online", pi.isOnline ? "Yes" : "No", cardColor: pi.isOnline ? Colors.green[100] : Colors.red[100]),
              _infoCard(Icons.watch_later_outlined, "Last Heartbeat", _formatDateTime(pi.lastHeartbeat)),
              _infoCard(Icons.memory_outlined, "Firmware", pi.firmwareVersion),
              _infoCard(Icons.event_note, "Total Events", pi.totalEvents.toString()),
            ]),

            _sectionTitle("Sensors (${sensors.length})"),
            if (sensors.isEmpty)
               const Padding(
                 padding: EdgeInsets.symmetric(vertical: 16.0),
                 child: Center(child: Text("No sensor data available.")),
               )
            else
              ...sensors.values.map((sensor) => _sensorCard(sensor)).toList(), // Iterate over values
          ],
        ),
      ),
    );
  }

  Color? _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'healthy':
      case 'online':
        return Colors.green[100];
      case 'degraded':
      case 'warning':
        return Colors.orange[100];
      case 'error':
      case 'offline':
        return Colors.red[100];
      default:
        return null;
    }
  }

  String _formatDateTime(DateTime? dt) {
     if (dt == null) return "N/A";
     // Format relative time for recent timestamps?
     // final now = DateTime.now();
     // if (now.difference(dt).inHours < 24) {
     //   return timeago.format(dt);
     // }
     return _dateTimeFormatter.format(dt);
   }

  Widget _clockWidget() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        child: Column(
          children: [
            const Text(
              "Current System Time", // Updated title
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
          LayoutBuilder( // Use LayoutBuilder for responsive card layout
            builder: (context, constraints) {
              // Adjust crossAxisCount based on available width
              int crossAxisCount = (constraints.maxWidth / 180).floor(); // Target width ~160 + spacing
              crossAxisCount = crossAxisCount.clamp(1, 4); // Min 1, Max 4 cards per row
              return GridView.count(
                 crossAxisCount: crossAxisCount,
                 shrinkWrap: true, // Important inside SingleChildScrollView
                 physics: const NeverScrollableScrollPhysics(), // Grid itself shouldn't scroll
                 mainAxisSpacing: 16,
                 crossAxisSpacing: 16,
                 childAspectRatio: 1.1, // Adjust aspect ratio if needed
                 children: cards,
               );
            }
          ),
          const SizedBox(height: 20),
        ],
      );

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 16), // Add top padding
        child: Text(
          title,
          style: TextStyle(
            fontSize: 20, // Slightly smaller
            fontWeight: FontWeight.w600, // Adjusted weight
            color: Colors.grey[800],
          ),
        ),
      );

  Widget _infoCard(IconData icon, String label, String value, {Color? cardColor}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor ?? this.cardColor, // Use provided color or default
          borderRadius: BorderRadius.circular(12), // Slightly smaller radius
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6, // Reduced blur
              offset: const Offset(0, 2), // Adjusted offset
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center content
          children: [
            Icon(icon, color: primaryColor, size: 28), // Slightly smaller icon
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.black87), // Adjusted style
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w600), // Adjusted style
               maxLines: 2,
               overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );

// Use typed SensorStatus model
Widget _sensorCard(SensorStatus sensor) {
  final isActive = sensor.isActive;
  final error = sensor.error;
  final hasError = error != null && error.isNotEmpty;

  return Card(
    elevation: 2, // Reduced elevation
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    color: hasError ? Colors.red[50] : (isActive ? Colors.green[50] : Colors.grey[100]), // Color based on state
    margin: const EdgeInsets.symmetric(vertical: 6),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                 children: [
                    Icon(
                      hasError ? Icons.error_outline : (isActive ? Icons.check_circle_outline : Icons.pause_circle_outline),
                      color: hasError ? Colors.red[700] : (isActive ? Colors.green[700] : Colors.grey[600]),
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      sensor.name,
                      style: TextStyle(
                         fontSize: 16,
                         fontWeight: FontWeight.w600,
                         color: Colors.grey[850],
                      ),
                    ),
                 ],
              ),
              // Optional: Add indicator for type or location
              if (sensor.type != null)
                 Chip(
                   label: Text(sensor.type!, style: TextStyle(fontSize: 10)),
                   padding: EdgeInsets.zero,
                   visualDensity: VisualDensity.compact,
                   backgroundColor: Colors.blue[50],
                 )
            ],
          ),
          const SizedBox(height: 8),
          if (hasError)
            Text(
              "Error: $error",
              style: TextStyle(color: Colors.red[700], fontSize: 13),
            )
          else
             Text(
               "Status: ${isActive ? 'Active' : 'Inactive'}",
               style: TextStyle(color: Colors.grey[700], fontSize: 13),
             ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(
                 "Last Check: ${_formatDateTime(sensor.lastCheck)}",
                 style: TextStyle(color: Colors.grey[600], fontSize: 12),
               ),
               Text(
                 "Events: ${sensor.eventCount}",
                 style: TextStyle(color: Colors.grey[600], fontSize: 12),
               ),
            ],
          ),
        ],
      ),
    ),
  );
}

}
