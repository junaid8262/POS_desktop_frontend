import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:namer_app/models/vendor_bills.dart';
import 'package:namer_app/models/vendor.dart';
import 'package:namer_app/screens/Vendor%20Bills/vendor_action_datacell_request_logic_widget.dart';

import '../../models/businessInfo.dart';
import '../../models/user.dart';
import '../../services/request.dart';

class VendorBillsDataSource extends DataTableSource {
  final List<VendorBill> vendorBills;
  final Map<String, Vendor>? vendors;
  final void Function(VendorBill) onEdit;
  final void Function(String) onDelete;
  final void Function(VendorBill) toggleStatus;
  final void Function(VendorBill,Vendor) showBillItems;
  final User? user;
  final BusinessDetails? businessDetails;

  final void Function(VendorBill, Vendor,String, BusinessDetails) printBill;

  final BuildContext context;
  List<VendorBill> filteredVendorBills;
  final String userRole;

  VendorBillsDataSource({
    required this.vendorBills,
    required this.vendors,
    required this.onEdit,
    required this.onDelete,
    required this.toggleStatus,
    required this.showBillItems,
    required this.context,
    required this.userRole,
    required this.printBill,
    required this.user,
    required this.businessDetails,
  }) : filteredVendorBills = List.from(vendorBills)
    ..sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));


  final RequestService _requestService = RequestService();

  // Adding filter for Bill Type
  void filterBillsByType(String billType) {
    if (billType == 'All') {
      filteredVendorBills = List.from(vendorBills)
        ..sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));

      // Show all bills if 'All' is selected
    } else {
      filteredVendorBills = vendorBills.where((bill) => bill.billType == billType).toList(); // Filter by type
    }
    notifyListeners();
  }

  // Search functionality for bills
  void filterBills(String query) {
    final lowerQuery = query.toLowerCase();
    filteredVendorBills
      ..clear()
      ..addAll(vendorBills.where((bill) {
        final vendor = vendors?[bill.vendorId];
        final vendorName = vendor?.name.toLowerCase() ?? '';
        final itemNames = bill.items.map((item) => item.name.toLowerCase()).join(' ');
        final totalAmount = bill.totalAmount.toString();
        return vendorName.contains(lowerQuery) ||
            itemNames.contains(lowerQuery) ||
            totalAmount.contains(lowerQuery);
      }));
    notifyListeners();
  }

  // Sorting bills based on columns (e.g., Bill ID, Total Amount, Date, etc.)
  void sortBills<T>(Comparable<T> Function(VendorBill bill) getField, bool ascending) {
    filteredVendorBills.sort((a, b) {
      final VendorBill c = a;
      if (!ascending) {
        a = b;
        b = c;
      }
      final Comparable<T> aValue = getField(a);
      final Comparable<T> bValue = getField(b);
      return Comparable.compare(aValue, bValue);
    });
    notifyListeners();
  }

  @override
  DataRow? getRow(int index) {
    final bill = filteredVendorBills[index];
    final vendor = vendors?[bill.vendorId];
    final formattedDate = DateFormat('dd-MM-yyyy').format(DateTime.parse(bill.date));
    print(bill.date);
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text((index + 1).toString())),
        DataCell(Text(bill.id)),
        DataCell(Text(vendor != null ? vendor.businessName : '')),
        DataCell(Text('\$${bill.totalAmount.toStringAsFixed(2)}')),
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

        // Bill Type column

        DataCell(
          VendorBillActionDataCell(
            futureRequest: _requestService.getRequestByEmployeeAndDocument(user!.id, 'VendorBill', bill.id),
            employeeId: user!.id,
            documentType: 'VendorBill',
            documentId: bill.id,
            userRole: user!.role,
            onEdit: (bill) => onEdit(bill),
            onDelete: (billId) => onDelete(billId),
            showBillItems: (bill, customer) => showBillItems(bill, customer),
            printBill: (bill, customer, billType,BusinessDetails) => printBill(bill, customer, billType,BusinessDetails! ),
            vendorBill: bill,
            vendor: vendor!,
            businessDetails: businessDetails,
          ),
        ),

      ],
    );
  }

  @override
  int get rowCount => filteredVendorBills.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
