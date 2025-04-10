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
      await _fetchStatus(); // Refresh status after action
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
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: isActive ? Colors.green : Colors.grey),
        title: Text(name.toUpperCase()),
        subtitle: Text("Active: $isActive"),
        trailing: sensor['data'] != null
            ? Text(sensor['data'].toString())
            : const SizedBox.shrink(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sensors = _statusData?['sensors'] ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text('Controls & System Status')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchStatus,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("System Status: ${_statusData?['status'] ?? 'N/A'}",
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    if (sensors.isNotEmpty)
                      ...sensors.entries.map((e) => _buildStatusTile(e.key, e.value)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.lock),
                      label: const Text('Lock Door'),
                      onPressed: () => _sendControl('lock'),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.lock_open),
                      label: const Text('Unlock Window'),
                      onPressed: () => _sendControl('unlock', {'target': 'window'}),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Capture Image'),
                      onPressed: () => _sendControl('capture_image'),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.videocam),
                      label: const Text('Record 10s Video'),
                      onPressed: () => _sendControl('record_video', {'duration': 10}),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _alertController,
                      decoration: const InputDecoration(
                        labelText: 'Alert Message',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.warning),
                      label: const Text('Send Alert'),
                      onPressed: _sendAlert,
                    ),
                    const SizedBox(height: 24),
                    if (_result != null)
                      Text(
                        _result!,
                        style: const TextStyle(color: Colors.blueAccent),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
