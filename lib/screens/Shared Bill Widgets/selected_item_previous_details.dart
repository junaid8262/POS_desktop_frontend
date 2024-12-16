import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/bills.dart';
import '../../models/item.dart';
import '../../models/vendor_bills.dart';
import '../../theme/theme.dart';

class SaleInformationCard extends StatelessWidget {
  final List<Bill> previousBills;
  final BillItem selectedItem;

  SaleInformationCard({required this.previousBills, required this.selectedItem});

  @override
  Widget build(BuildContext context) {
    // Check if there are any matching items across all bills
    final hasRelevantData = previousBills.any((bill) =>
        bill.items.any((item) => item.itemId == selectedItem.itemId));

    return Card(
      margin: EdgeInsets.all(8.0),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${selectedItem.name} Previous Customer Information', style: AppTheme.headline6),
            SizedBox(height: 8),
            Container(
              height: 150,
              child: !hasRelevantData
                ? Center(child: Text('No previous items found for this customer.'))
                  : SingleChildScrollView(
                child: Table(
                  border: TableBorder.all(
                    color: Colors.black54,
                    width: 1,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  columnWidths: {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(2),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(2),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                      ),
                      children: [
                        _buildHeaderCell('ID'),
                        _buildHeaderCell('Sale Rate'),
                        _buildHeaderCell('Qty'),
                        _buildHeaderCell('Date of Sale'),
                      ],
                    ),
                    // Only show rows if there's relevant data
                    for (var bill in previousBills)
                      for (var item in bill.items
                          .where((item) => item.itemId == selectedItem.itemId))
                        TableRow(
                          children: [
                            _buildDataCell('\$${item.itemId}'),
                            _buildDataCell('\$${item.saleRate.toStringAsFixed(2)}'),
                            _buildDataCell(item.quantity.toString()),
                            _buildDataCell(DateFormat('dd-MM-yyyy')
                                .format(DateTime.parse(bill.date))),
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

class SaleHistoryCard extends StatelessWidget {
  final List<BillItem> previousRates;
  final BillItem selectedItem;

  SaleHistoryCard({required this.previousRates, required this.selectedItem});

  @override
  Widget build(BuildContext context) {
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
              child: previousRates.isEmpty
                  ? Center(child: Text('No sale history available'))
                  : SingleChildScrollView(
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
                        _buildHeaderCell('Sales Rate'),
                        _buildHeaderCell('Date'),
                      ],
                    ),
                    for (var rate in previousRates)
                      TableRow(
                        children: [
                          _buildDataCell(rate.customerName.toString()),
                          _buildDataCell(rate.quantity.toString()),
                          _buildDataCell('\$${rate.saleRate.toStringAsFixed(2)}'),
                          _buildDataCell(rate.date.toString()),
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

class PurchaseHistoryCard extends StatelessWidget {
  final List<VendorBillItem> previousPurchaseRates;
  final BillItem selectedItem;

  PurchaseHistoryCard({required this.previousPurchaseRates, required this.selectedItem});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${selectedItem.name} Purchase History', style: AppTheme.headline6),
            SizedBox(height: 8),
            Container(
              height: 150,
              child: previousPurchaseRates.isEmpty
                  ? Center(child: Text('No purchase history available'))
                  : SingleChildScrollView(
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
                        _buildHeaderCell('Vendor Shop'),
                        _buildHeaderCell('Quantity'),
                        _buildHeaderCell('Purchase Rate'),
                        _buildHeaderCell('Date'),
                      ],
                    ),
                    for (var rate in previousPurchaseRates)
                      TableRow(
                        children: [
                          _buildDataCell(rate.vendorName ?? ''),
                          _buildDataCell(rate.quantity.toString() ?? ''),
                          _buildDataCell('\$${rate.purchaseRate.toStringAsFixed(2)}'),
                          _buildDataCell(rate.date.toString()),
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

