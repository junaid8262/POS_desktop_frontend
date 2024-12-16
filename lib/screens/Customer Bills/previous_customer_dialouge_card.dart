import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/bills.dart';
import '../../theme/theme.dart'; // For formatting dates

class PreviousCustomerBillsCard extends StatefulWidget {
  final List<Bill> previousBills;

  PreviousCustomerBillsCard({required this.previousBills});

  @override
  _PreviousCustomerBillsCardState createState() => _PreviousCustomerBillsCardState();
}

class _PreviousCustomerBillsCardState extends State<PreviousCustomerBillsCard> {
  void _showBillItems(Bill bill) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[200],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Center(
            child: Text(
              'Invoice Summary',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: bill.items.map((item) {
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 4.0),
                                    Text(
                                      'Qty: ${item.quantity}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '\$${item.purchaseRate.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 4.0),
                                    Text(
                                      'Total: \$${item.total.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          color: Colors.grey[300],
                          thickness: 1,
                          height: 20,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 20.0),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blueAccent, Colors.lightBlueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.2),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '\$${bill.items.fold(0.0, (sum, item) => sum + item.total).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                backgroundColor: Colors.redAccent,
                shadowColor: Colors.redAccent.withOpacity(0.4),
                elevation: 5,
              ).copyWith(
                backgroundColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                  if (states.contains(MaterialState.hovered)) {
                    return Colors.redAccent.withOpacity(0.8);
                  } else if (states.contains(MaterialState.pressed)) {
                    return Colors.redAccent.withOpacity(0.6);
                  }
                  return Colors.redAccent;
                }),
              ),
              child: Text(
                'Close',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      elevation: 5, // Adds shadow to the card
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text('Previous Customer Bills', style: AppTheme.headline6),
            SizedBox(height: 8),

            // Wrap Table in a scrollable Container with a fixed height
            Container(
              height: 150, // Set height based on your requirement
              child: SingleChildScrollView(
                child: Table(
                  border: TableBorder.all(
                    color: Colors.black54,
                    width: 1, // Border width
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                  ),
                  columnWidths: {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(2),
                    2: FlexColumnWidth(2),
                    3: FlexColumnWidth(1),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        color: Colors.blue[100], // Header row background color
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                          child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                          child: Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                          child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                        ),
                        SizedBox(), // For "View Details" icon
                      ],
                    ),

                    // Scrollable rows displaying previous bills
                    for (var bill in widget.previousBills)
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                            child: Text(DateFormat('dd-MM-yyyy').format(DateTime.parse(bill.date))),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                            child: Text('\$${bill.totalAmount.toStringAsFixed(2)}'),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: bill.status == 'Completed' ? Colors.green[300] : Colors.red[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              child: Text(
                                bill.status,
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          if (bill.status == 'Completed')
                            IconButton(
                              icon: Icon(Icons.visibility),
                              onPressed: () {
                           _showBillItems(bill);}
                            )
                          else
                            SizedBox(), // Empty space if not completed
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
}
