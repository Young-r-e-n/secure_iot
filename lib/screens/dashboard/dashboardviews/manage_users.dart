import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ManageUsersScreen extends StatefulWidget {
  @override
  _ManageUsersScreenState createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  late Future<List<dynamic>> _usersFuture;
  final String baseUrl = "https://clarence.fhmconsultants.com/api"; // Set your base URL



  @override
  void initState() {
    super.initState();
    _usersFuture = fetchUsers();
  }

  Future<List<dynamic>> fetchUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/users.php?action=read'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<void> createUser(String name, String email, String password, String role) async {
    await http.post(Uri.parse('$baseUrl/users.php?action=create'),
        body: {'name': name, 'email': email, 'password': password, 'role': role});
    setState(() {
      _usersFuture = fetchUsers(); // Refresh the list after creation
    });
  }

  Future<void> updateUser(dynamic id, String name, String email, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users.php?action=update'),
      body: {'id': id.toString(), 'name': name, 'email': email, 'role': role},
    );

    if (response.statusCode == 200) {
      setState(() {
        _usersFuture = fetchUsers(); // Refresh after update
      });
    } else {
      throw Exception('Failed to update user');
    }
  }


Future<void> deleteUser(int id, BuildContext context) async {
  // Show a loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Center(child: CircularProgressIndicator()),
  );

  final response = await http.post(
    Uri.parse('$baseUrl/users.php?action=delete'),
    body: {'id': id.toString()},
  );

  Navigator.of(context).pop(); // Close the loading dialog

  if (response.statusCode == 200) {
    final result = jsonDecode(response.body);
    final message = result['message'] ?? 'No message received';

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $message'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _usersFuture = fetchUsers(); // Refresh the list
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ $message'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Error ${response.statusCode}: Failed to delete user'),
        backgroundColor: Colors.red,
      ),
    );
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
    
      body: FutureBuilder(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final users = snapshot.data as List<dynamic>;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(users[index]['name']),
                subtitle: Text(users[index]['email']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Color(0xFF1E40AF)),
                      onPressed: () => _editUser(context, users[index]),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
onPressed: () => deleteUser(
  int.parse(users[index]['id'].toString()), // force to int
  context,
),



                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUserDialog(context),
        backgroundColor: Color(0xFF1E40AF),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

void _showAddUserDialog(BuildContext context) {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  String selectedRole = 'Admin'; // Default selected role

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          "Add User",
          style: TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStyledTextField(nameController, "Name"),
              SizedBox(height: 10),
              _buildStyledTextField(emailController, "Email"),
              SizedBox(height: 10),
              _buildStyledTextField(passwordController, "Password", obscureText: true),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: InputDecoration(
                  labelText: "Role",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                items: ['Admin', 'Security', 'Staff'].map((role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedRole = value;
                  }
                },
              ),
            ],
          ),
        ),
        actions: _buildDialogActions(() {
          createUser(
            nameController.text,
            emailController.text,
            passwordController.text,
            selectedRole,
          );
          Navigator.pop(context);
        }),
      );
    },
  );
}


void _editUser(BuildContext context, Map user) {
  TextEditingController nameController = TextEditingController(text: user['name']);
  TextEditingController emailController = TextEditingController(text: user['email']);
 String selectedRole = ['Admin', 'Security', 'Staff'].contains(user['role'])
    ? user['role']
    : 'Staff'; // Default to 'Staff' or whatever makes sense


  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Center(
          child: Text(
            "Edit User",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStyledTextField(nameController, "Name"),
              SizedBox(height: 10),
              _buildStyledTextField(emailController, "Email"),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: InputDecoration(
                  labelText: "Role",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: ['Admin', 'Security', 'Staff'].map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedRole = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Color(0xFF1E40AF), fontSize: 16)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1E40AF), foregroundColor: Colors.white),
            onPressed: () {
              updateUser(user['id'], nameController.text, emailController.text, selectedRole);
              Navigator.pop(context);
            },
            child: Text("Update", style: TextStyle(fontSize: 16)),
          ),
        ],
      );
    },
  );
}

  Widget _buildStyledTextField(TextEditingController controller, String label, {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.blue.withOpacity(0.1),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Color(0xFF1E40AF))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Color(0xFF1E40AF), width: 2)),
      ),
    );
  }

  List<Widget> _buildDialogActions(VoidCallback onSave) {
    return [
      TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
      TextButton(onPressed: onSave, child: Text("Save")),
    ];
  }
}
