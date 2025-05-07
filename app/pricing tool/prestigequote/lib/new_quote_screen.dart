// new_quote_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NewQuoteScreen extends StatefulWidget {
  final Map<String, dynamic>? initialCustomer;
  final int? quoteIndex;
  final Map<String, dynamic>? existingQuote;

  const NewQuoteScreen({Key? key, this.initialCustomer, this.quoteIndex, this.existingQuote}) : super(key: key);

  @override
  State<NewQuoteScreen> createState() => _NewQuoteScreenState();
}

class _NewQuoteScreenState extends State<NewQuoteScreen> {
  double _roomWidth = 0;
  double _roomLength = 0;
  double _roomHeight = 0;
  String _roomName = '';
  String _workDescription = '';
  double _plastererDays = 0;
  double _labourerDays = 0;
  Map<String, String> _materialQuantities = {};
  List<Map<String, dynamic>> _rooms = [];

  bool _customerViewOnly = false;
  double _selectedMarkup = 0.0;

  List<String> _roomTypes = ['Kitchen', 'Bedroom', 'Living Room', 'Bathroom', 'Hallway', 'Other'];
  List<String> _allMaterials = [];
  Map<String, double> _materialPrices = {};

  final _formKey = GlobalKey<FormState>();

  TextEditingController customerNameController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDefaultMarkup();
    _loadMaterialsFromSettings();
    if (widget.initialCustomer != null) {
      customerNameController.text = widget.initialCustomer!['name'] ?? '';
      addressController.text = widget.initialCustomer!['address'] ?? '';
      emailController.text = widget.initialCustomer!['email'] ?? '';
      phoneController.text = widget.initialCustomer!['phone'] ?? '';
    }
  }

  Future<void> _loadDefaultMarkup() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedMarkup = prefs.getDouble('defaultMarkup') ?? 0.0;
    });
  }

  Future<void> _loadMaterialsFromSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final materialString = prefs.getString('materials');
    if (materialString != null) {
      final decoded = List<Map<String, dynamic>>.from(json.decode(materialString));
      setState(() {
        _allMaterials = decoded.map((e) => e['name'].toString()).toList();
        _materialPrices = {
          for (var e in decoded)
            e['name'].toString(): double.tryParse(e['price'].toString()) ?? 0.0
        };
      });
    }
  }

  void saveQuote() async {
    if (!_formKey.currentState!.validate()) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final savedQuotesString = prefs.getString('savedQuotes');
    List<dynamic> savedQuotes = savedQuotesString != null ? json.decode(savedQuotesString) : [];

    double labourTotal = _rooms.fold(0, (sum, r) => sum + (r['labourerDays'] * 150));
    double plastererTotal = _rooms.fold(0, (sum, r) => sum + (r['plastererDays'] * 270));
    double materialCost = _rooms.fold(0, (sum, r) => sum + (r['materials'] as List).fold(0, (matSum, m) {
      String name = m['name'];
      double qty = double.tryParse(m['qty'].toString()) ?? 0.0;
      return matSum + ((_materialPrices[name] ?? 0.0) * qty);
    }));
    double markup = (_selectedMarkup / 100) * materialCost;
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
    List<Map<String, dynamic>> materialList = _materialQuantities.entries
        .where((entry) => entry.value.trim().isNotEmpty)
        .map((entry) => {
              'name': entry.key,
              'qty': entry.value,
            })
        .toList();

    double wallArea = 2 * (_roomWidth + _roomLength) * _roomHeight;
    double ceilingArea = _roomWidth * _roomLength;
    double totalCeilingWithWaste = (ceilingArea * 1.10);
    double boardSmallArea = 1.8 * 0.9;
    double boardLargeArea = 2.4 * 1.2;
    int smallBoardQty = (totalCeilingWithWaste / boardSmallArea).ceil();
    int largeBoardQty = (totalCeilingWithWaste / boardLargeArea).ceil();
    double covingLength = 2 * (_roomWidth + _roomLength);

    setState(() {
      _rooms.add({
        'name': _roomName,
        'plastererDays': _plastererDays,
        'labourerDays': _labourerDays,
        'materials': materialList,
        'wallArea': wallArea,
        'ceilingArea': ceilingArea,
        'smallBoards': smallBoardQty,
        'largeBoards': largeBoardQty,
        'covingLength': covingLength,
        'description': _workDescription,
      });
      _roomName = '';
      _plastererDays = 0;
      _labourerDays = 0;
      _materialQuantities = {};
      _roomWidth = 0;
      _roomLength = 0;
      _roomHeight = 0;
      _workDescription = '';
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
              DropdownButtonFormField<double>(
                value: _selectedMarkup,
                decoration: InputDecoration(labelText: 'Material Markup %'),
                items: [0, 5, 10, 15, 20].map((e) => DropdownMenuItem(value: e.toDouble(), child: Text('$e%'))).toList(),
                onChanged: (val) async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setDouble('defaultMarkup', val ?? 0.0);
                  setState(() => _selectedMarkup = val ?? 0.0);
                },
              ),
              SizedBox(height: 20),
              Text('Room Dimensions (meters)', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Width'),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => _roomWidth = double.tryParse(val) ?? 0,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Length'),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => _roomLength = double.tryParse(val) ?? 0,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Height'),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => _roomHeight = double.tryParse(val) ?? 0,
                    ),
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                value: _roomName.isNotEmpty ? _roomName : null,
                items: _roomTypes.map((room) => DropdownMenuItem(value: room, child: Text(room))).toList(),
                onChanged: (val) => setState(() => _roomName = val ?? ''),
                decoration: InputDecoration(labelText: 'Room Type'),
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
              TextFormField(
                decoration: InputDecoration(labelText: 'Work Description'),
                maxLines: 3,
                onChanged: (val) => _workDescription = val,
              ),
              SizedBox(height: 10),
              Text('Materials & Quantities', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._allMaterials.map((material) {
                return Row(
                  children: [
                    Expanded(child: Text(material)),
                    SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(hintText: 'Qty (e.g. 2.5)'),
                        keyboardType: TextInputType.number,
                        onChanged: (val) => _materialQuantities[material] = val,
                      ),
                    ),
                  ],
                );
              }).toList(),
              SizedBox(height: 10),
              ElevatedButton(onPressed: addRoom, child: Text('Add Room')),
              Divider(),
              ..._rooms.map((room) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text(room['name'] ?? 'Unnamed Room'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(room['description'] ?? ''),
                        Text('${room['plastererDays']} Plasterer, ${room['labourerDays']} Labourer'),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Wall Area: ${room['wallArea'].toStringAsFixed(2)} m²'),
                        Text('Ceiling Area: ${room['ceilingArea'].toStringAsFixed(2)} m²'),
                        Text('Small Boards Needed: ${room['smallBoards']}'),
                        Text('Large Boards Needed: ${room['largeBoards']}'),
                        Text('Coving Length: ${room['covingLength'].toStringAsFixed(2)} m'),
                      ],
                    ),
                  )
                ],
              )),
              Divider(),
              Builder(
                builder: (context) {
                  double labourTotal = _rooms.fold(0, (sum, r) => sum + (r['labourerDays'] * 150));
                  double plastererTotal = _rooms.fold(0, (sum, r) => sum + (r['plastererDays'] * 270));
                  double materialCost = _rooms.fold(0, (sum, r) => sum + (r['materials'] as List).fold(0, (matSum, m) {
                    String name = m['name'];
                    double qty = double.tryParse(m['qty'].toString()) ?? 0.0;
                    return matSum + ((_materialPrices[name] ?? 0.0) * qty);
                  }));
                  double markup = (_selectedMarkup / 100) * materialCost;
                  double total = labourTotal + plastererTotal + materialCost + markup;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_customerViewOnly) ...[
                        Text('Plasterer Total: £${plastererTotal.toStringAsFixed(2)}'),
                        Text('Labourer Total: £${labourTotal.toStringAsFixed(2)}'),
                        Text('Materials Cost: £${materialCost.toStringAsFixed(2)}'),
                        Text('Markup (${_selectedMarkup.toStringAsFixed(0)}%): £${markup.toStringAsFixed(2)}'),
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