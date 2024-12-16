import 'package:flutter/material.dart';
import 'package:namer_app/screens/Vendor/vendor_data_source.dart';
import 'package:namer_app/theme/theme.dart';
import 'package:provider/provider.dart';

import '../../components/export_csv.dart';
import '../../components/user_provider.dart';
import '../../models/user.dart';
import '../../models/vendor.dart';
import '../../services/vendors.dart';
import 'Vendor Ledger/vendor_ledger.dart';
import 'edit_or_add_vendor.dart';

class VendorPage extends StatefulWidget {
  @override
  _VendorPageState createState() => _VendorPageState();
}

class _VendorPageState extends State<VendorPage> {
  final VendorService _vendorService = VendorService();
  List<Vendor> _vendors = [];
  VendorDataSource? _dataSource;
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
    _fetchVendors();
  }

  Future<void> _fetchRole() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _user = userProvider.user;
    print('provider check ${_user!.role}');
  }
  void _onSortVendor<T>(Comparable<T> Function(Vendor vendor) getField, int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _dataSource?.sortVendor(getField, ascending);
    });
  }

  Future<void> _confirmDeleteVendor(String id) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevents closing the dialog by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete this vendor?'),
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
                await _deleteVendor(id); // Call the delete function if confirmed
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchVendors() async {
    final vendors = await _vendorService.getVendors();
    setState(() {
      _vendors = vendors;
      _dataSource = VendorDataSource(
          vendors: _vendors,
          onEdit: _showAddEditVendorDialog,
          onDelete: _confirmDeleteVendor,
          showLedger: _showVendorLedger,
          user: _user
      );
      _isLoading = false;
    });
  }

  Future<void>  _showVendorLedger(Vendor vendor)async
  {
    showDialog(
      context: context,
      builder: (context) => VendorLedger(
        vendor:  vendor,

      ),
    );
  }
  void _showAddEditVendorDialog([Vendor? vendor]) {
    showDialog(
      context: context,
      builder: (context) => AddEditVendorDialog(
        vendor: vendor,
        onVendorSaved: _fetchVendors,
      ),
    );
  }

  Future<void> _deleteVendor(String id) async {
    await _vendorService.deleteVendor(id);
    _fetchVendors();
  }

  void _onSearch(String query) {
    _dataSource?.filterVendors(query);
  }


  void exportToEXCEL(BuildContext context, List<Vendor> vendor) {
    CsvExporter.exportVendorData(vendor, context); // Call the export utility
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
                  Text('Vendor List', style: AppTheme.headline6),
                  Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        exportToEXCEL(context,_vendors);
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
                    onPressed: _fetchVendors,
                  ),
                ],
              ),
              headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                  return Colors.blue.withOpacity(0.2);
                },
              ),
              columns:  [
                DataColumn(
                  label: Text('Name'),
                  onSort: (columnIndex, ascending) {
                    _onSortVendor<String>(
                          (vendor) => vendor.name,
                      columnIndex,
                      ascending,
                    );
                  },
                ),
                DataColumn(
                  label: Text('Phone'),
                  onSort: (columnIndex, ascending) {
                    _onSortVendor<String>(
                          (vendor) => vendor.phoneNumber,
                      columnIndex,
                      ascending,
                    );
                  },
                ),
                DataColumn(
                  label: Text('Address'),
                  onSort: (columnIndex, ascending) {
                    _onSortVendor<String>(
                          (vendor) => vendor.address,
                      columnIndex,
                      ascending,
                    );
                  },
                ),
                DataColumn(
                  label: Text('Business Name'),
                  onSort: (columnIndex, ascending) {
                    _onSortVendor<String>(
                          (vendor) => vendor.businessName,
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
        onPressed: () => _showAddEditVendorDialog(),
        child: Icon(Icons.add),
      ),
    );
  }
}
