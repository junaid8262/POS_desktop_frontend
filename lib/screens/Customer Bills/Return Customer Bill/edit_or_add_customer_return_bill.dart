import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:namer_app/models/bills.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:namer_app/models/customer.dart';
import 'package:namer_app/models/item.dart';
import 'package:namer_app/screens/Customer%20Bills/Return%20Customer%20Bill/previous_customer_bill_selectable_dialouge.dart';
import 'package:namer_app/services/bills.dart';
import 'package:namer_app/theme/theme.dart';
import 'package:namer_app/components/input_field.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

import '../../../components/bussiness_info_provider.dart';
import '../../../models/businessInfo.dart';
import '../../../models/vendor_bills.dart';
import '../../../services/vendor_bills.dart';
import '../../Shared Bill Widgets/item_selection_dialog.dart';
import '../../Shared Bill Widgets/selected_item_previous_details.dart';
import '../Bill Widgets/print_bill_pdf.dart';

class AddEditReturnBillDialog extends StatefulWidget {
  final Bill? bill;
  final VoidCallback onBillSaved;
  final Function(String billId)? onBillSavedReturnBillId; // Updated callback function


  const AddEditReturnBillDialog({Key? key, this.bill, this.onBillSavedReturnBillId,required this.onBillSaved}) : super(key: key);

  @override
  _AddEditReturnBillDialogState createState() => _AddEditReturnBillDialogState();
}

