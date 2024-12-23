import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:namer_app/services/bills.dart';

import '../../models/bills.dart';
import '../../theme/theme.dart';
class SalesHistoryCard extends StatelessWidget {
  final String itemId;
  final BillItem selectedItem;

  SalesHistoryCard({required this.itemId, required this.selectedItem});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: BillService().fetchItemPurchaseDetails(itemId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No sale history available.'));
        }

        final rates = snapshot.data!;
        return Card(
          margin: EdgeInsets.all(8.0),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${selectedItem.name} Sale History', style: AppTheme.headline6),
                SizedBox(height: 8),
                Container(
                  height: 150,
                  child: SingleChildScrollView(
                    child: Table(
                      border: TableBorder.all(
                        color: Colors.black54,
                        width: 1,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      columnWidths: {
                        0: FlexColumnWidth(3),
                        1: FlexColumnWidth(2),
                        2: FlexColumnWidth(2),
                        3: FlexColumnWidth(2),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                          ),
                          children: [
                            _buildHeaderCell('Customer'),
                            _buildHeaderCell('Quantity'),
                            _buildHeaderCell('Sale Rate'),
                            _buildHeaderCell('Date'),
                          ],
                        ),
                        for (var rate in rates)
                          TableRow(
                            children: [
                              _buildDataCell(rate['customerName'].toString()),
                              _buildDataCell(rate['quantity'].toString()),
                              _buildDataCell('\$${rate['saleRate'].toStringAsFixed(2)}'),
                              _buildDataCell(DateFormat('dd-MM-yyyy')
                                  .format(DateTime.parse(rate['date']))),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCell(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildDataCell(String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Text(value),
    );
  }
}
