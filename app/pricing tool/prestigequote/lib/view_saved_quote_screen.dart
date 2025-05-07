import 'package:flutter/material.dart';

class ViewSavedQuoteScreen extends StatelessWidget {
  const ViewSavedQuoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Quotes')),
      body: const Center(
        child: Text('No saved quotes yet.'),
      ),
    );
  }
}
