import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config.dart'; // Import configuration

class ManageRacesScreen extends StatefulWidget {
  @override
  _ManageRacesScreenState createState() => _ManageRacesScreenState();
}

class _ManageRacesScreenState extends State<ManageRacesScreen> {
  List<Map<String, dynamic>> _races = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchRaces();
  }

  Future<void> _fetchRaces() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(AppConfig.apiRacesEndpoint));
      if (response.statusCode == 200) {
        setState(() {
          _races = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        throw Exception("Failed to fetch races");
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching races: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createRace(String raceName, List<String> runners) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.apiRacesEndpoint),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "name": raceName,
          "runners": runners,
        }),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Race created successfully")),
        );
        _fetchRaces(); // Refresh race list
      } else {
        throw Exception("Failed to create race");
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error creating race: $e")),
      );
    }
  }

  Future<void> _setActiveRace(int raceId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiRacesEndpoint}/$raceId/activate'),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Race set as active")),
        );
        _fetchRaces(); // Refresh race list
      } else {
        throw Exception("Failed to set active race");
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error setting active race: $e")),
      );
    }
  }

  Future<void> _updateRace(int raceId, String raceName, List<String> runners) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConfig.apiRacesEndpoint}/$raceId'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"name": raceName}),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to update race");
      }

      // Updating runners
      for (int i = 0; i < runners.length; i++) {
        final runnerResponse = await http.put(
          Uri.parse('${AppConfig.apiRacesEndpoint}/$raceId/runners/${i + 1}'),
          headers: {"Content-Type": "application/json"},
          body: json.encode({"name": runners[i]}),
        );

        if (runnerResponse.statusCode != 200) {
          throw Exception("Failed to update runner ${i + 1}");
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Race updated successfully")),
      );
      _fetchRaces();
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating race: $e")),
      );
    }
  }

  void _showCreateRaceDialog() {
    final TextEditingController raceNameController = TextEditingController();
    final List<TextEditingController> runnerControllers =
    List.generate(8, (_) => TextEditingController());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Create New Race"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: raceNameController,
                  decoration: InputDecoration(labelText: "Race Name"),
                ),
                const SizedBox(height: 16),
                Column(
                  children: List.generate(8, (index) {
                    return TextField(
                      controller: runnerControllers[index],
                      decoration:
                      InputDecoration(labelText: "Runner ${index + 1}"),
                    );
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final raceName = raceNameController.text.trim();
                final runners = runnerControllers
                    .map((controller) => controller.text.trim())
                    .where((runner) => runner.isNotEmpty)
                    .toList();

                if (raceName.isNotEmpty && runners.length == 8) {
                  await _createRace(raceName, runners);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          "Please fill all fields, including 8 runners"),
                    ),
                  );
                }
              },
              child: Text("Create"),
            ),
          ],
        );
      },
    );
  }

  void _showEditRaceDialog(Map<String, dynamic> race) {
    final TextEditingController raceNameController =
    TextEditingController(text: race['name']);
    final List<TextEditingController> runnerControllers = List.generate(
      8,
          (index) => TextEditingController(
        text: race['runners'][index]['name'],
      ),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Race"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: raceNameController,
                  decoration: InputDecoration(labelText: "Race Name"),
                ),
                const SizedBox(height: 16),
                Column(
                  children: List.generate(8, (index) {
                    return TextField(
                      controller: runnerControllers[index],
                      decoration:
                      InputDecoration(labelText: "Runner ${index + 1}"),
                    );
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final raceName = raceNameController.text.trim();
                final runners = runnerControllers
                    .map((controller) => controller.text.trim())
                    .where((runner) => runner.isNotEmpty)
                    .toList();

                if (raceName.isNotEmpty && runners.length == 8) {
                  await _updateRace(race['id'], raceName, runners);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                      Text("Please fill all fields, including 8 runners"),
                    ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Races"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showCreateRaceDialog,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _races.length,
        itemBuilder: (context, index) {
          final race = _races[index];
          final isActive = race['activeRace'] ?? false;
          final runners = race['runners'] ?? [];

          return Card(
            margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            elevation: 4.0,
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 16.0,
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    race['name'] ?? "Race ${race['id']}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: EdgeInsets.symmetric(
                          vertical: 4.0, horizontal: 8.0),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        "Active",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Text(
                "Runners: ${runners.map((runner) => runner['name']).join(', ')}",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == "Edit") {
                    _showEditRaceDialog(race);
                  } else if (value == "Set Active") {
                    await _setActiveRace(race['id']);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: "Edit",
                    child: Text("Edit"),
                  ),
                  if (!isActive)
                    PopupMenuItem(
                      value: "Set Active",
                      child: Text("Set Active"),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
