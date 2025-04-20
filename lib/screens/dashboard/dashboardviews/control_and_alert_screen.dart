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


Future<void> _updateFirmware() async {
  setState(() => _loading = true);
  try {
    final response = await widget.networkService.updateFirmware();
    _showSnackBar(response['message'] ?? 'Firmware updated successfully');
    await _fetchStatus();
  } catch (e) {
    _showSnackBar('Firmware update failed: $e');
  } finally {
    setState(() => _loading = false);
  }
}


  void _showConfirmationDialog({
  required String title,
  required String content,
  required VoidCallback onConfirm,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text("Confirm"),
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
          ),
        ],
      );
    },
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

    final resultFromPi = response['result_from_pi'];
    if (resultFromPi != null && resultFromPi['results'] != null) {
      _showSensorResultsDialog(resultFromPi['results'], resultFromPi['summary']);
    } else {
      _showSnackBar(response['message'] ?? 'Test completed');
    }

    await _fetchStatus();
  } catch (e) {
    _showSnackBar('Sensor test failed: $e');
  } finally {
    setState(() => _loading = false);
  }
}

void _showSensorResultsDialog(Map<String, dynamic> results, String summary) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                '🧪 Sensor Test Results',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final key = results.keys.elementAt(index);
                    final result = results[key];
                    final status = result['status'] ?? 'unknown';
                    final details = result['details'] ?? '';

                    Color statusColor;
                    IconData icon;
                    switch (status) {
                      case 'ok':
                        statusColor = Colors.green;
                        icon = Icons.check_circle;
                        break;
                      case 'error':
                        statusColor = Colors.red;
                        icon = Icons.error;
                        break;
                      case 'info':
                        statusColor = Colors.orange;
                        icon = Icons.info;
                        break;
                      default:
                        statusColor = Colors.grey;
                        icon = Icons.help_outline;
                    }

                    return Card(
                      child: ListTile(
                        leading: Icon(icon, color: statusColor),
                        title: Text(key.toUpperCase()),
                        subtitle: Text(details),
                        trailing: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                summary,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    },
  );
}


Future<void> _restartSystem() async {
  setState(() => _loading = true);
  try {
    final response = await widget.networkService.restartSystem();
    _showSnackBar(response['message'] ?? 'System restarted successfully');
    await _fetchStatus();
  } catch (e) {
    _showSnackBar('System restart failed: $e');
  } finally {
    setState(() => _loading = false);
  }
}

Future<void> _clearLogs() async {
  setState(() => _loading = true);
  try {
    final response = await widget.networkService.clearLogs();
    _showSnackBar(response['message'] ?? 'Logs cleared successfully');
    await _fetchStatus();
  } catch (e) {
    _showSnackBar('Clearing logs failed: $e');
  } finally {
    setState(() => _loading = false);
  }
}

Widget _buildStatusTile(String name, dynamic sensor) {
  final bool isActive = sensor['is_active'] ?? false;
  final String sensorType = sensor['type'];
  final Color statusColor = isActive ? Colors.green : Colors.blueGrey;
  final String data = sensor['data']?.toString() ?? "No data";

  IconData icon = Icons.device_unknown;
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
  }

  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top: icon + active status
          Row(
            children: [
              CircleAvatar(
                backgroundColor: statusColor,
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name.toUpperCase(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1),
                    Text(
                      isActive ? "Active" : "Inactive",
                      style: TextStyle(
                          fontSize: 12,
                          color: isActive ? Colors.green : Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Bottom: data
          Text(
            data,
            style: const TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}


Widget _buildDeviceControlTile({
  required String label,
  required String target,
  required String selection,
  required ValueChanged<String> onSelectionChanged,
}) {
  return Card(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // 👇 Force the segmented button to take full width
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'lock', label: Text("🔒 Lock")),
                ButtonSegment(value: 'unlock', label: Text("🔓 Unlock")),
              ],
              selected: <String>{selection},
              onSelectionChanged: (Set<String> value) {
                final newValue = value.first;
                onSelectionChanged(newValue);
                final command = '${newValue}_$target';
                _sendControl(command, {'target': target});
              },
              style: ButtonStyle(
                backgroundColor:
                    WidgetStateProperty.all(Colors.blueGrey.shade50),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 8),
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}



 Widget _buildControlButton(
  IconData icon,
  String label,
  VoidCallback onPressed,
  Color color,
) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
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

                      // if (sensors.isNotEmpty)
                      //   ...sensors.entries.map(
                      //     (e) => _buildStatusTile(e.key, e.value),
                      //   ),

  //                     if (sensors.isNotEmpty)
  // GridView.builder(
  //   shrinkWrap: true,
  //   physics: const NeverScrollableScrollPhysics(),
  //   itemCount: sensors.length,
  //   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
  //     crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
  //     crossAxisSpacing: 12,
  //     mainAxisSpacing: 12,
  //     childAspectRatio: 1.6,
  //   ),
  //   itemBuilder: (context, index) {
  //     final entry = sensors.entries.elementAt(index);
  //     return _buildStatusTile(entry.key, entry.value);
  //   },
  // ),


if (sensors.isNotEmpty)
  Column(
    children: [
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sensors.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
        ),
        itemBuilder: (context, index) {
          final entry = sensors.entries.elementAt(index);
          return _buildStatusTile(entry.key, entry.value);
        },
      ),
    ],
  )
,


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



const SizedBox(height: 20),

// Restart and Clear Logs Card
Card(
  elevation: 3,
  color: Colors.white,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
child: Padding(
  padding: const EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "🛠️ System Maintenance",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 16),
      _buildControlButton(
        Icons.restart_alt,
        'Restart System',
        () => _showConfirmationDialog(
          title: "Restart System?",
          content: "Are you sure you want to restart the system?",
          onConfirm: _restartSystem,
        ),
        Colors.orange,
      ),
      const SizedBox(height: 10),
      _buildControlButton(
        Icons.delete_forever,
        'Clear Logs',
        () => _showConfirmationDialog(
          title: "Clear Logs?",
          content: "This will permanently delete all logs. Proceed?",
          onConfirm: _clearLogs,
        ),
        Colors.red,
      ),
      const SizedBox(height: 10),
      _buildControlButton(
        Icons.system_update,
        'Update Firmware',
        () => _showConfirmationDialog(
          title: "Update Firmware?",
          content: "Make sure the device is connected and stable during the update. Proceed?",
          onConfirm: _updateFirmware,
        ),
        Colors.blue,
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
