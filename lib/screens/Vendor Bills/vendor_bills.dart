import 'package:flutter/material.dart';
import 'package:namer_app/models/vendor.dart';
import 'package:namer_app/screens/Vendor%20Bills/vendor_bill_data_source.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../components/bussiness_info_provider.dart';
import '../../components/export_csv.dart';
import '../../components/user_provider.dart';
import '../../models/businessInfo.dart';
import '../../models/user.dart';
import '../../models/vendor_bills.dart';
import '../../services/vendor_bills.dart';
import 'Return Vendor Bill/edit_or_add_vendor_return_bill.dart';
import 'Vendor Bill Widgets/print_vendor_bill_pdf.dart';
import 'Vendor Bill Widgets/show_vendor_ bill_items.dart';
import 'edit_or_add_vendor_bill.dart';

class VendorBillsPage extends StatefulWidget {
  @override
  _VendorBillsPageState createState() => _VendorBillsPageState();
}

class _VendorBillsPageState extends State<VendorBillsPage> {
  final VendorBillService _vendorBillService = VendorBillService();
  List<VendorBill> _vendorBills = [];
  VendorBillsDataSource? _dataSource;
  bool _isLoading = true;
  Map<String, Vendor> _vendors = {};
  String? _role;
  bool _sortAscending = true;
  int _sortColumnIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
  String _selectedBillType = 'All'; // Default to 'All'
  User? _user;
  BusinessDetails? _businessDetails;

  @override
  void initState() {
    super.initState();

  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fetch business details and other data here, where the context is valid
    _fetchBusinessDetails();
    _fetchRole();
    _fetchVendorBills();
  }

