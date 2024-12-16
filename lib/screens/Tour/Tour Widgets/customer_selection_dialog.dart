import 'package:flutter/material.dart';
import '../../../models/customer.dart';

class CustomerSelectionDialog extends StatefulWidget {
  final List<Customer> customers;
  final void Function(List<Customer>) onCustomersSelected;

  const CustomerSelectionDialog({
    Key? key,
    required this.customers,
    required this.onCustomersSelected,
  }) : super(key: key);

  @override
  _CustomerSelectionDialogState createState() => _CustomerSelectionDialogState();
}

class _CustomerSelectionDialogState extends State<CustomerSelectionDialog> {
  late CustomerDataSource _dataSource;

  @override
  void initState() {
    super.initState();
    _dataSource = CustomerDataSource(
      customers: widget.customers,
      onEdit: (customer) {
        // Handle edit customer
        print('Edit Customer: ${customer.name}');
      },
      onDelete: (customerId) {
        // Handle delete customer
        print('Delete Customer ID: $customerId');
      },
      showLedger: (customer) {
        // Handle show ledger for customer
        print('Show Ledger for: ${customer.name}');
      },
    );
  }

  void _onSubmitSelection() {
    final selectedCustomers = _dataSource.getSelectedCustomers();
    widget.onCustomersSelected(selectedCustomers);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.5,
        height: MediaQuery.of(context).size.height * 0.6,
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Select Customers',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: PaginatedDataTable(
                  columns: [
                    DataColumn(label: Text('Customer Name')),
                    DataColumn(label: Text('Phone Number')),
                    DataColumn(label: Text('Address')),
                    DataColumn(label: Text('Tour')),
                    DataColumn(label: Text('Balance')),
                  ],
                  source: _dataSource,
                  rowsPerPage: PaginatedDataTable.defaultRowsPerPage,
                  availableRowsPerPage: [5, 10, 20],
                  showCheckboxColumn: true,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _onSubmitSelection,
              child: Text('Select Customers'),
            ),
          ],
        ),
      ),
    );
  }
}


class CustomerDataSource extends DataTableSource {
  final List<Customer> customers;
  final void Function(Customer) onEdit;
  final void Function(Customer) showLedger;
  final void Function(String) onDelete;

  List<Customer> _selectedCustomers = [];
  List<Customer> filteredCustomers;

  CustomerDataSource({
    required this.customers,
    required this.onEdit,
    required this.onDelete,
    required this.showLedger,
  }) : filteredCustomers = List.from(customers);

  // Get the selected customers
  List<Customer> getSelectedCustomers() {
    return _selectedCustomers;
  }

  void filterCustomers(String query) {
    final lowerQuery = query.toLowerCase();
    filteredCustomers = customers.where((customer) {
      return customer.name.toLowerCase().contains(lowerQuery);
    }).toList();
    notifyListeners();
  }

  @override
  DataRow? getRow(int index) {
    final customer = filteredCustomers[index];
    final isSelected = _selectedCustomers.contains(customer);

    return DataRow(
      selected: isSelected,
      onSelectChanged: (selected) {
        if (selected == true) {
          _selectedCustomers.add(customer);
        } else {
          _selectedCustomers.remove(customer);
        }
        notifyListeners();
      },
      cells: [
        DataCell(Text(customer.name)),
        DataCell(Text(customer.phoneNumber)),
        DataCell(Text(customer.address)),
        DataCell(Text(customer.tour)),
        DataCell(Text('\$${customer.balance.toStringAsFixed(2)}')),
      ],
    );
  }

  @override
  int get rowCount => filteredCustomers.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => _selectedCustomers.length;
}
