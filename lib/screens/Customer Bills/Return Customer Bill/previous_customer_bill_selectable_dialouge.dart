import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/bills.dart';
import '../../../models/item.dart';

class BillSearchAndDetailsScreen extends StatefulWidget {
  final List<Bill> previousBills;
  final Function(List<Map<String, dynamic>>) onItemsSelected; // Updated callback function

  BillSearchAndDetailsScreen({
    required this.previousBills,
    required this.onItemsSelected, // Receive callback in constructor
  });

  @override
  _BillSearchAndDetailsScreenState createState() => _BillSearchAndDetailsScreenState();
}

class _BillSearchAndDetailsScreenState extends State<BillSearchAndDetailsScreen> {
  TextEditingController _searchController = TextEditingController();
  List<Bill> _filteredBills = [];

  @override
  void initState() {
    super.initState();
    _filteredBills = widget.previousBills; // Initially, all bills are displayed
  }

  void _filterBills(String query) {
    setState(() {
      _filteredBills = widget.previousBills.where((bill) {
        return bill.items.any((item) => item.name.toLowerCase().contains(query.toLowerCase())) ||
            bill.date.contains(query); // Match by item name or date
      }).toList();
    });
  }
  void _showCustomerBillItems(Bill bill, Function(List<BillItem>) onReturnBillItems) {
    List<bool> selectedItems = List<bool>.filled(bill.items.length, false);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.grey[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            titlePadding: EdgeInsets.zero,
            title: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.redAccent, Colors.red],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(),
                  Text(
                    'Invoice Summary',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.white,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: Colors.red,
                      ),
                    ),
                  )
                ],
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
                      children: bill.items.asMap().entries.map((entry) {
                        int index = entry.key;
                        var item = entry.value;

                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10.0),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedItems[index] = !selectedItems[index];
                                  });
                                },
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            selectedItems[index]
                                                ? Icons.check_box_rounded
                                                : Icons.check_box_outline_blank_rounded,
                                            color: selectedItems[index] ? Colors.green : Colors.grey,
                                            size: 24,
                                          ),
                                        ],
                                      ),
                                    ),
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
                ],
              ),
            ),
            actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            actions: [
              Center(
                child: Column(
                  children: [
                    Text(
                      '${selectedItems.where((isSelected) => isSelected).length} item(s) selected',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                          onPressed: selectedItems.contains(true)
                              ? () {
                            List<BillItem> selectedBillItems = [];
                            for (int i = 0; i < selectedItems.length; i++) {
                              if (selectedItems[i]) {
                                selectedBillItems.add(bill.items[i]);
                              }
                            }
                            onReturnBillItems(selectedBillItems); // Call the callback with selected items
                            Navigator.pop(context);
                          }
                              : null, // Disable the button if no items are selected
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 36),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            backgroundColor: selectedItems.contains(true)
                                ? Colors.green
                                : Colors.grey, // Change color based on whether items are selected
                            shadowColor: Colors.green.withOpacity(0.4),
                            elevation: 5,
                          ),
                          child: Text(
                            'Add to Return Bill',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void onReturnBillItems(List<BillItem> selectedItems) {
    List<Map<String, dynamic>> convertedItemsWithAdditionalValue = selectedItems.map((billItem) {
      return {
        'item': Item(
          id: billItem.itemId,
          name: billItem.name,
          brand: 'Default Brand',  // Assuming no brand information in BillItem, setting a default brand
          availableQuantity: billItem.quantity,
          purchaseRate: billItem.purchaseRate,
          saleRate: billItem.saleRate,
          minStock: 1,  // Default value for minStock
          addedEditDate: billItem.date != null
              ? DateTime.parse(billItem.date!)
              : DateTime.now(),  // Use current date if no date provided in BillItem
          location: 'Unknown',  // Assuming no location information in BillItem, setting a default value
          picture: null,
          miniUnit: billItem.miniUnit// No picture information in BillItem
        ),
        'discount': billItem.itemDiscount,
      };
    }).toList();

    // Now return the list of items with additional values back to the parent
    widget.onItemsSelected(convertedItemsWithAdditionalValue);
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _filterBills(value);
              },
              decoration: InputDecoration(
                labelText: 'Search by item name or date',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),

          // Ensure ListView is wrapped inside Expanded to avoid layout issues
          Expanded(
            child: _filteredBills.isNotEmpty
                ? SingleChildScrollView(
              child: Table(
                border: TableBorder.all(
                  color: Colors.black54,
                  width: 1,
                  borderRadius: BorderRadius.circular(8),
                ),
                columnWidths: {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: Colors.red[100], // Header row background color
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 12.0),
                        child: Text('Date',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 12.0),
                        child: Text('Total Amount',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 12.0),
                        child: Text('View Details',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                      ),
                    ],
                  ),
                  // Scrollable rows displaying filtered bills
                  for (var bill in _filteredBills)
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 12.0),
                          child: Text(DateFormat('dd-MM-yyyy')
                              .format(DateTime.parse(bill.date))),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 12.0),
                          child: Text(
                              '\$${bill.totalAmount.toStringAsFixed(2)}'),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 12.0),
                          child: InkWell(
                            onTap: () {
                              _showCustomerBillItems(bill,onReturnBillItems);
                            },
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  "View Details",
                                  style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600),
                                ),
                                SizedBox(width: 10),
                                Icon(Icons.list, color: Colors.green),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            )
                : Center(
              child: Text(
                'No bills found',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
