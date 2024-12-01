import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

import '../config.dart'; // Import configuration
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart'; // For NFC functionality

class ManageUsersScreen extends StatefulWidget {
  @override
  _ManageUsersScreenState createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  // Fetch the list of users
  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(AppConfig.apiUsersEndpoint));
      if (response.statusCode == 200) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        throw Exception("Failed to fetch users");
      }
    } catch (e) {
      print("Error fetching users: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching users: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Get the next available nfc_id from the backend
  Future<int?> _getNextAvailableNfcId() async {
    try {
      final response =
      await http.get(Uri.parse('${AppConfig.apiUsersEndpoint}/next-nfc-id'));
      if (response.statusCode == 200) {
        return int.parse(response.body);
      } else {
        throw Exception("Failed to fetch next available NFC ID");
      }
    } catch (e) {
      print("Error fetching next available NFC ID: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching next available NFC ID: $e")),
      );
      return null;
    }
  }

  // Write the nfc_id to the NFC card
  Future<bool> _writeNfcIdToCard(int nfcId) async {
    try {
      final nfcData = json.encode({"nfc_id": nfcId});
      await FlutterNfcKit.poll();
      await FlutterNfcKit.transceive(nfcData);
      await FlutterNfcKit.finish();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("NFC card written successfully")),
      );
      return true;
    } catch (e) {
      print("Error writing to NFC card: $e");

      if (kDebugMode) {
        print("Debug mode: Skipping NFC write");
        return true; // Simulate success in debug mode
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error writing to NFC card: $e")),
      );
      return false;
    }
  }

  // Create the user in the database
  Future<void> _createUser(String name, double balance, int nfcId) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.apiUsersEndpoint),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "name": name,
          "balance": balance,
          "nfcId": nfcId.toString(),
        }),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User created successfully")),
        );
        _fetchUsers(); // Refresh user list
      } else {
        throw Exception("Failed to create user");
      }
    } catch (e) {
      print("Error creating user: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error creating user: $e")),
      );
    }
  }

  // Show the dialog to create a new user
  void _showCreateUserDialog(int nfcId) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController balanceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Enter User Details"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("NFC ID: $nfcId"),
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: balanceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Balance"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final balance = double.tryParse(balanceController.text);

                if (name.isNotEmpty && balance != null) {
                  await _createUser(name, balance, nfcId);
                  Navigator.pop(context); // Close dialog
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Invalid input")),
                  );
                }
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // Handle the process of creating a new user
  Future<void> _handleCreateUser() async {
    // Step 1: Get next available NFC ID
    final nfcId = await _getNextAvailableNfcId();
    if (nfcId == null) return;

    // Step 2: Write NFC ID to the card
    bool nfcWriteSuccess = await _writeNfcIdToCard(nfcId);
    if (!nfcWriteSuccess) return; // Abort if NFC write failed

    // Step 3: Prompt admin to enter user details
    _showCreateUserDialog(nfcId);
  }

  // Delete user method
  Future<void> _deleteUser(int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.apiUsersEndpoint}/$userId'),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User deleted successfully")),
        );
        _fetchUsers(); // Refresh user list
      } else {
        throw Exception("Failed to delete user");
      }
    } catch (e) {
      print("Error deleting user: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting user: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Users"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _handleCreateUser,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            elevation: 4.0,
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 16.0,
              ),
              title: Text(
                user['name'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Text(
                "Balance: £${user['balance'].toStringAsFixed(2)}\nNFC ID: ${user['nfcId']}",
                style: TextStyle(color: Colors.green),
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteUser(user['id']),
              ),
            ),
          );
        },
      ),
    );
  }
}
