import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:namer_app/models/vendor.dart';
import 'package:namer_app/models/item.dart';
import 'package:namer_app/theme/theme.dart';
import 'package:namer_app/components/input_field.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../components/bussiness_info_provider.dart';
import '../../models/businessInfo.dart';
import '../../models/vendor_bills.dart';
import '../../services/vendor_bills.dart';
import '../Shared Bill Widgets/item_selection_dialog.dart';
import 'Vendor Bill Widgets/print_vendor_bill_pdf.dart';

class AddEditVendorBillDialog extends StatefulWidget {
  final VendorBill? bill;
  final VoidCallback onBillSaved;

  const AddEditVendorBillDialog({Key? key, this.bill, required this.onBillSaved}) : super(key: key);

  @override
  _AddEditVendorBillDialogState createState() => _AddEditVendorBillDialogState();
}

class _AddEditVendorBillDialogState extends State<AddEditVendorBillDialog> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _subtotalAmountController = TextEditingController();
  final TextEditingController _vendorAddressController = TextEditingController();
  final TextEditingController _vendorPhoneController = TextEditingController();
  final TextEditingController _vendorNameController = TextEditingController();
  final TextEditingController _vendorShopNameController = TextEditingController();
  final TextEditingController _paymentPromiseDateController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _creditController = TextEditingController();

  final VendorBillService _billService = VendorBillService();
  bool _isLoading = false;

  Map<String, TextEditingController> _quantityControllers = {};
  Map<String, TextEditingController> _purchaseRateControllers = {};
  Map<String, double> _initialPurchaseRates = {};


  List<Vendor> _vendors = [];
  List<Item> _items = [];
  List<VendorBill> _previousBills = [];
  Map<String, List<VendorBillItem>> _itemPreviousPurchaseRates = {};
  String? _selectedVendorId;
  Vendor? _selectedVendor;
  List<VendorBillItem> _selectedItems = [];
  String _selectedStatus = 'Completed';
  double _totalAmount = 0;
  double _discount = 0;
  double _subtotal = 0;
  String? _role;
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();

    if (widget.bill != null) {
      _selectedVendorId = widget.bill!.vendorId;
      DateTime date = DateTime.parse(widget.bill!.date);
      _dateController.text = DateFormat('dd-MM-yyyy').format(date);

      DateTime paymentPromiseDate = DateTime.parse(widget.bill!.paymentPromiseDate);
      _paymentPromiseDateController.text = DateFormat('dd-MM-yyyy').format(paymentPromiseDate);

      // Iterate over the items in the bill to initialize the purchase rates
      _selectedItems = widget.bill!.items.map((item) {

        // Initialize controllers for each item
        _quantityControllers[item.itemId] = TextEditingController(text: item.quantity.toString());
        _purchaseRateControllers[item.itemId] = TextEditingController(text: item.purchaseRate.toString());

        // Fetch previous rates only when editing a bill
        _fetchItemPreviousPurchaseRates(item.itemId);

        // Initialize the previous purchase rate (if available) or use the current rate
        _initialPurchaseRates[item.itemId] = item.purchaseRate;

        return VendorBillItem(
          itemId: item.itemId,
          name: item.name,
          quantity: item.quantity,
          purchaseRate: item.purchaseRate,
          total: item.total,
          miniUnit: item.miniUnit

        );
      }).toList();

      _creditController.text = widget.bill!.amountGiven.toString();
      _totalAmountController.text = widget.bill!.totalAmount.toString();
      _selectedStatus = widget.bill!.status;
      _discountController.text = widget.bill!.discount.toString();
      _descriptionController.text = widget.bill!.description.toString();

      _calculateTotalAmount();

      // Fetch vendor details for the selected vendor
      _fetchVendorDetails();

      // Fetch the previous purchase rates for each item
      for (var item in _selectedItems) {
        _fetchItemPreviousPurchaseRates(item.itemId);
      }
    } else {
      // If this is a new bill
      _discountController.text = '0.00';
      _setDefaultDate();
      _setDefaultpaymentPromiseDate();
      _creditController.text = '0.00';

    }

    _fetchRole();
    _fetchItems();
    _fetchVendors();
  }

  void _setDefaultDate() {
    DateTime pickedDefaultDate = DateTime.now();
    _dateController.text = DateFormat('dd-MM-yyyy').format(pickedDefaultDate);
  }

  void _setDefaultpaymentPromiseDate() {
    DateTime pickedDefaultDate = DateTime.now();
    _paymentPromiseDateController.text = DateFormat('dd-MM-yyyy').format(pickedDefaultDate);
  }

  Future<void> _fetchRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = prefs.getString('role');
    });
  }

  Future<void> _fetchVendors() async {
    final vendors = await _billService.getVendors();
    setState(() {
      _vendors = vendors;
    });
  }

  Future<void> _fetchItems() async {
    final items = await _billService.getItems();
    setState(() {
      _items = items;
    });
  }

  Future<void> _fetchVendorDetails() async {
    if (_selectedVendorId != null) {
      final vendor = await _billService.getVendorById(_selectedVendorId!);
      final previousBills = await _billService.getVendorBillsByVendorId(_selectedVendorId!);

      // Debug: Check if the fetched bills are correct
      previousBills.forEach((bill) {
        print('Bill Vendor ID: ${bill.vendorId}, Selected Vendor ID: $_selectedVendorId');
      });

      setState(() {
        _selectedVendor = vendor;
        _previousBills = previousBills
            .where((bill) => bill.vendorId == _selectedVendorId) // Ensure the correct vendor bills
            .take(5)
            .toList();
        _vendorNameController.text = vendor.name.toString();
        _vendorAddressController.text = vendor.address.toString();
        _vendorPhoneController.text = vendor.phoneNumber.toString();
        _vendorShopNameController.text = vendor.businessName.toString();
      });
    }
  }

  Future<void> _fetchItemPreviousPurchaseRates(String itemId) async {
    // Fetch item rates by vendor from the new method in VendorBillService
    final itemRates = await _billService.getItemRatesByVendorId(itemId);

    // Update the state to store the previous purchase rates
    setState(() {
      _itemPreviousPurchaseRates[itemId] = itemRates;
    });
  }

  void _addItemToBill(Item item) async {
    await _fetchItemPreviousPurchaseRates(item.id);
    setState(() {
      if (!_quantityControllers.containsKey(item.id)) {
        _quantityControllers[item.id] = TextEditingController(text: '1');
      }
      if (!_purchaseRateControllers.containsKey(item.id)) {
        _purchaseRateControllers[item.id] = TextEditingController(text: item.purchaseRate.toStringAsFixed(2));
      }

      // Initialize the purchase rate if it doesn't exist
      _initialPurchaseRates[item.id] ??= item.purchaseRate;

      VendorBillItem? existingItem;
      for (var selectedItem in _selectedItems) {
        if (selectedItem.itemId == item.id) {
          existingItem = selectedItem;
          break;
        }
      }

      if (existingItem != null) {
        existingItem.quantity++;
        existingItem.total = existingItem.purchaseRate * existingItem.quantity;
      } else {
        _selectedItems.add(VendorBillItem(
          itemId: item.id,
          name: item.name,
          quantity: 1,
          purchaseRate: item.purchaseRate,
          total: item.purchaseRate,
          miniUnit: item.miniUnit
        ));
      }

      _calculateTotalAmount();
    });
  }
  void _removeItemFromBill(VendorBillItem item) {
    setState(() {
      _selectedItems.remove(item);
      _calculateTotalAmount();
    });
  }

  void _updateItemQuantity(VendorBillItem item, int quantity) {
    setState(() {
      item.quantity = quantity;
      item.total = item.purchaseRate * quantity;
      _calculateTotalAmount();
    });
  }

  void _updateItemRateForBill(VendorBillItem item, double purchaseRate) {
    setState(() {
      item.purchaseRate = purchaseRate;
      item.total = item.purchaseRate * item.quantity;
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
      _totalAmount = _subtotal - _discount;
      _totalAmountController.text = _totalAmount.toStringAsFixed(2);
    });
  }

  Future<void> _handleSave({bool printBill = false , BusinessDetails? bussinessDetails}) async {
    setState(() {
      _isLoading = true;
    });

    final date = _dateController.text;
    final paymentPromiseDate = _paymentPromiseDateController.text;
    double creditAmount = double.parse(_creditController.text); // Parse credit amount

    VendorBill newBill;

    if (widget.bill == null) {
      newBill = VendorBill(
        id: '',
        vendorId: _selectedVendorId!,
        date: date,
        items: _selectedItems,
        billType: "Sale Bill",
        totalAmount: _totalAmount,
        discount: _discount,
        status: _selectedStatus,
        paymentPromiseDate : paymentPromiseDate,
        amountGiven: creditAmount,
        description: _descriptionController.text,
      );
      await _billService.addVendorBill(newBill);

      _billService.increaseVendorBillItemsQuantity(_selectedItems);
      _updateCustomerBalanceForNewBill(creditAmount);
    } else {

      newBill = VendorBill(
          id: widget.bill!.id,
          vendorId: _selectedVendorId!,
          date: date,
          items: _selectedItems,
          totalAmount: _totalAmount,
          status: _selectedStatus,
          paymentPromiseDate: paymentPromiseDate,
          discount: _discount,
          amountGiven: creditAmount,
          description: _descriptionController.text,
          billType: "Sale Bill"
      );
      await _billService.updateVendorBill(widget.bill!.id,newBill );
      _updateCustomerBalanceForExistingBill(creditAmount);
    }

    setState(() {
      _isLoading = false;
    });
    widget.onBillSaved();

    if (printBill) {
      final customer = await _billService.getVendorById(_selectedVendorId!);
      // Pass the correct parameters to generatePdfAndView
      VendorBillPdfGenerator.generatePdfAndView(newBill, customer, newBill.billType,bussinessDetails);
    }

    Navigator.pop(context);
  }


  // Function to update customer balance for a new bill
  Future<void> _updateCustomerBalanceForNewBill(double creditAmount) async {
    final newBalance = _selectedVendor!.balance + _totalAmount - creditAmount;
    await _billService.updateVendorBalance(_selectedVendorId!, newBalance);
    print('Customer balance updated for ID: $_selectedVendorId to $newBalance');
  }

