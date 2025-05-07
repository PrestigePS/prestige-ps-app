import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerDatabaseScreen extends StatefulWidget {
  const CustomerDatabaseScreen({super.key});

  @override
  State<CustomerDatabaseScreen> createState() => _CustomerDatabaseScreenState();
}

class _CustomerDatabaseScreenState extends State<CustomerDatabaseScreen> {
  List<Map<String, String>> customers = [];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('savedCustomers') ?? [];
    setState(() {
      customers = raw.map((c) => Map<String, String>.from(jsonDecode(c))).toList();
    });
  }

  Future<void> _saveCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = customers.map((c) => jsonEncode(c)).toList();
    await prefs.setStringList('savedCustomers', raw);
  }

  void _deleteCustomer(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Customer'),
        content: const Text('Are you sure you want to delete this customer?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => customers.removeAt(index));
      _saveCustomers();
    }
  }

  void _editCustomer(int index) {
    final c = customers[index];
    final nameCtrl = TextEditingController(text: c['name']);
    final phoneCtrl = TextEditingController(text: c['phone']);
    final emailCtrl = TextEditingController(text: c['email']);
    final addressCtrl = TextEditingController(text: c['address']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Customer'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                customers[index] = {
                  'name': nameCtrl.text,
                  'phone': phoneCtrl.text,
                  'email': emailCtrl.text,
                  'address': addressCtrl.text,
                };
              });
              _saveCustomers();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Database'),
        backgroundColor: Colors.blue[900],
      ),
      body: customers.isEmpty
          ? const Center(child: Text('No customers saved yet.'))
          : ListView.builder(
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final c = customers[index];
                return ListTile(
                  title: Text(c['name'] ?? ''),
                  subtitle: Text('${c['phone']} • ${c['email']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit), onPressed: () => _editCustomer(index)),
                      IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteCustomer(index)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
