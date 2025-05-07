import 'package:flutter/material.dart';

class QuoteSummaryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> rooms;

  const QuoteSummaryScreen({super.key, required this.rooms});

  @override
  State<QuoteSummaryScreen> createState() => _QuoteSummaryScreenState();
}

class _QuoteSummaryScreenState extends State<QuoteSummaryScreen> {
  final double plastererRate = 270.0;
  final double labourerRate = 150.0;
  final double markupRate = 0.15;
  final double vatRate = 0.20;

  // Placeholder material prices (replace later with B&Q sync)
  final Map<String, double> materialPrices = {
    'pva': 7.0,
    'plasterboard': 12.0,
    'scrim': 3.0,
    'beads': 4.0,
    'bonding': 10.0,
    'multi': 9.0,
    'waste': 20.0,
    'angleBeads': 4.0,
    'covingManual': 8.0,
  };

  bool _customerMode = false;

  double calculateMaterialCost(Map<String, dynamic> room) {
    double total = 0;
    materialPrices.forEach((key, price) {
      total += (room[key] ?? 0) * price;
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    double totalLabour = 0;
    double totalMaterials = 0;

    List<Map<String, dynamic>> processedRooms = widget.rooms.map((room) {
      double labour = (room['plastererDays'] * plastererRate) +
                      (room['labourerDays'] * labourerRate);
      double materials = calculateMaterialCost(room);
      double subtotal = labour + materials;
      double markup = subtotal * markupRate;
      double vat = (_customerMode ? 0 : (subtotal + markup) * vatRate);
      double total = subtotal + markup + vat;

      totalLabour += labour;
      totalMaterials += materials;

      return {
        'room': room['room'],
        'labour': labour,
        'materials': materials,
        'markup': markup,
        'vat': vat,
        'total': total,
      };
    }).toList();

    double grandSubtotal = totalLabour + totalMaterials;
    double grandMarkup = grandSubtotal * markupRate;
    double grandVAT = (_customerMode ? 0 : (grandSubtotal + grandMarkup) * vatRate);
    double grandTotal = grandSubtotal + grandMarkup + grandVAT;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quote Summary'),
        backgroundColor: Colors.blue[900],
        actions: [
          Switch(
            value: _customerMode,
            onChanged: (val) => setState(() => _customerMode = val),
            activeColor: Colors.green,
          ),
          const Padding(
            padding: EdgeInsets.only(right: 10),
            child: Center(child: Text('Customer View')),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (var room in processedRooms)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                title: Text(room['room']),
                subtitle: _customerMode
                    ? Text('Total: £${room['total'].toStringAsFixed(2)}')
                    : Text(
                        'Labour: £${room['labour'].toStringAsFixed(2)}\n'
                        'Materials: £${room['materials'].toStringAsFixed(2)}\n'
                        'Markup: £${room['markup'].toStringAsFixed(2)}\n'
                        'VAT: £${room['vat'].toStringAsFixed(2)}\n'
                        'Total: £${room['total'].toStringAsFixed(2)}',
                      ),
              ),
            ),
          const Divider(),
          ListTile(
            title: const Text('Totals'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_customerMode)
                  Text('Labour: £${totalLabour.toStringAsFixed(2)}\n'
                      'Materials: £${totalMaterials.toStringAsFixed(2)}\n'
                      'Markup: £${grandMarkup.toStringAsFixed(2)}\n'
                      'VAT: £${grandVAT.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                Text(
                  'Grand Total: £${grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // TODO: Export/send quote
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export feature coming soon')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[900],
              padding: const EdgeInsets.all(16),
            ),
            child: const Text('Send or Export Quote'),
          ),
        ],
      ),
    );
  }
}
