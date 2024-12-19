import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../components/bussiness_info_provider.dart';
import '../../../components/export_csv.dart';
import '../../../models/businessInfo.dart';
import '../../../models/vendor.dart';
import '../../../models/vendor_bills.dart';
import '../../../services/vendor_bills.dart';
import '../../../services/vendors.dart';
import '../../Vendor Bills/Vendor Bill Widgets/show_vendor_ bill_items.dart';
import 'debit_discount_bill_dialog.dart';

class VendorLedger extends StatefulWidget {
  final Vendor vendor;

  VendorLedger({
    required this.vendor,
  });

  @override
  _VendorLedgerState createState() => _VendorLedgerState();
}

class _VendorLedgerState extends State<VendorLedger> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _debitController = TextEditingController();
  late List<VendorBill> _bills = [];
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
  int? _sortColumnIndex;
  bool _sortAscending = true;
  double _totalAmountToBePaid = 0.0;
  final VendorBillService _vendorBillService = VendorBillService();
  bool _isLoading = false;
  bool _hasData = false;

  // Variables for date filtering
  DateTime? _startDate;
  DateTime? _endDate;
  double balance = 0;


  @override
  void initState() {
    super.initState();
    _getVendorBalance();
    _fetchBills();
    _calculateTotalAmountToBePaid();

  }

  void _getVendorBalance() async {
    VendorService  vendorService = VendorService();
    double newBalance = await vendorService.getVendorBalance(widget.vendor.id);
    print("balance is ${newBalance}");
    setState(() {
      balance = newBalance;
      print("balance upadted is ${balance}");

    });
  }





  // Filter bills based on the selected date range
  void _filterByDateRange() async{
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
                        onPressed: () {

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


  // Add sorting functionality for the date column
  void _onSort<T>(Comparable<T> Function(VendorBill bill) getField, int columnIndex,
      bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _bills.sort((a, b) {
        final VendorBill first = ascending ? a : b;
        final VendorBill second = ascending ? b : a;
        return Comparable.compare(getField(first), getField(second));
      });
    });
  }

  // Sorting by date logic
  void _sortByDate(int columnIndex, bool ascending) {
    _bills.sort((a, b) {
      DateTime aDate = DateTime.parse(a.date);
      DateTime bDate = DateTime.parse(b.date);

      if (!ascending) {
        final temp = aDate;
        aDate = bDate;
        bDate = temp;
      }

      return aDate.compareTo(bDate);
    });

    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
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


  Color _getRowColor(VendorBill bill) {
    switch (bill.billType) {
      case 'Sale Bill':
        return Color(0xFFE3F2FD); // Light blue for 'Purchase Bill'
      case 'Debit Bill':
        return Color(0xFFE8F5E9); // Light green for 'Debit Bill'
      case 'Return Bill':
        return Color(0xFFFFEBEE); // Light red for 'Return Bill'
      case 'Discount Bill':
        return Color(0xFFFFF3E0); // Light amber for 'Discount Bill'
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
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.black26),
            ),
          ),
          SizedBox(width: 10),
          Text(
            billType,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  // Method to add debit or discount bill and refresh balance and bills
  void debit_credit_dialog_show(bool isDebitBill) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return VendorBillDialog(
          title: isDebitBill ? "Add Debit Bill" : "Add Discount Bill",
          vendor: widget.vendor,
          balance: balance,
          isDebitBill: isDebitBill,
          onBillAdded: () {
            _getVendorBalance();
            _fetchBills(); // Fetch the bills after adding one
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

    final bills = await _vendorBillService.getAllBill();
    final filteredBills =
    bills.where((bill) => bill.vendorId == widget.vendor.id).toList();

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

  void exportToEXCEL(BuildContext context, List<VendorBill> bills) {
    CsvExporter.exportVendorLedger(bills, context); // Call the export utility
  }

  @override
  Widget build(BuildContext context) {
    final businessProvider = Provider.of<BusinessDetailsProvider>(context,listen :true);

    return Dialog(
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text('Vendor Bill Actions'),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      debit_credit_dialog_show(false); // Add Discount Bill
                    },
                    child: Text('Add Discount Bill'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),


                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      debit_credit_dialog_show(true); // Add Debit Bill
                    },
                    child: Text('Add Debit Bill'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    icon: Icon(Icons.refresh, color: Colors.blueAccent.shade200),
                    onPressed: () {
                      _getVendorBalance();
                      _fetchBills(); // Refresh bills
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
                    'VENDOR NAME:',
                    style: TextStyle(
                        fontSize: 24,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    ' ${widget.vendor.name.toUpperCase()}',
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
                    '\$${balance.toStringAsFixed(2)}',
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
                    _buildColorIndicator('Sale Bill', Color(0xFFE3F2FD)),
                    _buildColorIndicator('Debit Bill', Color(0xFFE8F5E9)),
                    _buildColorIndicator('Return Bill', Color(0xFFFFEBEE)),
                    _buildColorIndicator('Discount Bill', Color(0xFFFFF3E0)),
                    _buildColorIndicator('Other Bill Type', Color(0xFFF5F5F5)),
                  ],
                ),
              ),


              Expanded(
                child: SingleChildScrollView(
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
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
                                return Colors.blue.shade100; // Light blue for headers
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
                                    (VendorBill bill) {
                                  _editBill(bill);
                                },
                                    (VendorBill bill) {
                                  _viewBill(bill);
                                },
                                context,
                                widget.vendor,
                                businessProvider.businessDetails),

                            columnSpacing: 10.0,
                            horizontalMargin: 10.0,
                            headingRowHeight: 56.0,
                            dataRowHeight: 40.0,
                            rowsPerPage: _rowsPerPage,
                            onRowsPerPageChanged: (value) {
                              setState(() {
                                _rowsPerPage = value!;
                              });
                            },
                            showCheckboxColumn: false,
                            sortColumnIndex: _sortColumnIndex,
                            sortAscending: _sortAscending,
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
                    'Total Amount to be Paid: ${balance.toStringAsFixed(2)}',
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
            'No bills found for this vendor.',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  void _editBill(VendorBill bill) {
    // Edit bill logic here
  }

  void _viewBill(VendorBill bill) {
    // View bill logic here
  }
}

class _LedgerBillDataSource extends DataTableSource {
  final List<VendorBill> _bills;
  final Color Function(VendorBill) _getRowColor;
  final Function(VendorBill) onEdit; // Callback for edit button
  final Function(VendorBill) onView; // Callback for view button
  final BuildContext context;
  final Vendor vendor;
  final BusinessDetails? businessDetails; // Pass context here

  _LedgerBillDataSource(
      List<VendorBill> bills,
      this._getRowColor,
      this.onEdit,
      this.onView,
      this.context,
      this.vendor,
      this.businessDetails,
      ) : _bills = List.from(bills)
    ..sort((a, b) => DateTime.parse(b.date.isNotEmpty ? b.date : '')
        .compareTo(DateTime.parse(a.date.isNotEmpty ? a.date : '')));
  @override
  DataRow getRow(int index) {
    final VendorBill bill = _bills[index];
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
    final String formattedDate = bill.date.isNotEmpty
        ? dateFormat.format(DateTime.parse(bill.date))
        : 'N/A';

    final String billType = bill.billType ?? "N/A";

    return DataRow.byIndex(
      index: index,
      color: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
        return _getRowColor(bill); // Set row color based on bill type
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
            Tooltip(
              message: 'View Bill Items',
              child: IconButton(
                icon: Icon(Icons.list, color: Colors.green),
                onPressed: () => {
                  if (bill.billType == "Sale Bill" || bill.billType == "Return Bill" )
                    {
                      ShowVendorBillItems.show(context, bill, vendor,businessDetails)
                    }
                  else if (bill.billType == "Discount Bill" || bill.billType == "Debit Bill" )
                    {
                      ShowVendorBillItems.showDebitAndDiscountBill(context, bill, vendor,businessDetails)
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
    final VendorBill previousBill = _bills[index];
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