// Function to update customer balance for an existing bill
  Future<void> _updateCustomerBalanceForExistingBill(double creditAmount) async {
    if (_selectedStatus == 'Non Completed') {
      // Scenario for uncompleted bill where it was previously completed.

      // Ensure credit is 0 when status is 'Non Completed'
      creditAmount = 0.0;

      final previousTotal = widget.bill!.totalAmount; // Previous total from the bill
      final previousCredit = widget.bill!.amountGiven; // Previous credit from the bill

      // Deduct previous total and credit from balance (because we are now marking it as non-completed)
      final newBalance = _selectedVendor!.balance - previousTotal + previousCredit;

      // Update the customer balance
      await _billService.updateVendorBalance(_selectedVendorId!, newBalance);
      print('Customer balance updated for ID: $_selectedVendorId with Non Completed status. Previous total and credit removed. New balance: $newBalance');

    } else {
      // Scenario for completed bill
      compare_updateItemListsFromDB(widget.bill!.items, _selectedItems);

      // Variables for previous and current values
      final previousTotal = widget.bill!.totalAmount;
      final previousCredit = widget.bill!.amountGiven;
      final totalDifference = _totalAmount - previousTotal;
      final creditDifference = creditAmount - previousCredit;

      print('Previous Total: $previousTotal');
      print('Previous Credit: $previousCredit');
      print('Total Difference: $totalDifference');
      print('Credit Difference: $creditDifference');

      // Calculate the combined effect of both total and credit differences
      final combinedBalanceChange = totalDifference - creditDifference;

      // Update the balance once with the combined change
      final newBalance = _selectedVendor!.balance + combinedBalanceChange;
      await _billService.updateVendorBalance(_selectedVendorId!, newBalance);

      print('Customer balance updated for ID: $_selectedVendorId with combined changes. New balance: $newBalance');

      if (_totalAmount == previousTotal && creditAmount == previousCredit) {
        print('No balance update needed as both total and credit amounts are unchanged.');
      }
    }
  }

  void compare_updateItemListsFromDB(List<VendorBillItem> oldList, List<VendorBillItem> newList) {
    Map<String, VendorBillItem> oldItemMap = {for (var item in oldList) item.itemId: item};
    Map<String, VendorBillItem> newItemMap = {for (var item in newList) item.itemId: item};

    for (var item in oldList) {
      if (!newItemMap.containsKey(item.itemId)) {
        _billService.updateItemQuantity(item.itemId, item.quantity, increase: false);
      } else {
        VendorBillItem newItem = newItemMap[item.itemId]!;
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

  void _showItemSelectionDialog() async {
    final items = await _billService.getItems();
    showDialog(
      context: context,
      builder: (context) => ItemSelectionDialog(
        items: items,
        onItemsSelected: (selectedItems) {
          for (var item in selectedItems) {
            _addItemToBill(item);
          }
        },
      ),
    );
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


  @override
  Widget build(BuildContext context) {
    final businessProvider = Provider.of<BusinessDetailsProvider>(context,listen :true);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      backgroundColor: Colors.white,
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
                  color: Colors.blue,
                ),
                alignment: Alignment.center,
                width: double.infinity,
                child: Text(widget.bill == null ? 'Add Vendor Bill' : 'Edit Vendor Bill',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
              ),
              SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.black26),
                        color: Colors.grey[100],
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                'VENDOR BILL INVOICE',
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Vendor Shop Name',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      TypeAheadFormField<Vendor>(
                                        textFieldConfiguration: TextFieldConfiguration(
                                          controller: _vendorShopNameController,
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(),
                                            labelText: 'Shop Name',
                                          ),
                                          onTap: () {
                                            _vendorShopNameController.selection = TextSelection(
                                              baseOffset: 0,
                                              extentOffset: _vendorShopNameController.text.length,
                                            );
                                          },
                                        ),
                                        suggestionsCallback: (pattern) {
                                          return _vendors.where(
                                                  (vendor) => vendor.businessName
                                                  .toLowerCase()
                                                  .contains(pattern.toLowerCase()) ||
                                                  vendor.id.contains(pattern));
                                        },
                                        itemBuilder: (context, Vendor suggestion) {
                                          return Container(
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 4.0, horizontal: 8.0),
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
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                              border: Border.all(color: Colors.grey[300]!),
                                            ),
                                            child: ListTile(
                                              leading: CircleAvatar(
                                                backgroundColor: Colors.blueGrey[100],
                                                child: Icon(Icons.store, color: Colors.blueAccent),
                                              ),
                                              title: Text(
                                                suggestion.businessName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 16,
                                                  color: Colors.blueGrey[900],
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
                                        onSuggestionSelected: (Vendor suggestion) {
                                          setState(() {
                                            _selectedVendorId = suggestion.id;
                                            _selectedVendor = suggestion;
                                            _vendorShopNameController.text = suggestion.businessName;
                                            _vendorNameController.text = suggestion.name;
                                            _vendorAddressController.text = suggestion.address.toString();
                                            _vendorPhoneController.text = suggestion.phoneNumber.toString();
                                          });
                                          _fetchVendorDetails();

                                        },
                                        noItemsFoundBuilder: (context) => Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text('No vendors found.'),
                                        ),
                                        suggestionsBoxDecoration: SuggestionsBoxDecoration(
                                          constraints: BoxConstraints(maxHeight: 225),
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Vendor Name',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      CustomTextField(
                                        readOnly: true,
                                        controller: _vendorNameController,
                                        label: 'Vendor Name',
                                        onChanged: (value) {
                                          setState(() {
                                            _vendorNameController.text = value;
                                          });
                                        },
                                      ),
                                      SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
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
                                                            DateFormat('dd-MM-yyyy').format(pickedDate);
                                                      });
                                                    }
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                         /* Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Due Date',
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
                                                  controller: _paymentPromiseDateController,
                                                  decoration: InputDecoration(
                                                    border: OutlineInputBorder(),
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
                                                        _paymentPromiseDateController.text =
                                                            DateFormat('dd-MM-yyyy').format(pickedDate);
                                                      });
                                                    }
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(width: 25),*/
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Vendor Phone',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      CustomTextField(
                                        readOnly: true,
                                        controller: _vendorPhoneController,
                                        label: 'Phone No',
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(r'^\d*\.?\d{0,2}')),
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            _vendorPhoneController.text = value;
                                          });
                                        },
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Vendor Address',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      CustomTextField(
                                        readOnly: true,
                                        controller: _vendorAddressController,
                                        label: 'Address',
                                        onChanged: (value) {
                                          setState(() {
                                            _vendorAddressController.text = value;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),


                            //table
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Items',
                                  style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold),
                                ),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    SizedBox(
                                      height: 40,
                                      width: 250,
                                      child: ElevatedButton(
                                        onPressed: _showItemSelectionDialog,
                                        child: Text('Add Item'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Table(
                              border: TableBorder.all(
                                  width: 1, color: Colors.grey),
                              columnWidths: {
                                0: FixedColumnWidth(40),
                                1: FlexColumnWidth(),
                                2: FixedColumnWidth(80),
                                3: FixedColumnWidth(80),
                                4: FixedColumnWidth(70),
                                5: FixedColumnWidth(80),
                                6: FixedColumnWidth(90),
                                7: FixedColumnWidth(50),
                              },

                              children: [
                                TableRow(
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('#', style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('Product Name',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize : 12
                                          )),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('Qty', style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize : 12
                                      )),

                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('Unit', style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize : 12
                                      )),

                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Center(child: Text('Prev Buy',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize : 12
                                          ))),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Center(child: Text('Purchase',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize : 12
                                          ))),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Center(child: Text('Total',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize : 12
                                          ))),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('Action', style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize : 10
                                      )),
                                    ),
                                  ],
                                ),

                                for (int i = 0; i < _selectedItems.length; i++)
                                  TableRow(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            4, 15, 4, 0),
                                        child: Center(
                                            child: Text((i + 1).toString())),
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
                                              color: _selectedIndex == i ? Colors.blue.shade100 : Colors.transparent,
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
                                                inputFormatters: [
                                                  FilteringTextInputFormatter.digitsOnly, // Restrict to numbers only
                                                ],
                                                decoration: InputDecoration(
                                                  border: OutlineInputBorder(),
                                                  contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                                                ),
                                                controller: _quantityControllers[_selectedItems[i].itemId],
                                                onChanged: (value) {
                                                  final quantity = int.tryParse(value) ?? 0;
                                                  setState(() {
                                                    _selectedItems[i].quantity = quantity;
                                                    _updateItemQuantity(_selectedItems[i], quantity); // Update only the quantity
                                                  });
                                                },
                                              ),
                                            ),
                                            Container(
                                              height: 28, // Set this to match the TextField's height
                                              child: Column(
                                                children: [
                                                  SizedBox(
                                                    height: 14, // Smaller height for increment button
                                                    width: 14,  // Smaller width for increment button
                                                    child: IconButton(
                                                      icon: Icon(Icons.arrow_drop_up),
                                                      padding: EdgeInsets.zero,
                                                      iconSize: 18, // Smaller icon size
                                                      onPressed: () {
                                                        setState(() {
                                                          _selectedItems[i].quantity++;
                                                          _quantityControllers[_selectedItems[i].itemId]?.text = _selectedItems[i].quantity.toString(); // Update controller
                                                          _updateItemQuantity(_selectedItems[i], _selectedItems[i].quantity); // Update only quantity
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: 14, // Smaller height for decrement button
                                                    width: 14,  // Smaller width for decrement button
                                                    child: IconButton(
                                                      icon: Icon(Icons.arrow_drop_down),
                                                      padding: EdgeInsets.zero,
                                                      iconSize: 18, // Smaller icon size
                                                      onPressed: () {
                                                        setState(() {
                                                          if (_selectedItems[i].quantity > 0) {
                                                            _selectedItems[i].quantity--;
                                                            _quantityControllers[_selectedItems[i].itemId]?.text = _selectedItems[i].quantity.toString(); // Update controller
                                                            _updateItemQuantity(_selectedItems[i], _selectedItems[i].quantity); // Update only quantity
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
                                            _selectedItems[i].miniUnit.toString() ?? '0.0', // Safe access with default value
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(2, 15, 2, 0),
                                          child: Text(
                                            _initialPurchaseRates[_selectedItems[i].itemId]?.toString() ?? '0.0', // Safe access with default value
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: TextField(
                                          keyboardType: TextInputType
                                              .numberWithOptions(decimal: true),
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(),
                                            contentPadding: EdgeInsets.symmetric(
                                                horizontal: 8.0),
                                          ),
                                          controller: _purchaseRateControllers[_selectedItems[i].itemId],
                                          onChanged: (value) {
                                            final price = double.tryParse(value) ?? 0.0;
                                            _selectedItems[i].purchaseRate = price;
                                            _updateItemRateForBill(_selectedItems[i], price);
                                          },
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(20, 15, 4, 0),
                                        child: Text(_selectedItems[i].total
                                            .toStringAsFixed(2)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: IconButton(
                                          icon: Icon(
                                              Icons.delete, color: Colors.red),
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


                                // empty rows
                                for (int i = 0; i + _selectedItems.length <
                                    10; i++)
                                  TableRow(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            4, 15, 4, 0),
                                        child: Center(child: Text(
                                            (i + _selectedItems.length + 1)
                                                .toString())),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(''), // Empty cell
                                      ), Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(''), // Empty cell
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(''), // Empty cell
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(''), // Empty cell
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(''), // Empty cell
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(''), // Empty cell
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: IconButton(
                                          icon: Icon(Icons.delete,
                                              color: Colors.grey.shade200),
                                          onPressed: () {
                                            // No action, as rows are empty
                                          },
                                        ),
                                      ),
                                    ],
                                  )

                              ],
                            ),
                            SizedBox(height: 24),
                            Row(
                              mainAxisAlignment : MainAxisAlignment.spaceBetween,
                              children: [
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
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                
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
                                            Text(
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
                                                  prefixText: ' ₨ ', // Prefix text for currency
                                                  border: InputBorder.none, // Removed border
                                                  labelText: null, // Removed label text
                                                  contentPadding: EdgeInsets.symmetric(vertical: 10), // Adjust padding
                                                  isDense: true, // Reduced height
                                                ),
                                                style: TextStyle(
                                                  fontSize: 18, // Adjusted font size to match the text
                                                  color: Colors.black87,
                                                ),
                                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                controller: _discountController,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')), // Allows only numbers and up to 2 decimal places
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
                                
                                    // Amount
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
                                        Text(
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
                                    Text(
                                      '${numberToWords(double.tryParse(_totalAmountController.text)?.toInt() ?? 0)} Rupees Only',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                
                                    SizedBox(height: 25),

                                    



                                  ],
                                ),
                              ],
                            ),
                            if (_selectedVendor != null && _vendorShopNameController.text.trim().isNotEmpty)
                              Container(
                                width: 800,
                                height: 500,
                                child: Card(
                                  margin: EdgeInsets.all(12),
                                  elevation: 8,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.white, Colors.grey[100]!],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Section Header
                                          Text(
                                            "VENDOR BALANCE",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                              color: Colors.black87,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                          SizedBox(height: 20),

                                          // Current and New Balance Display
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Current Balance",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    widget.bill != null
                                                        ? "Rs ${_selectedVendor!.balance - widget.bill!.totalAmount + double.parse(_creditController.text)}"
                                                        : "Rs ${_selectedVendor!.balance.toString()}",
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                  )
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    "New Balance",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    _selectedStatus == 'Non Completed' && widget.bill != null
                                                        ? "Rs ${_selectedVendor!.balance - widget.bill!.totalAmount + double.parse(_creditController.text)}"
                                                        : _selectedStatus == 'Non Completed'
                                                        ? "Rs ${_selectedVendor!.balance}"
                                                        : widget.bill != null
                                                        ? "Rs ${_selectedVendor!.balance + _totalAmount - widget.bill!.totalAmount + double.parse(_creditController.text)}"
                                                        : "Rs ${_selectedVendor!.balance + _totalAmount + double.parse(_creditController.text)}",
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ],
                                          ),

                                          // Divider for separation
                                          Divider(color: Colors.grey[300], thickness: 1.5, height: 30),

                                          // Invoice-like Addition Breakdown
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Current Balance:",
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              Text(
                                                widget.bill != null
                                                    ? "Rs ${_selectedVendor!.balance - widget.bill!.totalAmount + double.parse(_creditController.text)}"
                                                    : "Rs ${_selectedVendor!.balance}",
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              )
                                            ],
                                          ),
                                          SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "+ New Bill:",
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              _selectedStatus == 'Non Completed'
                                                  ? Text(
                                                "Rs 0",
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              )
                                                  : Text(
                                                "Rs $_totalAmount",
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 10),
                                          Divider(color: Colors.grey[300], thickness: 1.5),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Total New Balance:",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              Text(
                                                _selectedStatus == 'Non Completed' && widget.bill != null
                                                    ? "Rs ${_selectedVendor!.balance - widget.bill!.totalAmount + double.parse(_creditController.text)}"
                                                    : _selectedStatus == 'Non Completed'
                                                    ? "Rs ${_selectedVendor!.balance + 0}"
                                                    : widget.bill != null
                                                    ? "Rs ${_selectedVendor!.balance + _totalAmount - widget.bill!.totalAmount + double.parse(_creditController.text)}"
                                                    : "Rs ${_selectedVendor!.balance + _totalAmount + double.parse(_creditController.text)}",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              )
                                            ],
                                          ),

                                          // Add Credit Section
                                          SizedBox(height: 30),
                                          Text(
                                            "Add Credit:",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          SizedBox(height: 12),

                                          Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              children: [
                                                StatefulBuilder(
                                                  builder: (BuildContext context, StateSetter setState) {
                                                    double allowedAmount = _selectedVendor!.balance + _totalAmount;

                                                    _creditController.addListener(() {
                                                      setState(() {});
                                                    });

                                                    return Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        TextField(
                                                          readOnly: _selectedStatus == 'Non Completed' ? true : false,
                                                          controller: _selectedStatus == 'Non Completed'
                                                              ? TextEditingController(text: "0.00")
                                                              : _creditController,
                                                          keyboardType: TextInputType.number,
                                                          inputFormatters: <TextInputFormatter>[
                                                            FilteringTextInputFormatter.digitsOnly, // Ensures only digits are allowed
                                                          ],
                                                          decoration: InputDecoration(
                                                            hintText: "Enter amount",
                                                            contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                                                            border: OutlineInputBorder(
                                                              borderRadius: BorderRadius.circular(12),
                                                            ),
                                                          ),
                                                          onChanged: (value) {
                                                            setState(() {});
                                                          },
                                                        ),
                                                        SizedBox(height: 16),
                                                        if (int.tryParse(_creditController.text) != null &&
                                                            int.tryParse(_creditController.text)! > allowedAmount)
                                                          Text(
                                                            'Warning: Amount exceeds the available balance!',
                                                            style: TextStyle(fontSize: 14, color: Colors.red),
                                                          ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            SizedBox(height: 8),

                            if (_selectedItems.isNotEmpty &&
                                _vendorPhoneController.text.trim().isNotEmpty &&
                                _vendorAddressController.text.trim().isNotEmpty &&
                                _vendorNameController.text.trim().isNotEmpty &&
                                _vendorShopNameController.text.trim().isNotEmpty) ...[
                              _isLoading
                                  ? CircularProgressIndicator()
                                  : Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton(
                                        onPressed: _handleSave,
                                        style: AppTheme.elevatedButtonStyle,
                                        child: Text('Save Bill', style: AppTheme.button),
                                      ),
                                      SizedBox(width: 16), // Space between buttons
                                      ElevatedButton(
                                        onPressed:  () {
                                          _handleSave(printBill: true , bussinessDetails: businessProvider.businessDetails);
                                        },
                                        style: AppTheme.elevatedButtonStyle,
                                        child: Text('Save & Print Bill', style: AppTheme.button),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ] else ...[
                              _isLoading
                                  ? CircularProgressIndicator()
                                  : Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton(
                                        onPressed: null, // Disabled button
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[400], // Inactive background color
                                          foregroundColor: Colors.grey[700], // Inactive text color
                                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          'Save Bill',
                                          style: TextStyle(
                                            color: Colors.grey[600], // Inactive text color
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 16), // Space between buttons
                                      ElevatedButton(
                                        onPressed: null, // Disabled button
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[400], // Inactive background color
                                          foregroundColor: Colors.grey[700], // Inactive text color
                                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          'Save & Print Bill',
                                          style: TextStyle(
                                            color: Colors.grey[600], // Inactive text color
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    flex: _selectedVendor != null && _vendorNameController.text.trim().isNotEmpty || _selectedItems.isNotEmpty ? 40 : 0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.blue[100],
                      ),
                      child: Column(
                        children: [

                          if (_selectedVendor != null && _vendorNameController.text.trim().isNotEmpty)
                            Card(
                              margin: EdgeInsets.all(8.0),
                              elevation: 5,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_previousBills.isNotEmpty) ...[
                                      SizedBox(height: 16),
                                      Text('Previous Bills', style: AppTheme.headline6),
                                      SizedBox(height: 8),

                                      // Wrap the table in a container with a fixed height for scrolling
                                      Container(
                                        height: 150, // Set the height as per your requirement
                                        child: SingleChildScrollView(
                                          child: Table(
                                            border: TableBorder.all(
                                              color: Colors.black54,
                                              width: 1,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            columnWidths: {
                                              0: FlexColumnWidth(3),
                                              1: FlexColumnWidth(1.5),
                                              2: FlexColumnWidth(1.5),
                                              3: FlexColumnWidth(2),
                                            },
                                            children: [
                                              TableRow(
                                                decoration: BoxDecoration(
                                                  color: Colors.blue[100],
                                                ),
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(
                                                        vertical: 8.0, horizontal: 12.0),
                                                    child: Text('Bill Id',
                                                        style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.black87)),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(
                                                        vertical: 8.0, horizontal: 12.0),
                                                    child: Text('Date',
                                                        style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.black87)),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(
                                                        vertical: 8.0, horizontal: 12.0),
                                                    child: Text('Total Amount',
                                                        style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.black87)),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(
                                                        vertical: 8.0, horizontal: 12.0),
                                                    child: Text('Items',
                                                        style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.black87)),
                                                  ),
                                                ],
                                              ),
                                              // Display previous bills in the table, scrollable if there are more than a few
                                              for (var bill in _previousBills)
                                                TableRow(
                                                  children: [
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(
                                                          vertical: 8.0, horizontal: 12.0),
                                                      child: Text(
                                                        bill.id),
                                                      ),
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(
                                                          vertical: 8.0, horizontal: 12.0),
                                                      child: Text(
                                                        DateFormat('dd-MM-yyyy').format(DateTime.parse(bill.date)),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(
                                                          vertical: 8.0, horizontal: 12.0),
                                                      child: Text('\$${bill.totalAmount.toStringAsFixed(2)}'),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(
                                                          vertical: 8.0, horizontal: 12.0),
                                                      child: InkWell(
                                                        onTap: () {
                                                          _showVendorBillItems(bill);
                                                        },
                                                        child: Row(
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            Text(
                                                              'View Items',
                                                              style: TextStyle(
                                                                  color: Colors.green,
                                                                  fontWeight: FontWeight.w600),
                                                            ),
                                                            SizedBox(width: 10),
                                                            Icon(Icons.list, color: Colors.green),
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
                                    ],
                                  ],
                                ),
                              ),
                            ),

                          if (_selectedIndex != -1 && _selectedIndex < _selectedItems.length && _selectedItems.isNotEmpty)
                            Card(
                              margin: EdgeInsets.all(8.0),
                              elevation: 5,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_selectedItems[_selectedIndex].name, style: AppTheme.headline6),
                                    SizedBox(height: 8),

                                    // Wrap the Table with a Container that has a fixed height and enables scrolling
                                    Container(
                                      height: 150, // Set height based on your requirement
                                      child: SingleChildScrollView(
                                        child: Table(
                                          border: TableBorder.all(
                                            color: Colors.black54,
                                            width: 1,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          columnWidths: {
                                            0: FlexColumnWidth(3),
                                            1: FlexColumnWidth(2),
                                            2: FlexColumnWidth(2),
                                            3: FlexColumnWidth(2),
                                          },
                                          children: [
                                            TableRow(
                                              decoration: BoxDecoration(
                                                color: Colors.blue[100], // Header row background color
                                              ),
                                              children: [

                                                Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                                                  child: Text('Vendor Shop', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                                                  child: Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                                                  child: Text('Purchase Rate', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                                                  child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                                                ),
                                              ],
                                            ),

                                            // Show all available rows, scrollable if more than 5
                                            for (var rate in (_itemPreviousPurchaseRates[_selectedItems[_selectedIndex].itemId] ?? []))
                                              TableRow(
                                                children: [

                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                                                    child: Text(rate.vendorName ?? ''),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                                                    child: Text('${rate.quantity}'),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                                                    child: Text('\$${rate.purchaseRate.toStringAsFixed(2)}'),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                                                    child: Text(rate.date ?? ''),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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

  Widget _buildChecklistItem({
    required String title,
    required bool isSelected,
  }) {
    return ListTile(
      leading: Icon(
        isSelected ? Icons.check_circle : Icons.cancel,
        color: isSelected ? Colors.green : Colors.red,
      ),
      title: Text(title),
    );
  }
}
