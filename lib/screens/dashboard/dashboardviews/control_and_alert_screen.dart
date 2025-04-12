import 'package:flutter/material.dart';
import 'dart:async';
import '../../../services/network_service.dart';

class ControlAndAlertScreen extends StatefulWidget {
  final NetworkService networkService;

  const ControlAndAlertScreen({super.key, required this.networkService});

  @override
  State<ControlAndAlertScreen> createState() => _ControlAndAlertScreenState();
}

class _ControlAndAlertScreenState extends State<ControlAndAlertScreen>
    with TickerProviderStateMixin {
  final TextEditingController _alertController = TextEditingController();
  bool _loading = false;
  String? _result;
  Map<String, dynamic>? _statusData;
  String _doorSelection = 'lock';
  String _windowSelection = 'lock';

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _fetchStatus();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(0xFF1E40AF),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchStatus() async {
    setState(() => _loading = true);
    try {
      final response = await widget.networkService.getStatus();
      setState(() => _statusData = response);
    } catch (e) {
      setState(() => _result = 'Error fetching status: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _sendControl(
    String action, [
    Map<String, dynamic>? params,
  ]) async {
    setState(() => _loading = true);
    try {
      final res = await widget.networkService.sendControlCommand(
        action,
        params,
      );
      setState(() => _result = res['message'] ?? 'Success');
      _showSnackBar(_result!);
      await _fetchStatus();
    } catch (e) {
      setState(() => _result = 'Control error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _sendAlert() async {
    setState(() => _loading = true);
    try {
      final res = await widget.networkService.sendAlert(_alertController.text);
      setState(() => _result = res['message'] ?? 'Alert sent');
      _showSnackBar(_result!);
      _alertController.clear();
    } catch (e) {
      setState(() => _result = 'Alert error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _testAllSensors() async {
    setState(() => _loading = true);
    try {
      final response = await widget.networkService.testAllSensors();
      _showSnackBar(response['message'] ?? 'Test completed');
      await _fetchStatus();
    } catch (e) {
      _showSnackBar('Sensor test failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildStatusTile(String name, dynamic sensor) {
    final bool isActive = sensor['is_active'] ?? false;
    final String sensorType = sensor['type'];
    final IconData icon;
    final Color statusColor = isActive ? Colors.green : Colors.blueGrey;

    switch (sensorType) {
      case 'camera':
        icon = Icons.camera_alt;
        break;
      case 'door':
        icon = Icons.door_front_door;
        break;
      case 'window':
        icon = Icons.sensor_window;
        break;
      case 'motion':
        icon = Icons.motion_photos_on;
        break;
      case 'rfid':
        icon = Icons.rss_feed;
        break;
      case 'actuator':
        icon = Icons.settings_remote;
        break;
      default:
        icon = Icons.device_unknown;
    }

    return Card(
      elevation: 3,
         color:Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 40 + (_pulseController.value * 6),
                  height: 40 + (_pulseController.value * 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isActive
                            ? Colors.green.withOpacity(0.3)
                            : Colors.transparent,
                  ),
                );
              },
            ),
            CircleAvatar(
              backgroundColor: statusColor,
              child: Icon(icon, color: Colors.white),
            ),
          ],
        ),
        title: Text(
          name.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(isActive ? "Active" : "Inactive"),
        trailing:
            sensor['data'] != null ? Text(sensor['data'].toString()) : null,
      ),
    );
  }

  Widget _buildDeviceControlTile({
    required String label,
    required String target,
    required String selection,
    required ValueChanged<String> onSelectionChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'lock', label: Text("🔒 Lock")),
            ButtonSegment(value: 'unlock', label: Text("🔓 Unlock")),
          ],
          selected: <String>{selection},
          onSelectionChanged: (Set<String> value) {
            final newValue = value.first;
            onSelectionChanged(newValue);
            _sendControl(newValue, {'target': target});
          },
        ),
      ],
    );
  }

  Widget _buildControlButton(
    IconData icon,
    String label,
    VoidCallback onPressed,
    Color color,
  ) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sensors = _statusData?['sensors'] ?? {};

    return Scaffold(
      appBar: AppBar(
       title: const Text(
  'Controls & System Status',
  style: TextStyle(
    fontWeight: FontWeight.bold,
    color: Color(0xFF1E40AF),
  
  ),
),
  backgroundColor:  Colors.white,
        automaticallyImplyLeading: false,
        elevation: 3,
        centerTitle: true,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _fetchStatus,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 3,
                           color:Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            "🔍 System Status: ${_statusData?['status'] ?? 'N/A'}",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (sensors.isNotEmpty)
                        ...sensors.entries.map(
                          (e) => _buildStatusTile(e.key, e.value),
                        ),

                      const SizedBox(height: 30),

                      Card(
                        elevation: 3,
                           color:Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "🔐 Access Control",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildDeviceControlTile(
                                label: "Main Door",
                                target: "door",
                                selection: _doorSelection,
                                onSelectionChanged:
                                    (val) =>
                                        setState(() => _doorSelection = val),
                              ),
                              const SizedBox(height: 16),
                              _buildDeviceControlTile(
                                label: "Window",
                                target: "window",
                                selection: _windowSelection,
                                onSelectionChanged:
                                    (val) =>
                                        setState(() => _windowSelection = val),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      Card(
                        elevation: 3,
                        color:Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "🎥 Surveillance",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildControlButton(
                                Icons.camera_alt,
                                'Capture Image',
                                () => _sendControl('capture_image'),
                                Colors.deepPurple,
                              ),
                              const SizedBox(height: 12),
                              _buildControlButton(
                                Icons.videocam,
                                'Record 10s Video',
                                () => _sendControl('record_video', {
                                  'duration': 10,
                                }),
                                Colors.indigo,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      Card(
                        elevation: 3,
                           color:Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "🧪 Sensor Testing",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildControlButton(
                                Icons.sensors,
                                'Test All Sensors',
                                _testAllSensors,
                                Colors.teal,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                      Card(
                        elevation: 3,
                           color:Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "🚨 Send Alert",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _alertController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter alert message...',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildControlButton(
                                Icons.warning_amber_rounded,
                                'Send Alert',
                                _sendAlert,
                                Colors.redAccent,
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (_result != null) ...[
                        const SizedBox(height: 24),
                        Center(
                          child: Text(
                            _result!,
                            style: TextStyle(
                              color: Colors.teal[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
    );
  }
}
