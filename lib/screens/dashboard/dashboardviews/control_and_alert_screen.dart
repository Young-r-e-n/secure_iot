import 'package:flutter/material.dart';
import '../../../services/network_service.dart';
import 'dart:async';

class ControlAndAlertScreen extends StatefulWidget {
  final NetworkService networkService;

  const ControlAndAlertScreen({super.key, required this.networkService});

  @override
  State<ControlAndAlertScreen> createState() => _ControlAndAlertScreenState();
}

class _ControlAndAlertScreenState extends State<ControlAndAlertScreen> {
  final TextEditingController _alertController = TextEditingController();
  bool _loading = false;
  String? _result;
  Map<String, dynamic>? _statusData;

  String _doorSelection = 'lock';
  String _windowSelection = 'lock';

  @override
  void initState() {
    super.initState();
    _fetchStatus();
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

  Future<void> _sendControl(String action, [Map<String, dynamic>? params]) async {
    setState(() => _loading = true);
    try {
      final res = await widget.networkService.sendControlCommand(action, params);
      setState(() => _result = res['message'] ?? 'Success');
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
      _alertController.clear();
    } catch (e) {
      setState(() => _result = 'Alert error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildStatusTile(String name, dynamic sensor) {
    final bool isActive = sensor['is_active'] ?? false;
    final IconData icon;
    switch (sensor['type']) {
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.green[600] : Colors.grey[400],
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Active: $isActive"),
        trailing: sensor['data'] != null ? Text(sensor['data'].toString()) : null,
      ),
    );
  }

  Widget _buildDeviceControlTile({
    required String label,
    required String target,
    required String selection,
    required ValueChanged<String> onSelectionChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'lock', label: Text("Lock")),
            ButtonSegment(value: 'unlock', label: Text("Unlock")),
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

  Widget _buildControlButton(IconData icon, String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sensors = _statusData?['sensors'] ?? {};

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Controls & System Status',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue[900],
        elevation: 0.5,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchStatus,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // SYSTEM STATUS
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          "System Status: ${_statusData?['status'] ?? 'N/A'}",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // SENSOR STATUS
                    if (sensors.isNotEmpty)
                      ...sensors.entries.map((e) => _buildStatusTile(e.key, e.value)),
                    const SizedBox(height: 24),

                    // ACCESS CONTROL
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Access Control", style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 12),
                            _buildDeviceControlTile(
                              label: "Door",
                              target: "door",
                              selection: _doorSelection,
                              onSelectionChanged: (val) => setState(() => _doorSelection = val),
                            ),
                            const SizedBox(height: 12),
                            _buildDeviceControlTile(
                              label: "Window",
                              target: "window",
                              selection: _windowSelection,
                              onSelectionChanged: (val) => setState(() => _windowSelection = val),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SURVEILLANCE
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Surveillance", style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 12),
                            _buildControlButton(Icons.camera_alt, 'Capture Image', () => _sendControl('capture_image')),
                            const SizedBox(height: 10),
                            _buildControlButton(Icons.videocam, 'Record 10s Video',
                                () => _sendControl('record_video', {'duration': 10})),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ALERTS
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Send Alert", style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _alertController,
                              decoration: InputDecoration(
                                labelText: 'Alert Message',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildControlButton(Icons.warning, 'Send Alert', _sendAlert),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // RESULT MESSAGE
                    if (_result != null)
                      Text(
                        _result!,
                        style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