class _AddEditReturnBillDialogState extends State<AddEditReturnBillDialog> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _subtotalAmountController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  final TextEditingController _creditController = TextEditingController();
  final TextEditingController _customerAddressController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _paymentPromisedDateController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final BillService _billService = BillService();
  final VendorBillService _billServiceVendor = VendorBillService();

  bool _isLoading = false;

  Map<String, TextEditingController> _quantityControllers = {};
  Map<String, TextEditingController> _discountControllers = {};
  Map<String, TextEditingController> _saleRateControllers = {};



  List<Customer> _customers = [];
  List<Item> _items = [];
  List<Bill> _previousBills = [];
  Map<String, List<BillItem>> _itemPreviousRates = {};
  String? _selectedCustomerId;
  Customer? _selectedCustomer;
  List<BillItem> _selectedItems = [];
  String _selectedStatus = 'Completed';
  double _totalAmount = 0;
  double _discount = 0;
  double _subtotal = 0;
  String? _role;
  double newBalance = 0;
  int _selectedIndex = -1;
  Map<String, List<VendorBillItem>> _itemPreviousPurchaseRates = {};


  @override
  void initState() {

    super.initState();

    if (widget.bill != null) {
      print("customer id init state: ${widget.bill?.customerId}");

      _selectedCustomerId = widget.bill!.customerId;
      DateTime date = DateTime.parse(widget.bill!.date);
      _dateController.text = DateFormat('dd-MM-yyyy').format(date);

      DateTime promiseDate = DateTime.parse(widget.bill!.paymentPromiseDate);
      _paymentPromisedDateController.text = DateFormat('dd-MM-yyyy').format(promiseDate);

      _selectedItems = widget.bill!.items.map((item) {
        // Initialize the controllers for each item
        _quantityControllers[item.itemId] = TextEditingController(text: item.quantity.toString());
        _discountControllers[item.itemId] = TextEditingController(text: item.itemDiscount.toStringAsFixed(2)); // Initialize with 0.00 or fetch it if applicable
        _saleRateControllers[item.itemId] = TextEditingController(text: item.saleRate.toStringAsFixed(2));

        return BillItem(
            itemId: item.itemId,
            name: item.name,
            quantity: item.quantity,
            saleRate: item.saleRate,
            purchaseRate: item.purchaseRate,
            total: item.total,
            itemDiscount: item.itemDiscount,
            miniUnit: item.miniUnit 
        );
      }).toList();
      _creditController.text = widget.bill!.amountGiven.toString();
      _totalAmountController.text = widget.bill!.totalAmount.toString();
      _selectedStatus = widget.bill!.status;
      _discountController.text = widget.bill!.discount.toString();
      _descriptionController.text = widget.bill!.description.toString();
      _calculateTotalAmount();
      _fetchCustomerDetails();
      for (var item in _selectedItems) {
        _fetchItemPreviousRates(item.itemId);
        _fetchItemPreviousPurchaseRates(item.itemId);
      }
    } else {
      _discountController.text = '0.00';
      _setDefaultDate();
      _setDefaultPromisedDate();
      _creditController.text = '0.00';
    }

    _fetchRole();
    _fetchItems();
    _fetchCustomers();
  }

  void _setDefaultDate() {
    DateTime pickedDefaultDate = DateTime.now();
    _dateController.text = DateFormat('dd-MM-yyyy').format(pickedDefaultDate);
  }

  void _setDefaultPromisedDate() {
    DateTime pickedDefaultDate = DateTime.now();
    _paymentPromisedDateController.text = DateFormat('dd-MM-yyyy').format(pickedDefaultDate);
  }

  Future<void> _fetchRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = prefs.getString('role');
    });
  }

  Future<void> _fetchCustomers() async {
    final customers = await _billService.getCustomers();
    setState(() {
      _customers = customers;
    });
  }

  Future<void> _fetchItems() async {
    final items = await _billService.getItems();
    setState(() {
      _items = items;
    });
  }

  Future<void> _fetchCustomerDetails() async {
    if (_selectedCustomerId != null) {
      final customer = await _billService.getCustomerById(_selectedCustomerId!);
      final allBills = await _billService.getBillsByCustomerId(_selectedCustomerId!);

      // Filter bills with status = 'Completed' and billType = 'Sale Bill'
      final filteredBills = allBills.where((bill) =>
      bill.status == 'Completed' && bill.billType == 'Sale Bill').toList();

      setState(() {
        _selectedCustomer = customer;
        _previousBills = filteredBills.take(5).toList(); // Get only the recent 5 filtered bills
        _customerNameController.text = customer.name.toString();
        _balanceController.text = customer.balance.toString();
        _customerAddressController.text = customer.address.toString();
        _customerPhoneController.text = customer.phoneNumber.toString();
      });
    }
  }


  Future<void> _fetchItemPreviousRates(String itemId) async {
    final itemRates = await _billService.getItemRatesById(itemId);
    setState(() {
      _itemPreviousRates[itemId] = itemRates;
    });
  }

  Future<void> _fetchItemPreviousPurchaseRates(String itemId) async {
    // Fetch item rates by vendor from the new method in VendorBillService
    final itemRates = await _billServiceVendor.getItemRatesByVendorId(itemId);

    // Update the state to store the previous purchase rates
    setState(() {
      _itemPreviousPurchaseRates[itemId] = itemRates;
    });
  }

  void _addItemToBill(Item item, double discount) async {
    await _fetchItemPreviousPurchaseRates(item.id);
    setState(() {
      if (!_quantityControllers.containsKey(item.id)) {
        _quantityControllers[item.id] = TextEditingController(text: item.availableQuantity.toString());
      }


      BillItem? existingItem;
      for (var selectedItem in _selectedItems) {
        if (selectedItem.itemId == item.id) {
          existingItem = selectedItem;
          break;
        }
      }

      if (existingItem != null) {
        existingItem.quantity++;
        existingItem.total = existingItem.purchaseRate * existingItem.quantity;
        _quantityControllers[item.id]!.text = existingItem.quantity.toString();
      } else {
        // Set the initial quantity to the purchased quantity
        int initialQuantity = item.availableQuantity; // or use the quantity from the previous bill if applicable
        _selectedItems.add(BillItem(
          itemId: item.id,
          name: item.name,
          quantity: initialQuantity, // Start with the purchased quantity
          purchaseRate: item.purchaseRate,
          total: item.purchaseRate * initialQuantity, // Total for the initial quantity
          miniUnit: item.miniUnit,
          item: item, saleRate: item.saleRate, itemDiscount: discount, // Store the item reference
        ));
        _quantityControllers[item.id]!.text = initialQuantity.toString(); // Set the controller to the initial quantity
      }

      _calculateTotalAmount();
    });
  }

  void _updateItemQuantity(BillItem billItem, int quantity) {
    setState(() {
      // Check if the quantity is less than or equal to the available quantity of the associated Item
      if (quantity > (billItem.item?.availableQuantity ?? 0)) {
        // Show an error message or handle the error as needed
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot return more than available quantity: ${billItem.item?.availableQuantity}'))
        );
        return; // Exit the method if the quantity is invalid
      }

      billItem.quantity = quantity;
      billItem.total = billItem.purchaseRate * quantity;

      // Recalculate the total amount
      _calculateTotalAmount();
    });
  }
  
  void _removeItemFromBill(BillItem item) {
    setState(() {
      _selectedItems.remove(item);
      _calculateTotalAmount();
    });
  }
  void _showAlertDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Warning'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
  // todo handle update item quantity alert
  // void _updateItemQuantity(BillItem item, int quantity) {
  //   if (quantity <= _items.firstWhere((i) => i.id == item.itemId).availableQuantity) {
  //     setState(() {
  //       item.quantity = quantity;
  //       item.total = item.saleRate * quantity;
  //       _calculateTotalAmount();
  //     });
  //   } else {
  //     // Show an alert dialog if the quantity exceeds available stock
  //     _showAlertDialog('Quantity exceeds available stock');
  //   }
  // }

  void _updateItemRateForBill(BillItem item, double saleRate) {
    setState(() {
      item.saleRate = saleRate;
      item.total = item.saleRate * item.quantity;
      _calculateTotalAmount();
    });
  }

  void _calculateTotalAmount() {
    double total = 0;
    for (var item in _selectedItems) {
      total += item.total;
    }
    setState(() {
      _subtotal = total;
      _subtotalAmountController.text = _subtotal.toStringAsFixed(2);
      _totalAmount = _subtotal-_discount;
      _totalAmountController.text = _totalAmount.toStringAsFixed(2);
      if (_balanceController.text.isNotEmpty)
      {
        newBalance = double.parse(_balanceController.text) + _totalAmount;
      }
    });
  }

  Future<void> _handleSave({bool printBill = false , BusinessDetails? bussinessDetails}) async {

    setState(() {
      _isLoading = true;
    });

    try {
      final date = _dateController.text;
      final paymentPromisedDate = _paymentPromisedDateController.text;
      double creditAmount = double.parse(_creditController.text); // Parse credit amount

      // Debug prints to check variable values
      print("Selected Customer ID: $_selectedCustomerId");
      print("Selected Items: ${_selectedItems}");
      print("Selected Status: $_selectedStatus");

      // Check for null values before proceeding
      if (_selectedCustomerId == null) {
        print('Error: Selected Customer ID is null');
        return; // Exit if customer ID is null
      }

      if (_selectedItems.isEmpty) {
        print('Error: Selected Items are empty');
        return; // Exit if items are empty
      }

      if (_selectedStatus == null) {
        print('Error: Selected Status is null');
        return; // Exit if status is null
      }

    // Check if the status is "Non Completed", set item sale rates, total bill, and discount to zero
    if (_selectedStatus == 'Non Completed') {
      for (var item in _selectedItems) {
        item.saleRate = 0; // Set sale rate to 0 for all items
        item.total = 0; // Set total to 0 for all items
      }
      _totalAmount = 0;  // Set total amount to 0
      _discount = 0;
      _creditController.text = '0.0'; // Set credit to 0
      creditAmount = 0.0; // Set creditAmount to 0 for non-completed
    }
    Bill newBill;

    if (widget.bill == null) {

      newBill = Bill(
        id: '',
        customerId: _selectedCustomerId!,
        date: date,
        items: _selectedItems,
        totalAmount: _totalAmount,
        discount: _discount,
        status: _selectedStatus,
        paymentPromiseDate: paymentPromisedDate,
        amountGiven: creditAmount,
        billType: "Return Bill",
        description: _descriptionController.text,
      );


      // New bill creation
      String returnBillId = await _billService.addBill(newBill);
      if (widget.onBillSavedReturnBillId != null) {
        widget.onBillSavedReturnBillId!(returnBillId);
      }

      // Reduce the items from inventory only if status is not 'Non Completed'
      if (_selectedStatus != 'Non Completed') {
        _billService.increaseBillItemsQuantity(_selectedItems);
        _updateCustomerBalanceForNewBillReversed();

      }


    } else {
      newBill = Bill(
        id: widget.bill!.id,
        customerId: _selectedCustomerId!,
        date: date,
        items: _selectedItems,
        totalAmount: _totalAmount,
        discount: _discount,
        status: _selectedStatus,
        paymentPromiseDate: paymentPromisedDate,
        amountGiven: creditAmount,
        billType: "Return Bill",
        description: _descriptionController.text,
      );

      // Updating an existing bill
      await _billService.updateBill(widget.bill!.id, newBill);
      if (widget.onBillSavedReturnBillId != null) {
        widget.onBillSavedReturnBillId!(widget.bill!.id);
      }
      // Handle balance update when status is 'Non Completed' and widget.bill != null
      _updateCustomerBalanceForExistingBillReversed();
    }

    setState(() {
      _isLoading = false;
    });


    widget.onBillSaved();

    if (printBill) {
      // Fetch customer details before printing the bill
      final customer = await _billService.getCustomerById(_selectedCustomerId!);
      // Generate and view the PDF
      BillPdfGenerator.generatePdfAndView(newBill, customer, newBill.billType,context,bussinessDetails!);
    }

    Navigator.pop(context);
    } catch (e) {
      print("An error occurred: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to update customer balance for a new bill (Reversed logic)
  Future<void> _updateCustomerBalanceForNewBillReversed() async {
    final newBalance = _selectedCustomer!.balance - _totalAmount;
    await _billService.updateCustomerBalance(_selectedCustomerId!, newBalance);
    print('Customer balance updated for ID: $_selectedCustomerId with new bill. Balance subtracted. New balance: $newBalance');
  }

// Function to update customer balance for an existing bill (Reversed logic)
  Future<void> _updateCustomerBalanceForExistingBillReversed() async {
    // Scenario for completed bill
    compare_updateItemListsFromDB(widget.bill!.items, _selectedItems);

    // Variables for previous and current values
    final previousTotal = widget.bill!.totalAmount;
    final totalDifference = previousTotal - _totalAmount;

    print('Previous Total: $previousTotal');
    print('Total Difference: $totalDifference');

    // Subtract the total difference from the balance
    final newBalance = _selectedCustomer!.balance + totalDifference;
    await _billService.updateCustomerBalance(_selectedCustomerId!, newBalance);

    print('Customer balance updated for ID: $_selectedCustomerId with reversed changes. New balance: $newBalance');

    if (_totalAmount == previousTotal) {
      print('No balance update needed as the total amount is unchanged.');
    }
  }

  void compareBills(Bill oldBill, Bill newBill) {
    // Compare basic attributes of the Bill
    if (oldBill.id != newBill.id) {
      print('Bill IDs are different.');
    }
    if (oldBill.customerId != newBill.customerId) {
      print('Customer IDs are different.');
    }
    if (oldBill.totalAmount != newBill.totalAmount) {
      print('Total amounts are different: old = ${oldBill.totalAmount}, new = ${newBill.totalAmount}');
    }
    if (oldBill.discount != newBill.discount) {
      print('Discounts are different: old = ${oldBill.discount}, new = ${newBill.discount}');
    }
    if (oldBill.paymentPromiseDate != newBill.paymentPromiseDate) {
      print('Payment promise dates are different.');
    }
    if (oldBill.status != newBill.status) {
      print('Statuses are different: old = ${oldBill.status}, new = ${newBill.status}');
    }
    if (oldBill.date != newBill.date) {
      print('Dates are different: old = ${oldBill.date}, new = ${newBill.date}');
    }

    // Compare the BillItem lists
    compare_updateItemListsFromDB(oldBill.items, newBill.items);
  }

  void compare_updateItemListsFromDB(List<BillItem> oldList, List<BillItem> newList) {
    Map<String, BillItem> oldItemMap = {for (var item in oldList) item.itemId: item};
    Map<String, BillItem> newItemMap = {for (var item in newList) item.itemId: item};

    for (var item in oldList) {
      if (!newItemMap.containsKey(item.itemId)) {
        _billService.updateItemQuantity(item.itemId, item.quantity, increase: false);
      } else {
        BillItem newItem = newItemMap[item.itemId]!;
        if (newItem.quantity != item.quantity) {
          final quantityDifference = newItem.quantity - item.quantity;
          final shouldIncrease = quantityDifference > 0;

          _billService.updateItemQuantity(
            item.itemId,
            quantityDifference.abs(),
            increase: shouldIncrease,
          );
        }
      }
    }

    for (var item in newList) {
      if (!oldItemMap.containsKey(item.itemId)) {
        _billService.updateItemQuantity(item.itemId, item.quantity, increase: true);
      }
    }

    bool listsAreIdentical = true;
    if (oldItemMap.length != newItemMap.length) {
      listsAreIdentical = false;
    } else {
      for (var item in oldList) {
        if (!newItemMap.containsKey(item.itemId) ||
            newItemMap[item.itemId]!.quantity != item.quantity ||
            newItemMap[item.itemId]!.purchaseRate != item.purchaseRate ||
            newItemMap[item.itemId]!.total != item.total) {
          listsAreIdentical = false;
          break;
        }
      }
    }

    if (listsAreIdentical) {
      print('Both item lists and their attributes are identical.');
    } else {
      print('The item lists have differences.');
    }
  }


  String _calculateProfit() {
    double totalAmount = double.tryParse(_totalAmountController.text) ?? 0.0;
    double totalPurchasePrice = _calculateTotalPurchasePrice(); // Assuming you have this method to calculate total purchase price.
    double profit = totalAmount - totalPurchasePrice;

    return '${NumberFormat.currency(symbol: '₨ ', decimalDigits: 2).format(profit)}';
  }

  double _calculateTotalPurchasePrice() {
    // Assuming you have a list of items, each with a purchase price and quantity
    double totalPurchasePrice = 0.0;
    for (var item in _selectedItems) {
      totalPurchasePrice += item.purchaseRate * item.quantity;
    }
    return totalPurchasePrice;
  }

  Color _getProfitColor() {
    double totalAmount = double.tryParse(_totalAmountController.text) ?? 0.0;
    double totalPurchasePrice = _calculateTotalPurchasePrice();
    double profit = totalAmount - totalPurchasePrice;

    return profit >= 0 ? Colors.green : Colors.red; // Green for profit, red for loss
  }

  Future<void> _generatePdfAndView() async {
    final pdf = pw.Document();

    // Add content to the PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Invoice Header with company information
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('IMRAN AUTOS',
                          style: pw.TextStyle(
                              fontSize: 28,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.red)),
                      pw.SizedBox(height: 5),
                      pw.Text(
                          'Shop Address: Add here for easy location identification',
                          style: pw.TextStyle(fontSize: 12)),
                      pw.Text('Mobile: 0311-1234567',
                          style: pw.TextStyle(fontSize: 12)),
                    ],
                  ),

                ],
              ),
              pw.SizedBox(height: 20),

              // Invoice Details Section
              pw.Text('Invoice Details',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 15), // Adjust padding for more vertical spacing
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start, // Align all content to the left for consistency
                  children: [
                    // First row: Customer Name and Customer Phone
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Customer Name:', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                            pw.SizedBox(height: 3), // Minimal space between label and value
                            pw.Text('${_customerNameController.text}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Customer Phone:', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                            pw.SizedBox(height: 3),
                            pw.Text('${_customerPhoneController.text}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),

                    // Add spacing between rows
                    pw.SizedBox(height: 10),

                    // Second row: Customer Address and Sales Date
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Customer Address:', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                            pw.SizedBox(height: 3),
                            pw.Text('${_customerAddressController.text}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Sales Date:', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                            pw.SizedBox(height: 3),
                            pw.Text('10-09-2024', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),


              pw.SizedBox(height: 20),

              // Items Table
              pw.Text('Items',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: [
                  '#',
                  'Product Name',
                  'Qty',
                  'Sale Price',
                  'Total'
                ],
                data: _selectedItems.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final item = entry.value;
                  final total = (item.saleRate * item.quantity)
                      .toStringAsFixed(2);
                  return [
                    index.toString(),
                    item.name,
                    item.quantity.toString(),
                    item.saleRate.toStringAsFixed(2),
                    total,
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                    color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColors.lightBlue,
                ),
                cellStyle: pw.TextStyle(fontSize: 12),
                cellHeight: 25,
                columnWidths: {
                  0: pw.FlexColumnWidth(0.5),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FlexColumnWidth(1),
                  3: pw.FlexColumnWidth(1.5),
                  4: pw.FlexColumnWidth(1.5),
                },
                border: pw.TableBorder.all(color: PdfColors.grey),
              ),
              pw.SizedBox(height: 20),

              // Totals Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Sub Total: Rs ${_subtotalAmountController.text}',
                          style: pw.TextStyle(fontSize: 16)),
                      pw.Text('Discount: Rs ${_discountController.text}',
                          style: pw.TextStyle(fontSize: 16)),
                      pw.Text('Total: Rs ${_totalAmountController.text}',
                          style: pw.TextStyle(
                              fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                          '${numberToWords(double.tryParse(_totalAmountController.text)?.toInt() ?? 0)} Rupees Only',
                          style: pw.TextStyle(
                              fontSize: 14, color: PdfColors.grey600)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Optional Footer for signature or terms
              pw.Text('Thank you for your business!',
                  style: pw.TextStyle(fontSize: 14, fontStyle: pw.FontStyle.italic)),
              pw.SizedBox(height: 10),
              pw.Text('Signature: ____________________',
                  style: pw.TextStyle(fontSize: 14)),
            ],
          );
        },
      ),
    );

    // Save the PDF document
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/bill_invoice.pdf');
    await file.writeAsBytes(await pdf.save());

    // Open the PDF document in the viewer
    OpenFile.open(file.path);
  }

  void _showCustomerBillItems(Bill bill) {
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
            color: Colors.redAccent,
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
                    colors: [Colors.redAccent, Colors.lightBlueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.2),
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


  String numberToWords(int number) {
    if (number == 0) return 'Zero';

    final units = ['One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine'];
    final teens = ['Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'];
    final tens = ['Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];
    final thousands = ['Thousand'];

    String words = '';

    if (number >= 1000) {
      int thousandPart = number ~/ 1000;
      words += '${numberToWords(thousandPart)} ${thousands[0]} ';
      number %= 1000;
    }

    if (number >= 100) {
      words += '${units[(number ~/ 100) - 1]} Hundred ';
      number %= 100;
    }

    if (number >= 20) {
      words += '${tens[(number ~/ 10) - 2]} ';
      number %= 10;
    } else if (number >= 11) {
      words += '${teens[number - 11]} ';
      number = 0;
    } else if (number == 10) {
      words += 'Ten ';
      number = 0;
    }

    if (number > 0) {
      words += '${units[number - 1]} ';
    }

    return words.trim();
  }


  void _onItemsReturned(List<Map<String, dynamic>> selectedItems) {
    print('Items returned: ${selectedItems.length}');
    for (var itemMap in selectedItems) {
      Item item = itemMap['item'] as Item;
      double discount = itemMap['discount'] as double;
      _addItemToBill(item,discount);
      print('Item: ${item.name}, Quantity: ${item.availableQuantity}, Sale Rate: \$${item.saleRate}, discount Value: \$${discount}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessProvider = Provider.of<BusinessDetailsProvider>(context,listen :true);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      backgroundColor: Colors.white, // Set the background color to white
      child: Container(
        padding: EdgeInsets.all(16),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.red,
                ),
                alignment: Alignment.center,
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align items with space between
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed:() => Navigator.of(context).pop(),
                    ),
                    Text(
                      widget.bill == null ? 'Add Return Bill' : 'Edit Return Bill',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 48), // Empty SizedBox to balance the space
                  ],
                ),
              ),
              SizedBox(height: 16),
              //name and input  fields
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'RETURN BILL INVOICE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment : MainAxisAlignment.start,
                        children: [
                          businessProvider.businessDetails!.companyLogo.isEmpty ? SizedBox(
                            width: 100,
                            height: 70,
                            child: Image.asset('assets/placeholder.jpg'),
                          ):
                          SizedBox(
                            width: 100,
                            height: 70,
                            child: Image.network('${dotenv.env['BACKEND_URL']!}${businessProvider.businessDetails!.companyLogo}'),
                          ),
                          Text(
                            businessProvider.businessDetails!.companyName,
                            style: TextStyle(
                              fontSize: 26,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                    ],
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left :16),
                    child: Text(
                      businessProvider.businessDetails!.companyAddress,
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left :16),
                    child: Text(
                      businessProvider.businessDetails!.companyPhoneNo,
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Text(
                    'Invoice Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 20),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment
                              .start,
                          children: [
                            Text(
                              'Customer Name',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 6),
                            TypeAheadFormField<Customer>(
                              textFieldConfiguration: TextFieldConfiguration(
                                controller: _customerNameController,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Customer',

                                ),

                                onTap: () {
                                  // Show the suggestions when the user taps on the field
                                  _customerNameController.selection = TextSelection(
                                    baseOffset: 0,
                                    extentOffset: _customerNameController.text.length,
                                  );
                                },
                              ),
                              suggestionsCallback: (pattern) {
                                return _customers.where((customer) =>
                                customer.name.toLowerCase().contains(pattern.toLowerCase()) ||
                                    customer.id.contains(pattern)); // Limit to 5 suggestions
                              },
                              itemBuilder: (context, Customer suggestion) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12.0),
                                    gradient: LinearGradient(
                                      colors: [Colors.white, Colors.grey[100]!],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.2),
                                        blurRadius: 4.0,
                                        offset: Offset(0, 2), // Subtle shadow effect
                                      ),
                                    ],
                                    border: Border.all(color: Colors.grey[300]!), // Thin border
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blueGrey[100],
                                      // Soft background color
                                      child: Icon(Icons.person_add_outlined, color: Colors.redAccent),
                                    ),
                                    title: Text(
                                      suggestion.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                        color: Colors.blueGrey[900], // Modern color for the text
                                      ),
                                    ),
                                    subtitle: Text(
                                      "ID: ${suggestion.id}",
                                      style: TextStyle(
                                        color: Colors.blueGrey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              onSuggestionSelected: (Customer suggestion) {
                                setState(() {
                                  _selectedCustomerId = suggestion.id;
                                  _selectedCustomer = suggestion;
                                  _customerNameController.text = suggestion.name;
                                  _customerAddressController.text = suggestion.address.toString();
                                  _customerPhoneController.text = suggestion.phoneNumber.toString();
                                });

                                // Call fetch after the state has been updated
                                _fetchCustomerDetails();
                              },
                              noItemsFoundBuilder: (context) => Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('No customers found.'),
                              ),
                              suggestionsBoxDecoration: SuggestionsBoxDecoration(
                                constraints: BoxConstraints(
                                  maxHeight: 225, // Control the height of the suggestions box
                                ),
                              ),
                            ),

                            SizedBox(height: 16),
                            Text(
                              'Customer Address',

                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 6),
                            CustomTextField(
                              readOnly : true,

                              controller: _customerAddressController,
                              label: 'Address',
                              onChanged: (value) {
                                setState(() {
                                  _customerAddressController.text = value;

                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment
                              .start,
                          children: [
                            Text(
                              'Customer Phone',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 6),
                            CustomTextField(
                              controller: _customerPhoneController,
                              readOnly : true,
                              label: 'Phone No',
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')), // Custom formatter for decimals
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _customerPhoneController.text = value;

                                });
                              },
                            ),
                            SizedBox(height: 16),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children : [

                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [
                                    Text(
                                      'Sales Date',
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
                                          //labelText: 'Date',
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

                                /*Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                    Text(
                                                      'Promised Date',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                    SizedBox(height: 6),
                                                    Container(
                                                      width: 150 ,
                                                      child: TextField(
                                                        controller: _paymentPromisedDateController,
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
                                                              _paymentPromisedDateController.text =
                                                                  DateFormat('dd-MM-yyyy')
                                                                      .format(pickedDate);
                                                            });
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                ],
                                              ),*/
                                SizedBox(width:25),

                              ],
                            ),



                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 24),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 50,
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.black26),
                          color: Colors.grey[100]
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            //table
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Return Bill Items',
                                  style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold),
                                ),

                              ],
                            ),
                            SizedBox(height: 16),
                            Table(
                              border: TableBorder.all(width: 1, color: Colors.grey),
                              columnWidths: {
                                0: FixedColumnWidth(40),
                                1: FlexColumnWidth(),
                                2: FixedColumnWidth(80),
                                3: FixedColumnWidth(70),
                                4: FixedColumnWidth(70),
                                5: FixedColumnWidth(80),
                                6: FixedColumnWidth(80),
                                7: FixedColumnWidth(90),
                                8: FixedColumnWidth(50),
                              },
                              children: [
                                TableRow(
                                  decoration: BoxDecoration(
                                    color: Colors.red[100],
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('#', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('Product Name',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),

                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Center(
                                          child: Text('Purchase', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Center(
                                          child: Text('Disc %', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Center(
                                          child: Text('Sale', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Center(
                                          child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                                    ),
                                  ],
                                ),
                                for (int i = 0; i < _selectedItems.length; i++)
                                  TableRow(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(4, 15, 4, 0),
                                        child: Center(child: Text((i + 1).toString())),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(0),
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _selectedIndex = i;
                                            });
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: _selectedIndex == i ? Colors.red.shade100 : Colors.transparent,
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(20.0),
                                              child: Text(
                                                _selectedItems[i].name,
                                                style: TextStyle(
                                                  color: _selectedIndex == i ? Colors.black : Colors.black,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(3.0),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                keyboardType: TextInputType.number,
                                                decoration: InputDecoration(
                                                  border: OutlineInputBorder(),
                                                  contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                                                ),
                                                controller: _quantityControllers[_selectedItems[i].itemId],

                                                onChanged: (value) {
                                                  final quantity = int.tryParse(value) ?? 0;
                                                  setState(() {
                                                    if (quantity <= _selectedItems[i].item!.availableQuantity) {
                                                      _selectedItems[i].quantity = quantity;
                                                      _updateItemQuantity(_selectedItems[i], quantity); // Update only the quantity
                                                    } else {
                                                      // If the quantity exceeds the availableQuantity, reset it to the availableQuantity
                                                      _selectedItems[i].quantity = _selectedItems[i].item!.availableQuantity;
                                                      _quantityControllers[_selectedItems[i].itemId]?.text = _selectedItems[i].quantity.toString(); // Update controller
                                                      _updateItemQuantity(_selectedItems[i], _selectedItems[i].quantity); // Update quantity
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(content: Text('Quantity cannot exceed available stock!')),
                                                      );
                                                    }
                                                  });
                                                },
                                              ),
                                            ),
                                            Container(
                                              height: 28,
                                              child: Column(
                                                children: [
                                                  SizedBox(
                                                    height: 14,
                                                    width: 14,
                                                    child: IconButton(
                                                      icon: Icon(Icons.arrow_drop_up),
                                                      padding: EdgeInsets.zero,
                                                      iconSize: 18,
                                                      onPressed: () {
                                                        setState(() {
                                                          if (_selectedItems[i].quantity < _selectedItems[i].item!.availableQuantity) {
                                                            _selectedItems[i].quantity++;
                                                            _quantityControllers[_selectedItems[i].itemId]?.text = _selectedItems[i].quantity.toString(); // Update controller
                                                            _updateItemQuantity(_selectedItems[i], _selectedItems[i].quantity); // Update only quantity
                                                          } else {
                                                            // Show a message if the user tries to increment past available stock
                                                            _showAlertDialog('Cannot exceed purchased Quantity!');
                                                          }
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: 14,
                                                    width: 14,
                                                    child: IconButton(
                                                      icon: Icon(Icons.arrow_drop_down),
                                                      padding: EdgeInsets.zero,
                                                      iconSize: 18,
                                                      onPressed: () {
                                                        setState(() {
                                                          if (_selectedItems[i]
                                                              .quantity > 0) {
                                                            _selectedItems[i]
                                                                .quantity--;
                                                            _quantityControllers[_selectedItems[i]
                                                                .itemId]?.text =
                                                                _selectedItems[i]
                                                                    .quantity
                                                                    .toString(); // Update controller
                                                            _updateItemQuantity(
                                                                _selectedItems[i],
                                                                _selectedItems[i]
                                                                    .quantity); // Update only quantity
                                                          }
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(2, 15, 2, 0),
                                          child: Text(
                                            _selectedItems[i].miniUnit.toString(),
                                            style: TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ),
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(2, 15, 2, 0),
                                          child: Text(
                                            _selectedItems[i].purchaseRate.toString(),
                                            style: TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: TextField(
                                          controller: _selectedStatus == 'Non Completed' ? TextEditingController(text :"0.00"): _discountControllers[_selectedItems[i].itemId],
                                          readOnly: _selectedStatus == 'Non Completed',
                                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                                          ),
                                          onChanged: (value) {
                                            final discountPercent = double.tryParse(value) ?? 0.0;
                                            setState(() {
                                              final originalRate = _selectedItems[i].purchaseRate;
                                              double newSaleRate;

                                              if (discountPercent > 0) {
                                                final discountAmount = originalRate * discountPercent / 100;
                                                newSaleRate = originalRate - discountAmount;
                                              } else {
                                                newSaleRate = originalRate;
                                              }
                                              _selectedItems[i].saleRate = newSaleRate;
                                              _selectedItems[i].itemDiscount = discountPercent;
                                              _updateItemRateForBill(_selectedItems[i], _selectedItems[i].saleRate);
                                              _saleRateControllers[_selectedItems[i].itemId]!.text = newSaleRate.toString();
                                            });
                                          },
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: StatefulBuilder(
                                          builder: (context, setState) {
                                            final isSaleRateLow = (double.tryParse(_selectedItems[i].saleRate.toString()) ?? 0.0) < _selectedItems[i].purchaseRate;
                                            return Tooltip(
                                              message: isSaleRateLow ? 'Warning: Sale rate is less than purchase rate!' : '',
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  TextField(
                                                    readOnly: _selectedStatus == 'Non Completed',
                                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                    decoration: InputDecoration(
                                                      border: OutlineInputBorder(),
                                                      contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                                                    ),
                                                    controller: _selectedStatus == 'Non Completed'
                                                        ? TextEditingController(text: '0.00')
                                                        : _saleRateControllers[_selectedItems[i].itemId],

                                                    onChanged: (value) {
                                                      final price = double.tryParse(value) ?? 0.0;
                                                      setState(() {
                                                        _selectedItems[i].saleRate = price;
                                                      });
                                                      _updateItemRateForBill(_selectedItems[i], price);
                                                    },
                                                  ),
                                                  if (isSaleRateLow)
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 4.0),
                                                      child: Container(
                                                        padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                                                        decoration: BoxDecoration(
                                                          color: Colors.red[100],
                                                          borderRadius: BorderRadius.circular(4.0),
                                                        ),
                                                        child: Row(
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            Icon(Icons.warning, color: Colors.red, size: 10.0),
                                                            SizedBox(width: 3),
                                                            Text("Warning", style: TextStyle(color: Colors.red, fontSize: 10)),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(20, 15, 4, 0),
                                        child: _selectedStatus == 'Completed'
                                            ? Text(_selectedItems[i].total.toStringAsFixed(2))
                                            : Text("0.00"),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: IconButton(
                                          icon: Icon(Icons.delete, color: Colors.red),
                                          onPressed: () {
                                            setState(() {
                                              _selectedItems.removeAt(i);
                                              _calculateTotalAmount();
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                for (int i = 0; i + _selectedItems.length < 10; i++)
                                  TableRow(
                                    children: List.generate(9, (_) => Padding(
                                        padding: const EdgeInsets.all(8.0), child: Text(''))),
                                  ),
                              ],
                            ),
                            SizedBox(height: 24),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                crossAxisAlignment :  CrossAxisAlignment.start,
                                mainAxisAlignment : MainAxisAlignment.spaceBetween ,
                                children: [
                                  _selectedStatus == 'Non Completed' ?  SizedBox() :
                                  Column(
                                    crossAxisAlignment :  CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            "Profit: ",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            _calculateProfit(), // Calculating profit based on total and purchase price
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                              color: _getProfitColor(), // Green for profit, red for loss
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height : 5),
                                      SizedBox(
                                        width: 300, // Set the width you want
                                        child: TextField(
                                          controller: _descriptionController,  // Your description controller
                                          maxLines: 3,  // Limit to 3 lines
                                          textAlign: TextAlign.start,  // Align text to the start
                                          decoration: InputDecoration(
                                            labelText: 'Description',  // Label for the TextField
                                            border: OutlineInputBorder(),  // Add a border around the TextField
                                          ),
                                          style: TextStyle(fontSize: 16),  // Optional: Customize text style
                                          keyboardType: TextInputType.multiline,  // Allow multiline input
                                          textInputAction: TextInputAction.newline,  // Allow new line

                                          // Add this to handle text changes
                                          onChanged: (text) {
                                            _descriptionController.text = text;
                                          },
                                        ),
                                      )
                                    ],
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // Header
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                "Sub Total: ",
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              _selectedStatus == 'Non Completed'
                                                  ? Text(
                                                'Rs 0.00',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  color: Colors.black87,
                                                ),
                                              )
                                                  : Text(
                                                '${NumberFormat.currency(symbol: ' ₨ ', decimalDigits: 2).format(double.tryParse(_subtotalAmountController.text) ?? 0.00)}',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                "Discount: ",
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 100,
                                                child: TextField(
                                                  decoration: InputDecoration(
                                                    prefixText: ' ₨ ',
                                                    border: InputBorder.none,
                                                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                                                    isDense: true,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.black87,
                                                  ),
                                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                  controller: _discountController,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                                  ],
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _discount = double.tryParse(value) ?? 0.0;
                                                      _calculateTotalAmount();
                                                    });
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),

                                      // Divider
                                      Container(
                                        width: 200,
                                        height: 1,
                                        color: Colors.grey[400],
                                      ),
                                      SizedBox(height: 8),

                                      // Total Amount
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            "Total: ",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          _selectedStatus == 'Non Completed'
                                              ? Text(
                                            'Rs 0.00',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                              color: Colors.black87,
                                            ),
                                          )
                                              : Text(
                                            '${NumberFormat.currency(symbol: '₨ ', decimalDigits: 2).format(double.tryParse(_totalAmountController.text) ?? 0)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4),

                                      // Amount in Words
                                      _selectedStatus == 'Non Completed'
                                          ? Text(
                                        '${numberToWords(double.tryParse('0')?.toInt() ?? 0)} Rupees Only',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[700],
                                        ),
                                      )
                                          : Text(
                                        '${numberToWords(double.tryParse(_totalAmountController.text)?.toInt() ?? 0)} Rupees Only',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      SizedBox(height: 8),


                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (_selectedCustomer != null && _customerNameController.text.trim().isNotEmpty &&
                                      _selectedItems.isNotEmpty &&
                                  _customerPhoneController.text.trim().isNotEmpty &&
                                  _customerAddressController.text.trim().isNotEmpty &&
                                  _customerNameController.text.trim().isNotEmpty)
                                _isLoading
                                    ? Center(child: CircularProgressIndicator())
                                    : Align(
                                  alignment: Alignment.centerRight,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // Save Return Bill Button
                                      ElevatedButton(
                                        onPressed: _handleSave,
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          elevation: 5,
                                          shadowColor: Colors.redAccent,
                                          backgroundColor: Colors.red,  // Set the button background color to red for return bills
                                          foregroundColor: Colors.white,  // Set the text and icon color to white
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.save, size: 18, color: Colors.white),  // Add an icon to improve UX
                                            SizedBox(width: 8),
                                            Text(
                                              'Save Return Bill',
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 20),

                                      // Save & Print Return Bill Button (only visible if status is not 'Non Completed')
                                      _selectedStatus == 'Non Completed'
                                          ? SizedBox()  // If the status is "Non Completed", don't show the Print button
                                          : ElevatedButton(
                                        onPressed: () {
                                          _handleSave(printBill: true , bussinessDetails: businessProvider.businessDetails);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          elevation: 5,
                                          shadowColor: Colors.redAccent,
                                          backgroundColor: Colors.red,  // Set the button background color to red for return bills
                                          foregroundColor: Colors.white,  // Set the text and icon color to white
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.print, size: 18, color: Colors.white),  // Add an icon to improve UX
                                            SizedBox(width: 8),
                                            Text(
                                              'Save & Print Return Bill',
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                ),                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 16),

                  Expanded(
                    flex: _selectedCustomer != null && _customerNameController.text.trim().isNotEmpty || _selectedItems.isNotEmpty ? 50 : 0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.red[100],
                      ),
                      child: Column(
                        children: [
                          // Checklist Item

                          // Customer Details Card
                          if (_selectedCustomer != null && _customerNameController.text.trim().isNotEmpty && _previousBills.isNotEmpty)
                            BillSearchAndDetailsScreen(previousBills: _previousBills, onItemsSelected: _onItemsReturned,),

                          // Customer previous purchase Card
                          if (_selectedIndex != -1 && _selectedIndex < _selectedItems.length && _selectedItems.isNotEmpty)
                            SaleInformationCard(previousBills: _previousBills, selectedItem: _selectedItems[_selectedIndex]),


                          // Selected Items Cards
                          if (_selectedIndex != -1 && _selectedIndex < _selectedItems.length && _selectedItems.isNotEmpty) ...[
                            SaleHistoryCard(
                                previousRates: _itemPreviousRates[_selectedItems[_selectedIndex].itemId] ?? [],
                                selectedItem: _selectedItems[_selectedIndex]),

                            // Call the Purchase History Card widget
                            PurchaseHistoryCard(previousPurchaseRates: _itemPreviousPurchaseRates[_selectedItems[_selectedIndex].itemId] ?? [],
                                selectedItem: _selectedItems[_selectedIndex]),


                          ]

                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


}
