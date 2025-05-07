// settings_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isVatRegistered = false;
  String _selectedVatType = 'Normal VAT';

  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _vatNumberController = TextEditingController();
  final TextEditingController _companyNumberController = TextEditingController();
  final TextEditingController _utrController = TextEditingController();
  final TextEditingController _niNumberController = TextEditingController();
  final TextEditingController _labourRateController = TextEditingController();

  final List<String> _vatTypes = [
    'Normal VAT',
    'Domestic Reverse Charge',
    'Zero-Rated VAT',
  ];

  List<Map<String, dynamic>> _materials = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final materialString = prefs.getString('materials');
    final labourRate = prefs.getDouble('labour_rate') ?? 270.0;

    setState(() {
      _labourRateController.text = labourRate.toString();
      _materials = materialString != null
          ? List<Map<String, dynamic>>.from(json.decode(materialString))
          : [
              {'name': 'Multi-Finish', 'price': 9.97},
              {'name': 'Bonding Coat', 'price': 15.70},
              {'name': 'PVA (5L)', 'price': 16.00},
              {'name': 'Angle Beads (2.4m)', 'price': 3.12},
              {'name': 'Stop Beads (2.4m)', 'price': 6.98},
              {'name': '127mm Coving (2m)', 'price': 60.00},
              {'name': 'Plasterboard 1800x900', 'price': 9.59},
              {'name': 'Plasterboard 2400x1200', 'price': 12.97},
              {'name': 'Scrim Tape (90m)', 'price': 10.12},
              {'name': 'Hardwall Plaster (25kg)', 'price': 16.20},
            ];
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('labour_rate', double.tryParse(_labourRateController.text) ?? 270.0);
    await prefs.setString('materials', json.encode(_materials));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
  }

  void _addMaterial() {
    setState(() {
      _materials.add({'name': '', 'price': 0.0});
    });
  }

  void _removeMaterial(int index) {
    setState(() {
      _materials.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blue[900],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Business Info',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _businessNameController,
              decoration: const InputDecoration(labelText: 'Business Name'),
            ),
            TextField(
              controller: _companyNumberController,
              decoration: const InputDecoration(labelText: 'Company Number (Ltd only)'),
            ),
            TextField(
              controller: _utrController,
              decoration: const InputDecoration(labelText: 'UTR Number'),
            ),
            TextField(
              controller: _niNumberController,
              decoration: const InputDecoration(labelText: 'NI Number (sole trader only)'),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const Text(
              'VAT Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SwitchListTile(
              title: const Text('Are you VAT Registered?'),
              value: _isVatRegistered,
              onChanged: (val) {
                setState(() => _isVatRegistered = val);
              },
            ),
            if (_isVatRegistered) ...[
              const SizedBox(height: 10),
              const Text('Default VAT Type'),
              DropdownButton<String>(
                value: _selectedVatType,
                isExpanded: true,
                items: _vatTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedVatType = val!);
                },
              ),
              TextField(
                controller: _vatNumberController,
                decoration: const InputDecoration(labelText: 'VAT Registration Number'),
              ),
            ],
            const SizedBox(height: 20),
            const Divider(),
            const Text(
              'Labour & Materials',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _labourRateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Labour Rate Per Day (£)'),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Materials', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                  onPressed: _addMaterial,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._materials.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> mat = entry.value;
              return Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(labelText: 'Material'),
                      controller: TextEditingController(text: mat['name']),
                      onChanged: (val) => _materials[index]['name'] = val,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(text: mat['price'].toString()),
                      onChanged: (val) => _materials[index]['price'] = double.tryParse(val) ?? 0.0,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeMaterial(index),
                  )
                ],
              );
            }).toList(),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Save Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
