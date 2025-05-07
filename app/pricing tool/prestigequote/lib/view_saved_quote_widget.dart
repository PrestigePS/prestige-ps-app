import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ViewSavedQuoteWidget extends StatefulWidget {
  final Map<String, dynamic>? initialCustomer;
  final int? quoteIndex;
  final Map<String, dynamic>? existingQuote;

  const ViewSavedQuoteWidget({Key? key, this.initialCustomer, this.quoteIndex, this.existingQuote}) : super(key: key);

  @override
  State<ViewSavedQuoteWidget> createState() => _ViewSavedQuoteWidgetState();
}

class _ViewSavedQuoteWidgetState extends State<ViewSavedQuoteWidget> {
  String _roomName = '';
  double _plastererDays = 0;
  double _labourerDays = 0;
  List<String> _selectedMaterials = [];
  List<Map<String, dynamic>> _rooms = [];

  bool _customerViewOnly = false;

  final List<String> _allMaterials = [
    'Multi Finish', 'Bonding', 'Hardwall', 'PVA', 'SBR', 'Grit',
    'Angle Beads', 'Stop Beads', 'Scrim'
  ];
  final _formKey = GlobalKey<FormState>();

  TextEditingController customerNameController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialCustomer != null) {
      customerNameController.text = widget.initialCustomer!['name'] ?? '';
      addressController.text = widget.initialCustomer!['address'] ?? '';
      emailController.text = widget.initialCustomer!['email'] ?? '';
      phoneController.text = widget.initialCustomer!['phone'] ?? '';
    }
  }

  void saveQuote() async {
    if (!_formKey.currentState!.validate()) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final savedQuotesString = prefs.getString('savedQuotes');
    List<dynamic> savedQuotes = savedQuotesString != null ? json.decode(savedQuotesString) : [];

    double labourTotal = _rooms.fold(0, (sum, r) => sum + (r['labourerDays'] * 150));
    double plastererTotal = _rooms.fold(0, (sum, r) => sum + (r['plastererDays'] * 270));
    double materialCost = _rooms.fold(0, (sum, r) => sum + (r['materials'].length * 20));
    double markup = 0.15 * (labourTotal + plastererTotal + materialCost);
    double total = labourTotal + plastererTotal + materialCost + markup;

    Map<String, dynamic> newQuote = {
      'customerName': customerNameController.text,
      'address': addressController.text,
      'email': emailController.text,
      'phone': phoneController.text,
      'date': DateTime.now().toIso8601String(),
      'total': total,
      'rooms': _rooms
    };

    if (widget.quoteIndex != null && widget.quoteIndex! < savedQuotes.length) {
      savedQuotes[widget.quoteIndex!] = newQuote;
    } else {
      savedQuotes.add(newQuote);
    }

    await prefs.setString('savedQuotes', json.encode(savedQuotes));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Quote saved and total updated')),
    );
  }

  void addRoom() {
    if (_roomName.isEmpty) return;
    setState(() {
      _rooms.add({
        'name': _roomName,
        'plastererDays': _plastererDays,
        'labourerDays': _labourerDays,
        'materials': List<String>.from(_selectedMaterials),
      });
      _roomName = '';
      _plastererDays = 0;
      _labourerDays = 0;
      _selectedMaterials.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('New Quote')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: customerNameController,
                decoration: InputDecoration(labelText: 'Customer Name'),
                validator: (value) => value!.isEmpty ? 'Enter customer name' : null,
              ),
              TextFormField(
                controller: addressController,
                decoration: InputDecoration(labelText: 'Address'),
              ),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(labelText: 'Phone'),
              ),
              SwitchListTile(
              title: Text('Customer View (Total Only)'),
              value: _customerViewOnly,
              onChanged: (val) => setState(() => _customerViewOnly = val),
            ),
              SizedBox(height: 20),

              Text('Rooms', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(labelText: 'Room Name'),
                onChanged: (val) => setState(() => _roomName = val),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Plasterer Days'),
                keyboardType: TextInputType.number,
                onChanged: (val) => _plastererDays = double.tryParse(val) ?? 0,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Labourer Days'),
                keyboardType: TextInputType.number,
                onChanged: (val) => _labourerDays = double.tryParse(val) ?? 0,
              ),
              Text('Materials'),
              Wrap(
                spacing: 8,
                children: _allMaterials.map((material) {
                  final selected = _selectedMaterials.contains(material);
                  return FilterChip(
                    label: Text(material),
                    selected: selected,
                    onSelected: (bool value) {
                      setState(() {
                        if (value) {
                          _selectedMaterials.add(material);
                        } else {
                          _selectedMaterials.remove(material);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: addRoom,
                child: Text('Add Room'),
              ),
              ..._rooms.map((room) => ListTile(
                    title: Text(room['name'] ?? 'Unnamed Room'),
                    subtitle: Text('${room['plastererDays']} Plasterer, ${room['labourerDays']} Labourer'),
                  )),
              Divider(),
              Text('Quote Summary', style: TextStyle(fontWeight: FontWeight.bold)),
              Builder(
                builder: (context) {
                  double labourTotal = _rooms.fold(0, (sum, r) => sum + (r['labourerDays'] * 150));
                  double plastererTotal = _rooms.fold(0, (sum, r) => sum + (r['plastererDays'] * 270));
                  double materialCost = _rooms.fold(0, (sum, r) => sum + (r['materials'].length * 20));
                  double markup = 0.15 * (labourTotal + plastererTotal + materialCost);
                  double total = labourTotal + plastererTotal + materialCost + markup;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_customerViewOnly) ...[
                        Text('Plasterer Total: £${plastererTotal.toStringAsFixed(2)}'),
                        Text('Labourer Total: £${labourTotal.toStringAsFixed(2)}'),
                        Text('Materials Cost: £${materialCost.toStringAsFixed(2)}'),
                        Text('Markup (15%): £${markup.toStringAsFixed(2)}'),
                      ],
                      Text('Grand Total: £${total.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  );
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: saveQuote,
                child: Text('Save Quote'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