  Future<void> _fetchBusinessDetails() async {
    final businessProvider = Provider.of<BusinessDetailsProvider>(context,listen :true);
    _businessDetails = businessProvider.businessDetails;
    print('provider check ${_businessDetails!.companyName}');
  }
  Future<void> _fetchRole() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _user = userProvider.user;
    print('provider check ${_user!.role}');
  }

  Future<void> _fetchVendorBills() async {
    try {
      final vendorBills = await _vendorBillService.getVendorBills();
      for (var bill in vendorBills) {
        final vendor = await _vendorBillService.getVendorById(bill.vendorId);
        _vendors[bill.vendorId] = vendor;
      }
      setState(() {
        _vendorBills = vendorBills;
        _dataSource = VendorBillsDataSource(
          vendorBills: _vendorBills,
          vendors: _vendors,
          onEdit: (VendorBill bill) {
            if (bill.billType == 'Return Bill') {
              // Call the class responsible for editing sales bills
              _showAddEditVendorReturnBillDialog(bill);
            } else {
              // Call another class responsible for editing non-sale bills (e.g., return bills)
              _showAddEditVendorBillDialog(bill);
            }
          },
          onDelete: _confirmDeleteVendorBill,
          toggleStatus: _toggleStatus,
          showBillItems: (bill,customer,) => ShowVendorBillItems.show(context, bill,customer,_businessDetails), // Use the static method here
          context: context,
          userRole: _role.toString(),
          printBill: VendorBillPdfGenerator.generatePdfAndView,
          user: _user,
            businessDetails: _businessDetails

        );
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      // Handle errors appropriately in your application (e.g., show a Snackbar or AlertDialog)
      print('Error fetching vendor bills: $error');
    }
  }

  void _billDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true, // Allows tapping outside to close the dialog
      barrierLabel: "Bill Options",
      transitionDuration: Duration(milliseconds: 300), // Transition duration
      pageBuilder: (context, animation1, animation2) {
        return Align(
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent, // Set transparent background for the dialog
            child: Container(
              width: MediaQuery.of(context).size.width * 0.35, // Responsive width
              padding: EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dialog title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bill Options',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  Divider(color: Colors.grey.shade300),
                  SizedBox(height: 20),

                  // Add Sale Bill
                  _optionTile(
                    icon: Icons.add_shopping_cart,
                    title: 'Add Vendor Sale Bill',
                    description: 'Create and manage a new vendor sale bill',
                    color: Colors.blue.shade600,
                    onTap: () {
                      Navigator.pop(context);
                      _showAddEditVendorBillDialog();
                    },
                  ),

                  SizedBox(height: 20),

                  // Add Return Bill
                  _optionTile(
                    icon: Icons.reply,
                    title: 'Add Vendor Return Bill',
                    description: 'Record return transaction for vendor bill',
                    color: Colors.red.shade600,
                    onTap: () {
                      Navigator.pop(context);
                      _showAddEditVendorReturnBillDialog();
                    },
                  ),

                  SizedBox(height: 30),

                  // Cancel button at the bottom (increased height)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 18), // Increased height
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: Colors.red.shade600,
                        // Add visual feedback on pressed
                        elevation: 5, // Raised effect when pressed
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: child,
        );
      },
    );
  }
  Widget _optionTile({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell( // Replaced GestureDetector with InkWell to add visual ripple effect
      onTap: onTap,
      borderRadius: BorderRadius.circular(12), // Ensure ripple effect fits the border
      splashColor: color.withOpacity(0.2), // Ripple effect color
      highlightColor: color.withOpacity(0.1), // Background color when pressed
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            // Leading Icon
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(width: 20),

            // Text Info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  void _showAddEditVendorReturnBillDialog([VendorBill? bill]) {
    showDialog(
      context: context,
      builder: (context) => AddEditVendorReturnBillDialog(
        bill: bill,
        onBillSaved: _fetchVendorBills,
      ),
    );
  }

  void _showAddEditVendorBillDialog([VendorBill? bill]) {
    showDialog(
      context: context,
      builder: (context) => AddEditVendorBillDialog(
        bill: bill,
        onBillSaved: _fetchVendorBills,
      ),
    );
  }

  Future<void> _confirmDeleteVendorBill(String id) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevents closing the dialog by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete this vendor bill?'),
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
                await _deleteVendorBill(id); // Call the delete function if confirmed
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteVendorBill(String id) async {
    try {
      await _vendorBillService.deleteVendorBill(id);
      _fetchVendorBills();
    } catch (error) {
      // Handle deletion errors
      print('Error deleting vendor bill: $error');
    }
  }

  void _showVendorBillItems(VendorBill bill) {
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

  void _toggleStatus(VendorBill bill) async {
    if (_role == 'admin') {
      try {
        setState(() {
          bill.status = bill.status == 'Completed' ? 'Non Completed' : 'Completed';
        });
        await _vendorBillService.updateVendorBill(bill.id, bill);
        _fetchVendorBills();
      } catch (error) {
        // Handle update errors
        print('Error updating vendor bill status: $error');
      }
    }
  }
  // Method to filter bills by type
  void _filterBillsByType(String billType) {
    setState(() {
      _selectedBillType = billType;
      _dataSource?.filterBillsByType(billType); // Use the filter method from the data source
    });
  }

  // Method to filter bills by search query
  void _onSearch(String query) {
    setState(() {
      _dataSource?.filterBills(query); // Use the filter method from the data source
    });
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
                  Text('Vendor Bills List', style: Theme.of(context).textTheme.headlineMedium),
                  Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        CsvExporter.exportVendorBills( _vendorBills,_vendors,context,); // Call the export utility
                        //_showAddDebitDialog(false); // Call your function to add a debit bill
                      },
                      child: Text('Export'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue, // Set button color if needed
                      ),
                    ),
                  ),
                  // Dropdown to filter by Bill Type
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 200, // Set a reasonable width for the dropdown
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedBillType,
                          items: ['All', 'Sale Bill', 'Return Bill'].map((String billType) {
                            return DropdownMenuItem<String>(
                              value: billType,
                              child: Text(billType),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedBillType = newValue!;
                              _dataSource!.filterBillsByType(_selectedBillType);
                            });
                          },
                          icon: Icon(Icons.arrow_drop_down),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 16),

                  // Search field
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.15,
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearch,
                      decoration: InputDecoration(
                        labelText: 'Search',
                        hintText: "Amount, Vendor Name, Item name",
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: _fetchVendorBills,
                  ),
                ],
              ),
              headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                  return Colors.blue.withOpacity(0.2);
                },
              ),
              columns: [
                DataColumn(
                  label: Text('S.No'),
                  onSort: (columnIndex, ascending) => setState(() {
                    _sortColumnIndex = columnIndex;
                    _sortAscending = ascending;
                    _dataSource?.sortBills<num>((bill) => _dataSource!.filteredVendorBills.indexOf(bill) + 1, ascending);
                  }),
                ),
                DataColumn(
                  label: Text('Bill ID'),
                  onSort: (columnIndex, ascending) => setState(() {
                    _sortColumnIndex = columnIndex;
                    _sortAscending = ascending;
                    _dataSource?.sortBills<String>((bill) => bill.id, ascending);
                  }),
                ),
                DataColumn(
                  label: Text('Vendor Shop'),
                  onSort: (columnIndex, ascending) => setState(() {
                    _sortColumnIndex = columnIndex;
                    _sortAscending = ascending;
                    _dataSource?.sortBills<String>((bill) => _vendors[bill.vendorId]?.businessName ?? '', ascending);
                  }),
                ),
                DataColumn(
                  label: Text('Total Amount'),
                  onSort: (columnIndex, ascending) => setState(() {
                    _sortColumnIndex = columnIndex;
                    _sortAscending = ascending;
                    _dataSource?.sortBills<num>((bill) => bill.totalAmount, ascending);
                  }),
                ),
                DataColumn(
                  label: Text('Bill Type'),
                  onSort: (columnIndex, ascending) => setState(() {
                    _sortColumnIndex = columnIndex;
                    _sortAscending = ascending;
                    _dataSource?.sortBills<String>((bill) => bill.billType, ascending);
                  }),
                ),
                DataColumn(
                  label: Text('Date'),
                  onSort: (columnIndex, ascending) => setState(() {
                    _sortColumnIndex = columnIndex;
                    _sortAscending = ascending;
                    _dataSource?.sortBills<DateTime>((bill) => DateTime.parse(bill.date), ascending);
                  }),
                ),


                DataColumn(label: Text('Actions')),
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
        onPressed: () => _billDialog(),
        child: Icon(Icons.add),
      ),
    );
  }
}

