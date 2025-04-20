import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:security_iot/services/network_service.dart';
import 'package:share_plus/share_plus.dart';


class LogsScreen extends StatefulWidget {
  const LogsScreen({Key? key}) : super(key: key);

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  late Future<List<Map<String, dynamic>>> _logsFuture;
  List<Map<String, dynamic>> _allLogs = [];
  List<Map<String, dynamic>> _filteredLogs = [];
  String _selectedSeverity = 'all';

  @override
  void initState() {
    super.initState();
    _logsFuture = _fetchLogs();
  }

  Future<List<Map<String, dynamic>>> _fetchLogs() async {
    final service = await NetworkService.create();
    final logs = await service.getLogs();
    _allLogs = logs;
    _filteredLogs = logs;
    return logs;
  }

  void _filterLogs(String severity) {
    setState(() {
      _selectedSeverity = severity;
      if (severity == 'all') {
        _filteredLogs = _allLogs;
      } else {
        _filteredLogs =
            _allLogs.where((log) => log['severity'] == severity).toList();
      }
    });
  }

  void _exportLogs() {
    final exportData = jsonEncode(_filteredLogs);
    Share.share(exportData, subject: 'Exported Logs');
  }

  void _showLogDetails(Map<String, dynamic> log) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(log['event_type'] ?? 'Log Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Timestamp', log['timestamp']),
              _buildDetailRow('Severity', log['severity']),
              _buildDetailRow('Source', log['source']),
              const Divider(),
              _buildDetailRow('Message', log['details']['message']),
              const SizedBox(height: 8),
              Text('Sensor Data:', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(jsonEncode(log['details']['sensor_data'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          )
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$title: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value?.toString() ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'critical':
        return Colors.red.shade700;
      case 'error':
        return Colors.redAccent;
      case 'warning':
        return Colors.orange;
      case 'user':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  appBar: AppBar(
  automaticallyImplyLeading: false,  // Removes the back button
  title: Text(
    'System Logs',
    style: TextStyle(
      fontSize: 24.0, // Adjust font size to make it look nicer
      fontWeight: FontWeight.bold, // Makes the text bold
      color: const Color.fromARGB(255, 11, 85, 146), // Sets the text color (you can adjust this to your liking)
    ),
  ),
  actions: [
    IconButton(
      icon: const Icon(Icons.share),
      onPressed: _exportLogs,
      tooltip: 'Export Logs',
    ),
  ],
),

      body: Column(
        children: [
Padding(
  padding: const EdgeInsets.all(8.0),
  child: Container(
    decoration: BoxDecoration(
      color: Colors.blue.shade50, // Light background color
      borderRadius: BorderRadius.circular(12.0), // Rounded corners
      boxShadow: [
        BoxShadow(
          color: Colors.black26,
          offset: Offset(0, 2),
          blurRadius: 4.0,
        ),
      ],
    ),
    child: DropdownButton<String>(
      value: _selectedSeverity,
      items: const [
        DropdownMenuItem(value: 'all', child: Text('All')),
        DropdownMenuItem(value: 'info', child: Text('Info')),
        DropdownMenuItem(value: 'warning', child: Text('Warning')),
        DropdownMenuItem(value: 'error', child: Text('Error')),
        DropdownMenuItem(value: 'user', child: Text('User Audit')),
        DropdownMenuItem(value: 'critical', child: Text('Critical')),
      ],
      onChanged: (value) {
        if (value != null) _filterLogs(value);
      },
      isExpanded: true,
      style: TextStyle(
        fontSize: 16.0, // Text size
        fontWeight: FontWeight.bold, // Bold text
        color: Colors.black, // Text color
      ),
      underline: Container(
        height: 2,
        color: const Color.fromARGB(255, 3, 21, 51), // Custom underline color
      ),
    ),
  ),
),

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _logsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (_filteredLogs.isEmpty) {
                  return const Center(child: Text('No logs available.'));
                }

                return ListView.builder(
                  itemCount: _filteredLogs.length,
                  itemBuilder: (context, index) {
                    final log = _filteredLogs[index];
                    final severity = log['severity'] ?? 'info';
                    final color = _severityColor(severity);
                    final message = log['details']['message'] ?? 'No message';
                    final timestamp = log['timestamp'] ?? '';

                    return Card(
                      color: color.withOpacity(0.1),
                      child: ListTile(
                        leading: Icon(Icons.security, color: color),
                        title: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(timestamp),
                        trailing: Text(severity.toUpperCase(), style: TextStyle(color: color)),
                        onTap: () => _showLogDetails(log),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
