import 'package:flutter/material.dart';
import 'view_saved_quote_widget.dart';

class SavedQuotesScreen extends StatelessWidget {
  const SavedQuotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Quotes'),
        backgroundColor: Colors.blue[900],
      ),
      body: const ViewSavedQuoteWidget(),
    );
  }
}
