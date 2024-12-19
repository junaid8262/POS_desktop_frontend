import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:namer_app/models/bills.dart';
import 'package:namer_app/models/businessInfo.dart';
import 'package:namer_app/models/customer.dart';

import '../../models/request.dart';
import '../../models/user.dart';

import 'package:shimmer/shimmer.dart';

import '../../services/request.dart';
import 'action_datacell_request_logic_widget.dart';

class BillsDataSource extends DataTableSource {
  final List<Bill> bills;
  final Map<String, Customer>? customers;
  final void Function(Bill) onEdit;
  final void Function(String) onDelete;
  final void Function(Bill,Customer) showBillItems;
  final void Function(Bill, Customer,String, BusinessDetails) printBill;
  final BuildContext context;
  List<Bill> filteredBills;
  final User? user;
  final BusinessDetails? businessDetails;

  BillsDataSource({
    required this.bills,
    required this.customers,
    required this.onEdit,
    required this.onDelete,
    required this.showBillItems,
    required this.context,
    required this.user,
    required this.printBill,
    required this.businessDetails,
  }) : filteredBills = List.from(bills)
    ..sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));


  final RequestService _requestService = RequestService();
  // Adding filter for Bill Type
  void filterBillsByType(String billType) {
    if (billType == 'All') {
      filteredBills = List.from(bills)
        ..sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date))); // Show all bills if 'All' is selected
    } else {
      filteredBills = bills.where((bill) => bill.billType == billType).toList(); // Filter by type
    }
    notifyListeners(); // Notify listeners to update the table
  }

  // Filter bills based on search query (e.g., customer name, item name, or total amount)
  void filterBills(String query) {
    final lowerQuery = query.toLowerCase();
    filteredBills
      ..clear()
      ..addAll(bills.where((bill) {
        final customer = customers?[bill.customerId];
        final customerName = customer?.name.toLowerCase() ?? '';
        final itemNames = bill.items.map((item) => item.name.toLowerCase()).join(' ');
        final totalAmount = bill.totalAmount.toString();
        return customerName.contains(lowerQuery) ||
            itemNames.contains(lowerQuery) ||
            totalAmount.contains(lowerQuery);
      }));
    notifyListeners();
  }

  // Sorting bills based on columns (e.g., Bill ID, Total Amount, Date, etc.)
  void sortBills<T>(Comparable<T> Function(Bill bill) getField, bool ascending) {
    filteredBills.sort((a, b) {
      final Bill c = a;
      if (!ascending) {
        a = b;
        b = c;
      }
      final Comparable<T> aValue = getField(a);
      final Comparable<T> bValue = getField(b);
      return Comparable.compare(aValue, bValue);
    });
    notifyListeners(); // Refresh the table
  }

  @override
  DataRow? getRow(int index) {
    final bill = filteredBills[index];
    final customer = customers?[bill.customerId];
    final formattedDate = DateFormat('dd-MM-yyyy').format(DateTime.parse(bill.date));

    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text((index + 1).toString())),

        // Adjust the width of the bill ID column
        DataCell(
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 80), // Set smaller width
            child: Text(bill.id, overflow: TextOverflow.ellipsis),
          ),
        ),

        DataCell(Text(customer != null ? customer.name : '')),
        DataCell(Text('\$${bill.totalAmount.toStringAsFixed(2)}')),
        DataCell(
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: bill.status == 'Completed' ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              bill.status,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),

        // Bill Type column with container color for Sale or Return
        DataCell(
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: bill.billType == 'Sale Bill' ? Colors.blueAccent : Colors.redAccent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              bill.billType,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),

        DataCell(Text(formattedDate)),
        DataCell(
          CustomerBillActionDataCell(
            futureRequest: _requestService.getRequestByEmployeeAndDocument(user!.id, 'Bill', bill.id),
            employeeId: user!.id,
            documentType: 'Bill',
            documentId: bill.id,
            userRole: user!.role,
            onEdit: (bill) => onEdit(bill),
            onDelete: (billId) => onDelete(billId),
            showBillItems: (bill, customer) => showBillItems(bill, customer),
            printBill: (bill, customer, billType, BusinessDetails) => printBill(bill, customer, billType,BusinessDetails!),
            bill: bill,
            customer: customer!,
            businessDetails: businessDetails,
          ),
        ),
      ],
    );
  }

  @override
  int get rowCount => filteredBills.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}



