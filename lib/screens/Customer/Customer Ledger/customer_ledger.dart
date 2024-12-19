import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:namer_app/models/businessInfo.dart';
import 'package:namer_app/services/customers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../../components/bussiness_info_provider.dart';
import '../../../components/export_csv.dart';
import '../../../models/bills.dart';
import '../../../models/customer.dart';
import '../../../services/bills.dart';
import '../../Customer Bills/Bill Widgets/show_bill_items.dart';
import 'debit_discount_bill_dialog.dart';

class CustomerLedger extends StatefulWidget {
  final Customer customer;

  CustomerLedger({
    required this.customer,
  });

  @override
  _CustomerLedgerState createState() => _CustomerLedgerState();
}

class _CustomerLedgerState extends State<CustomerLedger> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _debitController = TextEditingController();
  late List<Bill> _bills = [];
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
  int? _sortColumnIndex;
  bool _sortAscending = true;
  double _totalAmountToBePaid = 0.0;
  final BillService _billService = BillService();
  bool _isLoading = false;
  bool _hasData = false;
  double balance = 0;

  // Variables for date filtering
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _getCustomerBalance();
    _fetchBills();
    _calculateTotalAmountToBePaid();
  }

  void _getCustomerBalance() async {
    CustomerService customerService = CustomerService();
    double newBalance = await customerService.getCustomerBalance(widget.customer.id);
    print("balance is ${newBalance}");
    setState(() {
      balance = newBalance;
      print("balance upadted is ${balance}");

    });
  }

  // Filter bills based on the selected date range
  void _filterByDateRange() async {
    await _fetchBills();
    if (_startDate != null && _endDate != null) {
      final filteredBills = _bills.where((bill) {
        final billDate = DateTime.parse(bill.date);
        return billDate.isAfter(_startDate!) && billDate.isBefore(_endDate!);
      }).toList();

      setState(() {
        _bills = filteredBills;
      });
    }
  }

  // Show the date range picker dialog
  Future<void> _selectDateRange(BuildContext context) async {
    DateTime? startDate = _startDate ?? DateTime.now().subtract(Duration(days: 7));
    DateTime? endDate = _endDate ?? DateTime.now();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
              child: Container(
                height: 220,
                width: 320,
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Select Date Range",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDateButton(context, "Start Date", startDate!, (picked) {
                          setState(() {
                            startDate = picked;
                          });
                        }),
                        _buildDateButton(context, "End Date", endDate!, (picked) {
                          setState(() {
                            endDate = picked;
                          });
                        }),
                      ],
                    ),

                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async{


                        setState(() {
                          _startDate = startDate;
                          _endDate = endDate;
                        });
                        _filterByDateRange();
                        Navigator.of(context).pop();

                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text("APPLY"),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildDateButton(BuildContext context, String label, DateTime date, Function(DateTime) onDatePicked) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        SizedBox(height: 8),
        ElevatedButton(
          onPressed: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );
            if (pickedDate != null) {
              onDatePicked(pickedDate);
            }
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            _formatDate(date),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }


  String _formatDate(DateTime date) {
    final DateFormat formatter = DateFormat('dd MMM yyyy');
    return formatter.format(date);
  }


  void _filterBills(String query) {
    final filteredBills = _bills.where((bill) {
      final billIdLower = bill.id.toLowerCase();
      final creditLower = (bill.totalAmount ?? 0.0).toString().toLowerCase();
      final debitLower = (bill.amountGiven ?? 0.0).toString().toLowerCase();

      final searchLower = query.toLowerCase();
      return billIdLower.contains(searchLower) ||
          creditLower.contains(searchLower) ||
          debitLower.contains(searchLower);
    }).toList();

    setState(() {
      _bills = filteredBills;
    });
  }

  void _calculateTotalAmountToBePaid() {
    _totalAmountToBePaid = _bills.fold(0.0, (sum, bill) {
      final totalAmount = bill.totalAmount ?? 0.0;
      final amountGiven = bill.amountGiven ?? 0.0;
      return sum + (totalAmount - amountGiven);
    });
    setState(() {});
  }

  void _onSort<T>(Comparable<T> Function(Bill bill) getField, int columnIndex,
      bool ascending) {
    _bills.sort((a, b) {
      if (!ascending) {
        final Bill c = a;
        a = b;
        b = c;
      }
      final Comparable<T> aValue = getField(a);
      final Comparable<T> bValue = getField(b);
      return Comparable.compare(aValue, bValue);
    });
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  Color _getRowColor(Bill bill) {
    switch (bill.billType) {
      case 'Sale Bill':
        return Color(0xFFE3F2FD); // Light, professional blue for 'Sale Bill'
      case 'Debit Bill':
        return Color(0xFFE8F5E9); // Light, professional green for 'Debit Bill'
      case 'Return Bill':
        return Color(0xFFFFEBEE); // Light, professional red for 'Return Bill'
      case 'Discount Bill':
        return Color(0xFFFFF3E0); // Light, professional amber for 'Discount Bill'
      default:
        return Color(0xFFF5F5F5); // Neutral light grey for other types
    }
  }






  Widget _buildColorIndicator(String billType, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4), // Rounded edges for the indicator box
              border: Border.all(color: Colors.black26), // Optional border to make the color more distinct
            ),
          ),
          SizedBox(width: 10), // Spacing between the color indicator and the text
          Text(
            billType,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

// Method to add debit amount and refresh balance and bills
  void debit_credit_dialog_show(bool isDebitBill) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BillDialog(
          title: isDebitBill ? "Add Debit Bill" : "Add Discount Bill",
          customer: widget.customer,
          isDebitBill: isDebitBill,
          balance: balance,
          onBillAdded: () async {
            _getCustomerBalance();

            await _fetchBills(); // Fetch the bills after adding one
          },

        );
      },
    );
  }
