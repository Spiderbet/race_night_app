import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BettingApp(),
    );
  }
}

class BettingApp extends StatefulWidget {
  @override
  _BettingAppState createState() => _BettingAppState();
}

class _BettingAppState extends State<BettingApp> {
  List<int> _counts = List.generate(8, (index) => 0);
  List<String> _horseNames = List.generate(8, (index) => 'Horse ${index + 1}');
  double _charityTakeout = 20.0;
  final TextEditingController _controller = TextEditingController(text: "20");
  List<TextEditingController> _nameControllers = [];
  int _selectedRaceNumber = 1;
  final List<int> _raceNumbers = List.generate(10, (index) => index + 1);

  // Define horse button color specifications
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

  @override
  void initState() {
    super.initState();
    _nameControllers = List.generate(8, (index) => TextEditingController(text: _horseNames[index]));
  }

  @override
  void dispose() {
    for (var controller in _nameControllers) {
      controller.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  int get _total => _counts.reduce((value, element) => value + element);
  double get _totalAfterCharity => _total * (1 - _charityTakeout / 100);
  double get _totalForCharity => _total * (_charityTakeout / 100);

  void _incrementCounter(int horseNumber) {
    setState(() {
      _counts[horseNumber - 1]++;
    });
  }

  double _calculateDividend(int horseNumber) {
    if (_counts[horseNumber - 1] == 0) return 0;
    return _totalAfterCharity / _counts[horseNumber - 1];
  }

  void _updateCharityTakeout(String value) {
    final newTakeout = double.tryParse(value);
    if (newTakeout != null) {
      setState(() {
        _charityTakeout = newTakeout;
        _controller.text = value;
      });
    }
  }

  void _openRaceSettings() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Race Settings'),
          content: SingleChildScrollView(
            child: Column(
              children: List.generate(_horseNames.length, (index) => TextField(
                controller: _nameControllers[index],
                decoration: InputDecoration(labelText: 'Horse ${index + 1} Name'),
              )),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                setState(() {
                  for (int i = 0; i < _horseNames.length; i++) {
                    _horseNames[i] = _nameControllers[i].text;
                  }
                });
                Navigator.of(context).pop();
              },
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
        title: Text('Race Night Betting - Race $_selectedRaceNumber'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _openRaceSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: 'Select Race Number',
                border: OutlineInputBorder(),
              ),
              value: _selectedRaceNumber,
              items: _raceNumbers.map<DropdownMenuItem<int>>((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(value.toString()),
                );
              }).toList(),
              onChanged: (int? newValue) {
                setState(() {
                  _selectedRaceNumber = newValue!;
                });
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Charity Takeout Percentage',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _updateCharityTakeout(value),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Bets: £${_total.floor()}', style: TextStyle(fontSize: 20)),
                Text('For Charity: £${_totalForCharity.floor()}', style: TextStyle(fontSize: 20, color: Colors.green)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _counts.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: InkWell(
                    onTap: () => _incrementCounter(index + 1),
                    child: Container(
                      padding: EdgeInsets.all(20.0),
                      color: _towelColors[index],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('${_horseNames[index]}', style: TextStyle(fontSize: 24, color: _numberColors[index])),
                          ),
                          Container(
                            padding: EdgeInsets.all(10.0),
                            color: Colors.black, // For visibility, use a neutral background in the right column
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Bets: ${_counts[index]}', style: TextStyle(fontSize: 18, color: Colors.white)),
                                Text('Dividend: £${_calculateDividend(index + 1).floor()}', style: TextStyle(fontSize: 18, color: Colors.white)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}