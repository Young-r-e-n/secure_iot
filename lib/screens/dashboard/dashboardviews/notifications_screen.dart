import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final TextEditingController _controller = TextEditingController();
  final String fetchUrl = 'https://clarence.fhmconsultants.com/api/get_notifications.php';
  final String sendUrl = 'https://clarence.fhmconsultants.com/api/send_notification.php';
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await http.get(Uri.parse(fetchUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          notifications = List<Map<String, dynamic>>.from(data);
        });
      } else {
        setState(() {
          error = 'Failed to fetch notifications.';
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error fetching data: $e';
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> sendNotification() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse(sendUrl),
        body: {'message': message},
      );

      if (response.statusCode == 200) {
        _controller.clear();
        await fetchNotifications();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification sent')),
        );
      } else {
        throw Exception('Failed to send notification');
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
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Notification input box
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter notification message',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendNotification,
                ),
                border: const OutlineInputBorder(),
              ),
              minLines: 1,
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            // Notifications list or error/loading
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                      ? Center(child: Text(error!))
                      : ListView.builder(
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final item = notifications[index];
                            return Card(
                                color:Colors.white,
                              child: ListTile(
                                title: Text(item['message'] ?? 'No message'),
                                subtitle: Text(item['sender'] ?? 'Unknown sender'),
                                trailing: Text(
                                  item['created_at'] ?? '',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
