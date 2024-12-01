import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:race_night_app/participant_ui/admin_screen.dart';
import 'package:race_night_app/participant_ui/manage_races_screen.dart';
import 'package:race_night_app/participant_ui/manage_users_screen.dart';
import 'package:senraise_printer/senraise_printer.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:auto_size_text/auto_size_text.dart';

import 'participant_ui/scan_nfc_screen.dart';
import 'participant_ui/place_bet_screen.dart';
import 'participant_ui/confirm_bet_screen.dart';
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(fontFamily: 'Poppins'),
      initialRoute: '/',
      routes: {
        '/': (context) => ScanNfcScreen(),
        '/placeBet': (context) {
          final nfcId = ModalRoute.of(context)?.settings.arguments as String;
          return PlaceBetScreen(nfcId: nfcId);
        },
        '/manageUsers': (context) => ManageUsersScreen(),
        '/admin': (context) => const AdminScreen(),
        '/manageRaces': (context) => ManageRacesScreen(),
        '/confirmBet': (context) {
          final arguments =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
          return ConfirmBetScreen(
            runner: arguments['runner'] as String,
            nfcId: arguments['nfcId'] as String,
            raceNumber: arguments['raceNumber'] as int,
          );
        },
      },
    );
  }
}


class BettingApp extends StatefulWidget {
  @override
  _BettingAppState createState() => _BettingAppState();
}

class _BettingAppState extends State<BettingApp> {
  final _senraisePrinterPlugin = SenraisePrinter();

  double get _totalAfterCharity => _total * (1 - _charityTakeout / 100);

  List<int> _counts = List.generate(8, (index) => 0);
  List<String> _horseNames = List.generate(8, (index) => 'Horse ${index + 1}');
  double _charityTakeout = 20.0;
  final TextEditingController _controller = TextEditingController(text: "20");
  List<TextEditingController> _nameControllers = [];
  int _selectedRaceNumber = 1;
  final List<int> _raceNumbers = List.generate(10, (index) => index + 1);

  // Define horse button color specifications explicitly here
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

  // Getter to calculate total bets
  int get _total => _counts.reduce((value, element) => value + element);

  // Getter to calculate total for charity
  double get _totalForCharity => _total * (_charityTakeout / 100);

  final List<List<String>> _raceHorseNames = [
    ["Mr. Piglet", "Swifty Sow", "Hog Wild", "Porcine Lightning", "Mudslide Maverick", "Squeal of Fortune", "Hammin' It Up", "Oinker Express"],
    ["Bacon Bolt", "Snout Runner", "Puddle Jumper", "Piggy Banker", "Razorback Rocket", "Curly Tail Comet", "Truffle Hunter", "Pork Chop Sprinter"],
    ["Sloppy Joe", "Muddy Buddy", "Trotter Trot", "Snout So Fast", "Greased Lightning", "Piglet's Dream", "Ham Solo", "Brisket Breaker"],
  ];

  @override
  void initState() {
    super.initState();
    _nameControllers = List.generate(8, (index) => TextEditingController(text: _horseNames[index]));
    updateHorseNamesForSelectedRace();
  }

  @override
  void dispose() {
    for (var controller in _nameControllers) {
      controller.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  void updateHorseNamesForSelectedRace() {
    setState(() {
      _horseNames = List.generate(8, (index) => "${index + 1}. ${_raceHorseNames[_selectedRaceNumber - 1][index]}");
    });
  }

  void _incrementCounter(int horseNumber) async {
    setState(() {
      _counts[horseNumber - 1]++;
    });

    // Prepare receipt text
    String receiptText = "\n\nRace #$_selectedRaceNumber\n\n"
        "${_horseNames[horseNumber - 1]}";

    // Attempt to print the receipt
    try {
      await _senraisePrinterPlugin.setAlignment(1);

      DateTime now = DateTime.now();
      DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
      String formattedDate = formatter.format(now);

      Uint8List data = (await rootBundle.load('images/img.png'))
          .buffer
          .asUint8List();
      await _senraisePrinterPlugin.printPic(data);
      await _senraisePrinterPlugin.setTextBold(true);
      await _senraisePrinterPlugin.setTextSize(40);
      await _senraisePrinterPlugin.printText(receiptText);
      await _senraisePrinterPlugin.setTextSize(24);
      await _senraisePrinterPlugin.printText("\n\nPlaced: ${formattedDate}\n\n\n\n");
    } catch (e) {
      print("Error printing receipt: $e");
    }
  }

  Future<Uint8List?> resizeImage(String path, int targetWidth) async {
    final Uint8List originalImageData = (await rootBundle.load(path)).buffer.asUint8List();

    final Uint8List? compressedImageData = await FlutterImageCompress.compressWithList(
      originalImageData,
      minWidth: targetWidth,
      quality: 95, // Adjust the quality as needed
      // Keep the aspect ratio:
      keepExif: true,
    );

    return compressedImageData;
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

  void _showRaceSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Race'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [1, 2, 3].map((raceNumber) => ListTile(
              title: Text('Race $raceNumber'),
              onTap: () {
                setState(() {
                  _selectedRaceNumber = raceNumber;
                  _counts = List.generate(8, (index) => 0);
                  updateHorseNamesForSelectedRace();
                });
                Navigator.of(context).pop();
              },
            )).toList(),
          ),
        );
      },
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 120,
        backgroundColor: Colors.black,
        // Remove the leading property if you previously added a logo there
        title: Container(
          height: 80, // Use the AppBar's standard height to guide the logo's size
          child: Image.asset(
            'images/img_logo.png',
            fit: BoxFit.contain, // This ensures the whole logo is visible and scaled correctly
          ),
        ),
        centerTitle: true, // Center the logo
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            color: Colors.white,
            onPressed: _openRaceSettings,
          ),
          IconButton(
            icon: Icon(Icons.flash_on),
            color: Colors.white,
            onPressed: _showRaceSelectionDialog, // Your onPressed logic
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
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
                SizedBox(width: 8.0), // Spacing between the two widgets
                Expanded(
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
              ],
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
                            child: AutoSizeText('${_horseNames[index]}', style: TextStyle(fontSize: 28, color: _numberColors[index]), maxLines: 1),
                          ),
                          Container(
                            padding: EdgeInsets.all(10.0),
                            margin: EdgeInsets.fromLTRB(20.0, 0, 0, 0),
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