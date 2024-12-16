import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:namer_app/screens/Tour/tour_history_view_screen.dart';

import '../../models/bills.dart';
import '../../models/customer.dart';
import '../../models/tour.dart';
import '../../services/bills.dart';
import '../../services/customers.dart';
import '../../services/tour.dart';
import '../Customer Bills/Return Customer Bill/edit_or_add_customer_return_bill.dart';
import '../Customer/Customer Ledger/debit_discount_bill_dialog.dart';


class TourDetailDialog extends StatefulWidget {
  final Tour tour;

  TourDetailDialog({
    required this.tour,
  });

  @override
  _TourDetailDialogState createState() => _TourDetailDialogState();
}

class _TourDetailDialogState extends State<TourDetailDialog> {
  final TextEditingController _searchController = TextEditingController();
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
  int? _sortColumnIndex;
  bool _sortAscending = true;
  bool _isLoading = false;
  bool _hasData = false;

  final CustomerService _customerService = CustomerService();
  List<Customer> _selectedCustomers = [];
  final TextEditingController _dateController = TextEditingController();
  final TourService _tourService = TourService();

  // Move debitBillSaved to the parent widget state
  List<BillStatus> debitBillSaved = [];
  List<BillStatus> discountBillSaved = [];
  List<BillStatus> returnBillSaved = [];
  List<double> _customerBalances = [];

  @override
  void initState() {
    super.initState();
    _setDefaultDate();
    _fetchCustomerDetails(widget.tour.customerIds);
  }

  // Method to handle the balance update in the parent widget
  void _handleBalanceUpdate(int index) async {
    CustomerService customerService = CustomerService();
    double newBalance = await customerService.getCustomerBalance(_selectedCustomers[index].id);

    setState(() {
      _customerBalances[index] = newBalance; // Update balance in the state
    });
  }


  void _setDefaultDate() {
    DateTime pickedDefaultDate = DateTime.now();
    _dateController.text = DateFormat('dd-MM-yyyy').format(pickedDefaultDate);
  }

  Future<void> _fetchCustomerDetails(List<String> customerIds) async {
    List<Customer> customers = [];
    List<double> balances = [];

    setState(() {
      _isLoading = true;
    });
    for (String id in customerIds) {
      try {
        Customer customer = await _customerService.getCustomerById(id);
        customers.add(customer);
        double balance = await _customerService.getCustomerBalance(id);
        balances.add(balance);
      } catch (e) {
        print("Error fetching customer with ID $id: $e");
      }
    }

    setState(() {
      _isLoading = false;
      _hasData = customers.isNotEmpty;
      _selectedCustomers = customers;
      _customerBalances = balances;

      // Initialize the bill state arrays based on customer count
      debitBillSaved = List<BillStatus>.generate(
        customers.length,
            (index) => BillStatus(false, ''), // Initialize with default values
      );

      discountBillSaved = List<BillStatus>.generate(
        customers.length,
            (index) => BillStatus(false, ''), // Initialize with default values
      );

      returnBillSaved = List<BillStatus>.generate(
        customers.length,
            (index) => BillStatus(false, ''), // Initialize with default values
      );
    });
  }

  void _updateBillSavedState(int index, bool isDebitBill) {
    setState(() {
      if (isDebitBill) {
        debitBillSaved[index].isSaved = true;
      } else {
        discountBillSaved[index].isSaved = true;
      }
    });
  }

