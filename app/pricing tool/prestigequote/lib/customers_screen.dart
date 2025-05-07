import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<Map<String, String>> customers = [];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList('savedCustomers') ?? [];
    setState(() {
      customers = rawList.map((e) => Map<String, String>.from(jsonDecode(e))).toList();
    });
  }

  Future<void> _saveCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = customers.map((c) => jsonEncode(c)).toList();
    await prefs.setStringList('savedCustomers', encoded);
    _loadCustomers();
  }

  void _addOrEditCustomer({Map<String, String>? existing, int? index}) {
    final nameController = TextEditingController(text: existing?['name']);
    final phoneController = TextEditingController(text: existing?['phone']);
    final emailController = TextEditingController(text: existing?['email']);
    final addressController = TextEditingController(text: existing?['address']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(index == null ? 'Add Customer' : 'Edit Customer'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newCustomer = {
                'name': nameController.text.trim(),
                'phone': phoneController.text.trim(),
                'email': emailController.text.trim(),
                'address': addressController.text.trim(),
              };
              setState(() {
                if (index != null) {
                  customers[index] = newCustomer;
                } else {
                  customers.add(newCustomer);
                }
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

  void _deleteCustomer(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Customer'),
        content: const Text('Are you sure you want to delete this customer?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                customers.removeAt(index);
              });
              _saveCustomers();
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        backgroundColor: Colors.blue[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addOrEditCustomer(),
          ),
        ],
      ),
      body: customers.isEmpty
          ? const Center(child: Text('No customers saved yet.'))
          : ListView.builder(
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final c = customers[index];
                return ListTile(
                  title: Text(c['name'] ?? ''),
                  subtitle: Text('${c['phone'] ?? ''}\n${c['email'] ?? ''}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit), onPressed: () => _addOrEditCustomer(existing: c, index: index)),
                      IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteCustomer(index)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
