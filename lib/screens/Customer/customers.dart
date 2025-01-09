import 'package:flutter/material.dart';
import 'package:namer_app/models/customer.dart';
import 'package:namer_app/services/customers.dart';
import 'package:namer_app/theme/theme.dart';
import 'package:namer_app/components/input_field.dart';
import 'package:provider/provider.dart';

import '../../components/export_csv.dart';
import '../../components/user_provider.dart';
import '../../models/user.dart';
import 'customer_data_source.dart';
import 'Customer Ledger/customer_ledger.dart';
import 'edit_or_add_customer.dart';


class CustomerPage extends StatefulWidget {
  @override
  _CustomerPageState createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  final CustomerService _customerService = CustomerService();
  List<Customer> _customers = [];
  CustomerDataSource? _dataSource;
  bool _isLoading = true;
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
  TextEditingController _searchController = TextEditingController();
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  User? _user;

  @override
  void initState() {
    super.initState();
    _fetchRole();

    _fetchCustomers();
  }
  Future<void> _fetchRole() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _user = userProvider.user;
    print('provider check ${_user!.role}');
  }

  void _onSortCustomer<T>(Comparable<T> Function(Customer customer) getField, int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _dataSource?.sortCustomer(getField, ascending);
    });
  }


  Future<void> _confirmDeleteBill(String id) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      // Prevents closing the dialog by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Confirm Delete'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete this bill?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.redAccent),
              ),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await _deleteCustomer(id); // Call the delete function if confirmed
              },
            ),
          ],
        );
      },
    );
  }


  Future<void> _fetchCustomers() async {
    final customers = await _customerService.getCustomers();
    setState(() {
      _customers = customers;
      _dataSource = CustomerDataSource(
        customers: _customers,
        onEdit: _showAddEditCustomerDialog,
        onDelete: _confirmDeleteBill,
        showLedger: _showCustomerLedger,
        user: _user
      );
      _isLoading = false;
    });
  }

  Future<void>  _showCustomerLedger(Customer customer)async
  {
    showDialog(
      context: context,
      builder: (context) => CustomerLedger(
        customer:  customer,

      ),
    );
  }

  void _showAddEditCustomerDialog([Customer? customer]) {
    showDialog(
      context: context,
      builder: (context) => AddEditCustomerDialog(
        customer: customer,
        onCustomerSaved: _fetchCustomers,
      ),
    );
  }

  Future<void> _deleteCustomer(String id) async {
    await _customerService.deleteCustomer(id);
    _fetchCustomers();
  }

  void _onSearch(String query) {
    _dataSource?.filterCustomers(query);
  }

  void exportToEXCEL(BuildContext context, List<Customer> customer) {
    CsvExporter.exportCustomerData(customer, context); // Call the export utility
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 5)],
              color: Colors.white,
            ),
            child: PaginatedDataTable(
              header: Row(
                children: [
                  Text('Customer List', style: AppTheme.headline6),

                  Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        exportToEXCEL(context,_customers);
                        //_showAddDebitDialog(false); // Call your function to add a debit bill
                      },
                      child: Text('Export'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue, // Set button color if needed
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.15,
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearch,
                      decoration: InputDecoration(
                        labelText: 'Search',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: _fetchCustomers,
                  ),
                ],
              ),
              headingRowColor: WidgetStateProperty.resolveWith<Color?>(
                    (Set<WidgetState> states) {
                  return Colors.blue.withOpacity(0.2);
                },
              ),
              columns:  [
              DataColumn(
              label: Text('Name'),
              onSort: (columnIndex, ascending) {
                _onSortCustomer<String>(
                      (customer) => customer.name,
                  columnIndex,
                  ascending,
                );
              },
            ),
              DataColumn(
                label: Text('Phone'),
                onSort: (columnIndex, ascending) {
                  _onSortCustomer<String>(
                        (customer) => customer.phoneNumber,
                    columnIndex,
                    ascending,
                  );
                },
              ),
              DataColumn(
                label: Text('Address'),
                onSort: (columnIndex, ascending) {
                  _onSortCustomer<String>(
                        (customer) => customer.address,
                    columnIndex,
                    ascending,
                  );
                },
              ),

              DataColumn(
                label: Text('Balance'),
                onSort: (columnIndex, ascending) {
                  _onSortCustomer<num>(
                        (customer) => customer.balance,
                    columnIndex,
                    ascending,
                  );
                },
              ),
              DataColumn(
                label: Text('Actions'),
                onSort: null, // No sorting for actions
              ),
              ],
              source: _dataSource!,
              rowsPerPage: _rowsPerPage,
              onRowsPerPageChanged: (value) {
                setState(() {
                  _rowsPerPage = value!;
                });
              },
              availableRowsPerPage: [5, 10, 20, 30],
              columnSpacing: 20,
              horizontalMargin: 20,
              showCheckboxColumn: false,
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditCustomerDialog(),
        child: Icon(Icons.add),
      ),
    );
  }
}