  void _SaveTour() async {
    // Show a confirmation dialog
    bool? isConfirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Tour Completion"),
          content: Text("Are you sure you have completed your tour inputs? Once added, it cannot be changed."),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Return false on cancel
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Return true on confirm
              },
              child: Text("Confirm"),
            ),
          ],
        );
      },
    );

    // If the user confirmed, proceed to save the tour
    if (isConfirmed == true) {
      List<CustomerTourInfo> customerTourInfoList = [];
      for (int i = 0; i < _selectedCustomers.length; i++) {
        customerTourInfoList.add(
          CustomerTourInfo(
            customerId: _selectedCustomers[i].id,
            customerName: _selectedCustomers[i].name,
            debitBill: debitBillSaved[i].id,
            discountBill: discountBillSaved[i].id,
            returnBill: returnBillSaved[i].id,
          ),
        );
      }

      // Create History object
      History history = History(
        billDetails: customerTourInfoList,
        date: _dateController.text, // Ensure date is correctly parsed
      );

      // Add history to the service
      await _tourService.addHistory(widget.tour.id, history);

      // Navigate back
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text('Tour Details'),
          actions: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TourHistoryDialog(tour:widget.tour,)),
                  );
                },
                child: Text('View Tour History'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
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
                    'TOUR NAME:',
                    style: TextStyle(
                        fontSize: 24,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    ' ${widget.tour.routeName.toUpperCase()}',
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
                    'Route Day: ',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.blueGrey),
                  ),
                  Text(
                    '${widget.tour.dayOfRoute}',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade600),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tour Date',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 6),
                              Container(
                                width: 150,
                                child: TextField(
                                  controller: _dateController,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    //labelText: 'Payment Date',
                                  ),
                                  readOnly: true,
                                  onTap: () async {
                                    DateTime? pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2101),
                                    );

                                    if (pickedDate != null) {
                                      setState(() {
                                        _dateController.text =
                                            DateFormat('dd-MM-yyyy')
                                                .format(pickedDate);
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

              SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: LayoutBuilder(
                    builder: (BuildContext context,
                        BoxConstraints constraints) {
                      return ConstrainedBox(
                        constraints: BoxConstraints(
                            minWidth: constraints.maxWidth),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: PaginatedDataTable(
                            headingRowColor: MaterialStateProperty
                                .resolveWith<Color?>(
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
                                label: Text('Customer Name',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                    textAlign: TextAlign.center),
                              ),
                              DataColumn(
                                label: Text('Customer ID',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                    textAlign: TextAlign.center),
                              ),
                              DataColumn(
                                label: Text('Customer Balance',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                    textAlign: TextAlign.center),
                              ),
                              DataColumn(
                                label: Text('Debit Bill',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                    textAlign: TextAlign.center),
                              ),
                              DataColumn(
                                label: Text('Discount Bill',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                    textAlign: TextAlign.center),
                              ),
                              DataColumn(
                                label: Text('Return Bill',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                    textAlign: TextAlign.center),
                              ),
                            ],
                            source: _TourDataSource(
                              _selectedCustomers,
                              context,
                              debitBillSaved,
                              discountBillSaved,
                              returnBillSaved,
                              _updateBillSavedState,
                              _customerBalances,
                              _handleBalanceUpdate, // Pass the balance update callback


                            ),
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
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {

                      _SaveTour();

                      debitBillSaved.forEach((bill) {
                        print("debit bill saved: isSaved = ${bill.isSaved}, id = ${bill.id}");
                      });

                      returnBillSaved.forEach((bill) {
                        print("return bill saved: isSaved = ${bill.isSaved}, id = ${bill.id}");
                      });

                      discountBillSaved.forEach((bill) {
                        print("discount bill saved: isSaved = ${bill.isSaved}, id = ${bill.id}");
                      });
                      //Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      Colors.blue, // Set the background color
                    ),
                    child: Text('Save Tour'),
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
}

class _TourDataSource extends DataTableSource {
  final List<Customer> customer;
  final BuildContext context;
  final List<BillStatus> debitBillSaved;
  final List<BillStatus> discountBillSaved;
  final List<BillStatus> returnBillSaved;
  final Function(int, bool) updateBillSavedState;
  final List<double> balances;
  final Function(int) onBalanceUpdate; // New callback to notify parent

  _TourDataSource(
      this.customer,
      this.context,
      this.debitBillSaved,
      this.discountBillSaved,
      this.returnBillSaved,
      this.updateBillSavedState,
      this.balances,
      this.onBalanceUpdate, // Initialize the callback
      );

  void updateBalance(int index) {
    // Notify parent widget to handle the balance update
    onBalanceUpdate(index);
  }

  void debit_credit_dialog_show(bool isDebitBill, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BillDialog(
          title: isDebitBill ? "Add Debit Bill" : "Add Discount Bill",
          customer: customer[index],
          isDebitBill: isDebitBill,
          balance: balances[index],
          onBillAdded: () {
            // Update the respective bill saved status
            if (isDebitBill) {
              updateBillSavedState(index, true);
            } else {
              updateBillSavedState(index, false);
            }
            notifyListeners(); // Refresh DataTable rows

            // Notify parent to update the balance
            updateBalance(index);
          },
          onBillSavedReturnBillId: (value) {
            if (isDebitBill) {
              debitBillSaved[index].id = value;
            } else {
              discountBillSaved[index].id = value;
            }

            // Notify parent to update the balance after bill is saved
            updateBalance(index);
          },
        );
      },
    );
  }


  void _showAddEditReturnBillDialog(int index, [Bill? bill]) {
    showDialog(
      context: context,
      builder: (context) => AddEditReturnBillDialog(
        bill: bill,
        onBillSaved: () {
          returnBillSaved[index].isSaved = true; // Mark return bill as saved

          // Notify the parent widget to update the balance
          updateBalance(index); // This now calls the onBalanceUpdate callback
          notifyListeners(); // Refresh the UI
        },
        onBillSavedReturnBillId: (value) {
          returnBillSaved[index].id = value; // Mark return bill as saved

          // Optionally log or handle the returned bill ID
          print("Bill ID is $value");

          // Notify the parent widget to update the balance after the bill is saved
          updateBalance(index); // Notify parent to refresh balance
        },
      ),
    );
  }


  @override
  DataRow getRow(int index) {
    final String customerName = customer[index].name ?? "N/A";
    final String customerId = customer[index].id ?? "N/A";
    final double customerBalance = balances[index];

    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text((index + 1).toString())), // No.
        DataCell(Text(customerName)), // Customer Name
        DataCell(Text(customerId)), // Customer ID
        DataCell(Text('${customerBalance.toString()} PKR')), // Customer Balance

        // Debit Bill
        DataCell(
          !debitBillSaved[index].isSaved
              ? ElevatedButton(
            onPressed: () {
              debit_credit_dialog_show(true, index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade300,
            ),
            child: Text('Debit Bill +'),
          )
              : Row(
            children: [
              Icon(
                Icons.check,
                color: Colors.green,
              ),
              SizedBox(width: 8),
              Text("Added", style: TextStyle(fontSize: 16)),
            ],
          ),
        ),

        // Discount Bill
        DataCell(
          !discountBillSaved[index].isSaved
              ? ElevatedButton(
            onPressed: () {
              debit_credit_dialog_show(false, index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade300,
            ),
            child: Text('Discount Bill +'),
          )
              : Row(
            children: [
              Icon(
                Icons.check,
                color: Colors.amber.shade300,
              ),
              SizedBox(width: 8),
              Text("Added", style: TextStyle(fontSize: 16)),
            ],
          ),
        ),

        // Return Bill
        DataCell(
          !returnBillSaved[index].isSaved
              ? ElevatedButton(
            onPressed: () {
              _showAddEditReturnBillDialog(index); // Your return bill logic
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade300,
            ),
            child: Text('Return Bill +'),
          )
              : Row(
            children: [
              Icon(
                Icons.check,
                color: Colors.red.shade300,
              ),
              SizedBox(width: 8),
              Text("Added", style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => customer.length;

  @override
  int get selectedRowCount => 0;
}


class BillStatus {
  bool isSaved;
  String id;

  BillStatus(this.isSaved, this.id);
}