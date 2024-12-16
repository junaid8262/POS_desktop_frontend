import 'package:flutter/material.dart';
import 'package:namer_app/models/customer.dart';

import '../../models/bills.dart';
import '../../models/user.dart';
import '../../services/request.dart';
import 'customer_action_datacell_request_logic.dart';



class CustomerDataSource extends DataTableSource {
  final List<Customer> customers;
  final void Function(Customer) onEdit;
  final void Function(Customer) showLedger;
  final void Function(String) onDelete;
  List<Customer> filteredCustomers;
  final User? user;


  CustomerDataSource({
    required this.customers,
    required this.onEdit,
    required this.onDelete,
    required this.showLedger,
    required this.user,
  }) : filteredCustomers = List.from(customers);
  final RequestService _requestService = RequestService();

  void filterCustomers(String query) {
    final lowerQuery = query.toLowerCase();
    filteredCustomers = customers.where((customer) {
      return customer.name.toLowerCase().contains(lowerQuery);
    }).toList();
    notifyListeners();
  }

  void sortCustomer<T>(Comparable<T> Function(Customer customer) getField, bool ascending) {
    filteredCustomers.sort((a, b) {
      if (!ascending) {
        final Customer temp = a;
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
    final customer = filteredCustomers[index];
    final List<Bill> customerBill = [];
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(customer.name)),
        DataCell(Text(customer.phoneNumber)),
        DataCell(Text(customer.address)),
        DataCell(Text('\$${customer.balance.toStringAsFixed(2)}')),
        DataCell(CustomerActionDataCell(
          futureRequest: _requestService.getRequestByEmployeeAndDocument(user!.id, 'Customer', customer.id),
          employeeId: user!.id,
          documentType: 'Customer',
          documentId: customer.id,
          userRole: user!.role,
          onEdit: (customer) => onEdit(customer),
          onDelete: (customerId) => onDelete(customerId),
          showLedger: (customer) => showLedger(customer), // Ledger function
          customer: customer, // Current customer
        )),
      ],
      onSelectChanged: (selected) {
        // Optional: Add any onSelect behavior
      },
      color: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
          if (states.contains(WidgetState.hovered)) {
            return Colors.blue.withOpacity(0.1);
          }
          return null;
        },
      ),
    );
  }

  @override
  int get rowCount => filteredCustomers.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}

