import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:namer_app/models/bills.dart';
import 'package:namer_app/models/businessInfo.dart';
import 'package:namer_app/models/customer.dart';
import 'package:namer_app/screens/Customer%20Bills/Bill%20Widgets/print_bill_pdf.dart';
import 'package:namer_app/services/bills.dart';
import 'package:provider/provider.dart';

import '../../components/bussiness_info_provider.dart';
import '../../components/export_csv.dart';
import '../../components/user_provider.dart';
import '../../models/user.dart';
import 'Bill Widgets/show_bill_items.dart';
import 'Return Customer Bill/edit_or_add_customer_return_bill.dart';
import 'bill_data_source.dart';
import 'edit_or_add_bill.dart';


class BillsPage extends StatefulWidget {
  @override
  _BillsPageState createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  final BillService _billService = BillService();
  List<Bill> _bills = [];
  BillsDataSource? _dataSource;
  bool _isLoading = true;
  Map<String, Customer> _customers = {};
  User? _user;
  BusinessDetails? _businessDetails;
  bool _sortAscending = true;
  int _sortColumnIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
  String _selectedBillType = 'All'; // Default value to 'All'

  @override
  void initState() {
    super.initState();
    print("debugging");
    // Do not call methods that depend on Inherited Widgets here
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fetch business details and other data here, where the context is valid
    _fetchBusinessDetails();
    _fetchRole();
    _fetchBills();
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

  Future<void> _fetchBills() async {
    final bills = await _billService.getBills();
    for (var bill in bills) {
      final customer = await _billService.getCustomerById(bill.customerId);
      _customers[bill.customerId] = customer;
    }
    setState(() {
      _bills = bills;
      _dataSource = BillsDataSource(
        bills: _bills,
        customers: _customers,
        onEdit: (Bill bill) {
          if (bill.billType == 'Return Bill') {
            // Call the class responsible for editing sales bills
            _showAddEditReturnBillDialog(bill);
          } else {
            // Call another class responsible for editing non-sale bills (e.g., return bills)
            _showAddEditBillDialog(bill);
          }
        },
        onDelete: _confirmDeleteBill,
        showBillItems: (bill,customer) => ShowBillItems.show(context, bill,customer,_businessDetails), // Use the static method here
        printBill: BillPdfGenerator.generatePdfAndView,
        context: context,
        user: _user,
        businessDetails: _businessDetails
      );
      _isLoading = false;
    });
  }

  void _showAddEditBillDialog([Bill? bill]) {
    showDialog(
      context: context,
      builder: (context) => AddEditBillDialog(
        bill: bill,
        onBillSaved: _fetchBills,));
        /*onBillSaved:   ()async{
          await DesktopMultiWindow.invokeMethod(0, 'refreshBills');}
      ));*/
  }

  void _showAddEditReturnBillDialog([Bill? bill]) {
    showDialog(
      context: context,
      builder: (context) => AddEditReturnBillDialog(
        bill: bill,
        onBillSaved: _fetchBills,
      ),
    );
  }

/*  void openNewBillWindow([Bill? bill]) async {
    final window = await DesktopMultiWindow.createWindow(jsonEncode({
      'args1': 'Sub window',
      'args2': 100,
      'args3': true,
      'billData': bill?.toJson(),  // Assuming `toJson()` serializes the bill data
    }));
    window
      ..setFrame(const Offset(100, 100) & const Size(600, 400))
      ..setTitle('Add/Edit Bill')
      ..show();
  }*/

  Future<void> _confirmDeleteBill( String id) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevents closing the dialog by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
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
                await _deleteBill(id); // Call the delete function if confirmed
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteBill(String id) async {
    await _billService.deleteBill(id);
    _fetchBills();
  }

  void _onSearch(String query) {
    setState(() {
      _dataSource?.filterBills(query);
    });
  }

  void _onSort<T>(Comparable<T> Function(Bill bill) getField, int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _dataSource?.sortBills(getField, ascending);
    });
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
                    title: 'Add Sale Bill',
                    description: 'Create and manage a new sale bill',
                    color: Colors.blue.shade600,
                    onTap: () {
                      Navigator.pop(context);
                      // todo only for testing purposes of the new package
                      _showAddEditBillDialog();
                       //openNewBillWindow();


                    },
                  ),

                  SizedBox(height: 20),

                  // Add Return Bill
                  _optionTile(
                    icon: Icons.reply,
                    title: 'Add Return Bill',
                    description: 'Record a return transaction for a bill',
                    color: Colors.red.shade600,
                    onTap: () {
                      Navigator.pop(context);
                      _showAddEditReturnBillDialog();
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

// A new option tile widget for modular UI
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


  void exportToEXCEL() {
    CsvExporter.exportCustomerBills(_bills,_customers, context); // Call the export utility
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              // Use the full width of the screen
              width: constraints.maxWidth,
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
                    Text(
                      'Customer Bills List',
                      style: TextStyle(fontSize: 20),
                    ),
                    Spacer(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          exportToEXCEL();
                          //_showAddDebitDialog(false); // Call your function to add a debit bill
                        },
                        child: Text('Export'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue, // Set button color if needed
                        ),
                      ),
                    ),
                    // Wrap the Dropdown inside a ConstrainedBox or SizedBox to limit its width
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

                    // Improved Search Field
                    Container(
                      width: MediaQuery.of(context).size.width * 0.20,
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearch,
                        decoration: InputDecoration(
                          labelText: 'Search',
                          hintText: "Amount, Customer Name, Item name",
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
                      onPressed: _fetchBills,
                    ),
                  ],
                ),

                headingRowColor:
                MaterialStateProperty.resolveWith<Color?>(
                      (Set<MaterialState> states) {
                    return Colors.blue.withOpacity(0.2);
                  },
                ),
                columns: [
                  DataColumn(
                    label: Text('S.No'),
                    onSort: (columnIndex, ascending) => _onSort<num>(
                          (bill) => _dataSource!.filteredBills
                          .indexOf(bill) +
                          1,
                      columnIndex,
                      ascending,
                    ),
                  ),
                  DataColumn(
                    label: Text('Bill ID'),
                    onSort: (columnIndex, ascending) => _onSort<String>(
                            (bill) => bill.id, columnIndex, ascending),
                  ),
                  DataColumn(
                    label: Text('Customer Name'),
                    onSort: (columnIndex, ascending) =>
                        _onSort<String>(
                              (bill) =>
                          _customers[bill.customerId]?.name ?? '',
                          columnIndex,
                          ascending,
                        ),
                  ),
                  DataColumn(
                    label: Text('Total Amount'),
                    onSort: (columnIndex, ascending) => _onSort<num>(
                            (bill) => bill.totalAmount, columnIndex,
                        ascending),
                  ),
                  DataColumn(
                    label: Text('Status'),
                    onSort: (columnIndex, ascending) => _onSort<String>(
                            (bill) => bill.status, columnIndex, ascending),
                  ),
                  DataColumn(
                    label: Text('Bill Type'),
                      onSort: (columnIndex, ascending) => _onSort<String>(
                      (bill) => bill.billType, columnIndex, ascending),
                  ),
                  DataColumn(
                    label: Text('Date'),
                    onSort: (columnIndex, ascending) =>
                        _onSort<DateTime>(
                              (bill) => DateTime.parse(bill.date),
                          columnIndex,
                          ascending,
                        ),
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
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _billDialog(),
        child: Icon(Icons.add),
      ),
    );
  }
}

