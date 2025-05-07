import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help / About'),
        backgroundColor: Colors.blue[900],
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Prestige Quote App\n\n'
          'Use this app to build, save, and manage professional room-by-room quotes.\n\n'
          'Features:\n'
          '- Add customers\n'
          '- Input room dimensions\n'
          '- Auto-calculate m², plasterboards & coving\n'
          '- Save quotes for future editing\n\n'
          'Contact: daniel.boalch@prestigepropertysolutions.co.uk',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
