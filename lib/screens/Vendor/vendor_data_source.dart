import 'package:flutter/material.dart';
import 'package:namer_app/models/vendor.dart';
import 'package:namer_app/screens/Vendor/vendor_action_datacell_request_logic.dart';

import '../../models/bills.dart';
import '../../models/user.dart';
import '../../services/request.dart';

class VendorDataSource extends DataTableSource {
  final List<Vendor> vendors;
  final void Function(Vendor) onEdit;
  final void Function(String) onDelete;
  final void Function(Vendor) showLedger;
  final User? user;

  List<Vendor> filteredVendors;

  VendorDataSource({
    required this.vendors,
    required this.onEdit,
    required this.onDelete,
    required this.showLedger,
    required this.user,
  }) : filteredVendors = List.from(vendors);
  final RequestService _requestService = RequestService();

  void filterVendors(String query) {
    final lowerQuery = query.toLowerCase();
    filteredVendors = vendors.where((vendor) {
      return vendor.name.toLowerCase().contains(lowerQuery) ||
          vendor.phoneNumber.toLowerCase().contains(lowerQuery) ||
          vendor.address.toLowerCase().contains(lowerQuery) ||
          vendor.businessName.toLowerCase().contains(lowerQuery);
    }).toList();
    notifyListeners();
  }

  void sortVendor<T>(Comparable<T> Function(Vendor vendor) getField, bool ascending) {
    filteredVendors.sort((a, b) {
      if (!ascending) {
        final Vendor temp = a;
        a = b;
        b = temp;
      }
      final Comparable<T> aValue = getField(a);
      final Comparable<T> bValue = getField(b);
      return Comparable.compare(aValue, bValue);
    });
    notifyListeners();
  }

  @override
  DataRow? getRow(int index) {
    final vendor = filteredVendors[index];
    final List<Bill> vendorBill = [];
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(vendor.name)),
        DataCell(Text(vendor.phoneNumber)),
        DataCell(Text(vendor.address)),
        DataCell(Text(vendor.businessName)),
        DataCell(VendorActionDataCell(
          futureRequest: _requestService.getRequestByEmployeeAndDocument(user!.id, 'Vendor', vendor.id),
          employeeId: user!.id,
          documentType: 'Vendor',
          documentId: vendor.id,
          userRole: user!.role,
          onEdit: (vendor) => onEdit(vendor),
          onDelete: (vendorId) => onDelete(vendorId),
          showLedger: (vendor) => showLedger(vendor), // Ledger function
          vendor: vendor, // Current customer
        )),
      ],
      onSelectChanged: (selected) {
        // Optional: Add any onSelect behavior
      },
      color: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.hovered)) {
            return Colors.blue.withOpacity(0.1);
          }
          return null;
        },
      ),
    );
  }

  @override
  int get rowCount => filteredVendors.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