// Method for fetching bills and refreshing the balance
  Future<void> _fetchBills() async {
    setState(() {
      _isLoading = true;
    });

    final bills = await _billService.getAllBillsForCustomerLedger();
    final filteredBills = bills.where((bill) => bill.customerId == widget.customer.id).toList();

    setState(() {
      _bills = filteredBills;
      _hasData = _bills.isNotEmpty;
      _isLoading = false;
    });

    if (_searchController.text.trim().isNotEmpty) {
      _filterBills(_searchController.text);
    }

    // Recalculate total balance after fetching bills
    _calculateTotalAmountToBePaid();

  }


  void exportToEXCEL(BuildContext context, List<Bill> bills) {
    CsvExporter.exportCustomerLedger(bills, context); // Call the export utility
  }


  @override
  Widget build(BuildContext context) {
    final businessProvider = Provider.of<BusinessDetailsProvider>(context,listen :true);

    return Dialog(
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text('Bill Actions'),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align buttons properly
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      exportToEXCEL(context,_bills);
                      //_showAddDebitDialog(false); // Call your function to add a debit bill
                    },
                    child: Text('Export'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // Set button color if needed
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      debit_credit_dialog_show(false);
                      //_showAddDebitDialog(false); // Call your function to add a debit bill
                    },
                    child: Text('Add Discount Bill'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // Set button color if needed
                    ),
                  ),
                ),
                // Button for Add Debit Bill
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      debit_credit_dialog_show(true);

                    },
                    child: Text('Add Debit Bill'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // Set button color if needed
                    ),
                  ),
                ),



                // Icon Button for Refresh Bills
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    icon: Icon(Icons.refresh, color: Colors.blueAccent.shade200),
                    onPressed: () {
                      _getCustomerBalance();
                      _fetchBills();
                    },
                  ),
                ),
              ],
            )
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _hasData
            ? Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'CUSTOMER NAME:',
                    style: TextStyle(
                        fontSize: 24,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    ' ${widget.customer.name.toUpperCase()}',
                    style: TextStyle(
                        fontSize: 24,
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Total Balance: ',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.blueGrey),
                  ),
                  Text(
                    'PKR ${balance!.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade600),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(0.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => _selectDateRange(context),
                    child: Text('Select Date Range'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                ),
              ),

              SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "${_startDate != null ? _formatDate(_startDate!) : 'Select'} - ${_endDate != null ? _formatDate(_endDate!) : 'Select'}",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildColorIndicator('Sale Bill', Color(0xFFE3F2FD)), // Professional light blue for 'Sale Bill'
                    _buildColorIndicator('Debit Bill', Color(0xFFE8F5E9)), // Professional light green for 'Debit Bill'
                    _buildColorIndicator('Return Bill', Color(0xFFFFEBEE)), // Professional light red for 'Return Bill'
                    _buildColorIndicator('Discount Bill', Color(0xFFFFF3E0)), // Professional light amber for 'Discount Bill'
                    _buildColorIndicator('Other Bill Type', Color(0xFFF5F5F5)), // Neutral light grey for others
                  ],
                ),
              ),


              Expanded(
                child: SingleChildScrollView(
                  child: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                      return ConstrainedBox(
                        constraints:
                        BoxConstraints(minWidth: constraints.maxWidth),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: PaginatedDataTable(
                            headingRowColor:
                            MaterialStateProperty.resolveWith<Color?>(
                                  (Set<MaterialState> states) {
                                return Colors.blue
                                    .shade100; // Light blue for headers
                              },
                            ),
                            columns: [
                              DataColumn(
                                label: Text('S.No',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                    textAlign: TextAlign.center),
                              ),
                              DataColumn(
                                label: Text('Bill ID',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                    textAlign: TextAlign.center),
                              ),
                              DataColumn(
                                label: Text('Bill Type',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                    textAlign: TextAlign.center),
                              ),
                              DataColumn(
                                label: Text('Date',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                    textAlign: TextAlign.center),
                              ),
                              DataColumn(
                                label: Text('Credit',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                    textAlign: TextAlign.center),
                              ),
                              DataColumn(
                                label: Text('Debit',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                    textAlign: TextAlign.center),
                              ),
                              DataColumn(
                                label: Text('Balance',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                    textAlign: TextAlign.center),
                              ),
                              DataColumn(
                                label: Text('Actions',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                              ),
                            ],
                            source: _LedgerBillDataSource(
                                _bills,
                                _getRowColor,
                                    (Bill bill) {
                                  // Define the action for editing a bill
                                  _editBill(bill);
                                },
                                    (Bill bill) {
                                  // Define the action for viewing a bill
                                  _viewBill(bill);
                                },
                              context,
                              widget.customer,
                                businessProvider.businessDetails),
                            columnSpacing: 10.0,
                            horizontalMargin: 10.0,
                            headingRowHeight:
                            56.0, // Adjust header height to match your design
                            dataRowHeight: 40.0, // Adjust row height
                            rowsPerPage: _rowsPerPage,
                            onRowsPerPageChanged: (value) {
                              setState(() {
                                _rowsPerPage = value!;
                              });
                            },
                            showCheckboxColumn: false,
                            sortColumnIndex: _sortColumnIndex,
                            sortAscending: _sortAscending,
                            // Adding borders around cells
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Total Amount to be Paid: PKR${balance!.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey),
                  ),
                ),
              ),
            ],
          ),
        )
            : Center(
          child: Text(
            'No bills found for this customer.',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  void _editBill(Bill bill) {

  }

  void _viewBill(Bill bill) {

  }

}

class _LedgerBillDataSource extends DataTableSource {
  final List<Bill> _bills;
  final Color Function(Bill) _getRowColor;
  final Function(Bill) onEdit;  // Callback for edit button
  final Function(Bill) onView;  // Callback for view button
  final BuildContext context; // Pass context here
  final Customer customer; // Pass context here
  final BusinessDetails? businessDetails; // Pass context here

  _LedgerBillDataSource(
      List<Bill> bills,
      this._getRowColor,
      this.onEdit,
      this.onView,
      this.context,
      this.customer,
      this.businessDetails
      ) : _bills = List.from(bills)
    ..sort((a, b) => DateTime.parse(b.date ?? '')
        .compareTo(DateTime.parse(a.date ?? '')));
  @override
  DataRow getRow(int index) {
    final Bill bill = _bills[index];
    final debit = bill.billType == "Return Bill" ? bill.totalAmount ?? 0.0 : bill.amountGiven ?? 0.0;
    final credit = bill.billType == "Return Bill" ? bill.amountGiven ?? 0.0 : bill.totalAmount ?? 0.0;

    double balance;

    if (index == 0) {
      balance = credit - debit;
    } else {
      double previousBalance = _getPreviousRowBalance(index - 1);
      balance = previousBalance + credit - debit;
    }

    final DateFormat dateFormat = DateFormat('dd-MM-yyyy');
    final String formattedDate = bill.date != null
        ? dateFormat.format(DateTime.parse(bill.date!))
        : 'N/A';

    final String billType = bill.billType ?? "N/A";

    return DataRow.byIndex(
      index: index,
      color: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
        return _getRowColor(bill); // Set row color based on your logic
      }),
      cells: [
        DataCell(Text((index + 1).toString())), // S.No.
        DataCell(Text(bill.id)), // Bill ID
        DataCell(Text(billType)), // Bill Type
        DataCell(Text(formattedDate)), // Date
        DataCell(Text(credit.toStringAsFixed(2))), // Credit
        DataCell(Text(debit.toStringAsFixed(2))), // Debit
        DataCell(Text(balance.toStringAsFixed(2))), // Balance
        DataCell(Row(
          children: [
            /*Tooltip(
              message: 'Edit Bill',
              child: IconButton(
                icon: Icon(Icons.edit, color: Colors.blueAccent), // Edit button
                onPressed: () {
                  onEdit(bill); // Trigger the edit action
                },
              ),
            ),*/
            Tooltip(
              message: 'View Bill Items',
              child: IconButton(
                icon: Icon(Icons.list, color: Colors.green),
                onPressed: () => {
                  if (bill.billType == "Sale Bill" || bill.billType == "Return Bill" )
                    {
                      ShowBillItems.show(context,bill, customer,businessDetails)
                    }
                  else if (bill.billType == "Discount Bill" || bill.billType == "Debit Bill" )
                    {
                      ShowBillItems.showDebitAndDiscountBill(context,bill, customer,businessDetails)
                    }
                },
              ),
            ),
          ],
        )), // Actions column with edit and view buttons
      ],
    );
  }

  // Helper method to get the previous row's balance
  double _getPreviousRowBalance(int index) {
    final Bill previousBill = _bills[index];
    final previousDebit = previousBill.billType == "Return Bill" ? previousBill.totalAmount ?? 0.0 : previousBill.amountGiven ?? 0.0;
    final previousCredit = previousBill.billType == "Return Bill" ? previousBill.amountGiven ?? 0.0 : previousBill.totalAmount ?? 0.0;
    double previousBalance = index == 0 ? 0 : _getPreviousRowBalance(index - 1);
    return previousBalance + previousCredit - previousDebit;
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _bills.length;

  @override
  int get selectedRowCount => 0;
}





