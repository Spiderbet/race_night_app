import 'package:flutter/material.dart';

class RaceNightHeader extends StatelessWidget {
  final String? title;

  const RaceNightHeader({Key? key, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Logo Image
          Center(
            child: Image.asset(
              'images/img_logo.png', // Replace with the path to your logo
              height: 80.0,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 8.0),
          // Title (optional)
          if (title != null)
            Text(
              title!,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}