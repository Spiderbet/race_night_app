import 'package:flutter/material.dart';
import '../widgets/race_night_header.dart';

class PlaceBetScreen extends StatefulWidget {
  final String nfcId;
  const PlaceBetScreen({Key? key, required this.nfcId}) : super(key: key);

  @override
  _PlaceBetScreenState createState() => _PlaceBetScreenState();
}

class _PlaceBetScreenState extends State<PlaceBetScreen> {
  int _currentRaceNumber = 1; // Example race number
  double _currentBalance = 50.00; // Example user balance
  List<String> _runnerNames = [
    "Mr. Piglet",
    "Swifty Sow",
    "Hog Wild",
    "Porcine Lightning",
    "Mudslide Maverick",
    "Squeal of Fortune",
    "Hammin' It Up",
    "Oinker Express",
  ];

  final List<Color> _towelColors = [
    Colors.red,
    Colors.white,
    Colors.blue,
    Colors.yellow,
    Colors.green,
    Colors.black,
    Colors.orange,
    Colors.pink,
  ];

  final List<Color> _numberColors = [
    Colors.white,
    Colors.black,
    Colors.white,
    Colors.black,
    Colors.white,
    Colors.yellow,
    Colors.black,
    Colors.black,
  ];

  void _selectRunner(String runner) {
    Navigator.pushNamed(
      context,
      '/confirmBet',
      arguments: {
        'runner': runner,
        'nfcId': widget.nfcId,
        'raceNumber': _currentRaceNumber,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const RaceNightHeader(), // Logo header
              const SizedBox(height: 8), // Spacer
              _buildRaceNumberHeader(), // Race number header
              _buildUserInfoRow(), // User ID and balance
              const SizedBox(height: 8), // Spacer
              Expanded(
                child: _buildRunnerGrid(), // Dynamic grid for runners
              ),
            ],
          ),
          // Logout Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/', (route) => false);
              },
              backgroundColor: Colors.red,
              child: const Icon(Icons.logout, color: Colors.white),
              mini: true,
              tooltip: "Logout",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRaceNumberHeader() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(
          "Race: $_currentRaceNumber",
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "User: ${widget.nfcId}",
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            "Balance: £${_currentBalance.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 16, color: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildRunnerGrid() {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate available height and subtract margins, paddings, and headers
    final availableHeight = screenHeight -
        (MediaQuery.of(context).padding.top + 250); // Account for headers and spacers
    final rowCount = isLandscape ? 4 : 8; // 4 rows in landscape, 8 in portrait
    final buttonHeight =
        (availableHeight - (8.0 * (rowCount - 1))) / rowCount; // Adjust for row spacing
    final buttonWidth = isLandscape
        ? (screenWidth - 48) / 2 // 2 columns in landscape, account for margins
        : screenWidth - 32; // Full width in portrait

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(), // Disable scrolling
      padding: EdgeInsets.zero, // Remove default padding
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isLandscape ? 2 : 1, // 2 columns in landscape
        mainAxisSpacing: 8.0, // Spacing between rows
        crossAxisSpacing: 8.0, // Spacing between columns
        mainAxisExtent: buttonHeight, // Fix button height
      ),
      itemCount: _runnerNames.length,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            onTap: () => _selectRunner(_runnerNames[index]),
            child: Container(
              width: buttonWidth,
              height: buttonHeight,
              color: _towelColors[index],
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _runnerNames[index],
                  style: TextStyle(
                    fontSize: buttonHeight * 0.3, // Adjust font size
                    color: _numberColors[index],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
