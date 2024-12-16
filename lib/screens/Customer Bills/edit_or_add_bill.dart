import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:namer_app/models/bills.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:namer_app/models/customer.dart';
import 'package:namer_app/models/item.dart';
import 'package:namer_app/screens/Customer%20Bills/previous_customer_dialouge_card.dart';
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

import '../../components/bussiness_info_provider.dart';
import '../../components/user_provider.dart';
import '../../models/businessInfo.dart';
import '../../models/user.dart';
import '../../models/vendor_bills.dart';
import '../../services/vendor_bills.dart';
import '../Shared Bill Widgets/item_selection_dialog.dart';
import '../Shared Bill Widgets/selected_item_previous_details.dart';
import 'Bill Widgets/print_bill_pdf.dart';
import 'Return Customer Bill/edit_or_add_customer_return_bill.dart';

class AddEditBillDialog extends StatefulWidget {
  final Bill? bill;
  final VoidCallback onBillSaved;
  final bool? isQuickBill;
  final int depth; // Depth of the dialog

  const AddEditBillDialog({
    Key? key,
    this.bill,
    required this.onBillSaved,
    this.isQuickBill,
    this.depth = 0, // Default to 0 for the first dialog
  }) : super(key: key);

  @override
  _AddEditBillDialogState createState() => _AddEditBillDialogState();
}

class _AddEditBillDialogState extends State<AddEditBillDialog> {
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
  String _selectedStatus = 'Non Completed';
  double _totalAmount = 0;
  double _discount = 0;
  double _subtotal = 0;
  String? _role;
  User? _user;
  double newBalance = 0;
  int _selectedIndex = -1;
  Map<String, List<VendorBillItem>> _itemPreviousPurchaseRates = {};



  void _showAddEditBillDialog({int depth = 0}) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => AddEditBillDialog(
        onBillSaved: () {}, // Your save logic here
        isQuickBill: true, // If it's a quick bill, pass true
        depth: depth, // Pass the current depth
      ),
    );
  }


  void _showAddEditReturnBillDialog([Bill? bill]) {
    showDialog(
      context: context,
      builder: (context) => AddEditReturnBillDialog(
        bill: bill,
        onBillSaved: (){},
      ),
    );
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
                  Builder(
                      builder: (context) {
                        return _optionTile(
                          icon: Icons.add_shopping_cart,
                          title: 'Add Sale Bill',
                          description: 'Create and manage a new sale bill',
                          color: Colors.blue.shade600,
                          onTap: () {
                            if (widget.depth <= 5) {
                              Navigator.pop(context);
                              _showAddEditBillDialog(depth: widget.depth + 1);
                            } else {
                              // Show the SnackBar with the correct context
                              print("max reached");
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Maximum limit of 5 dialogs reached!'))
                              );
                            }
                          },
                        );
                      }
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
  //13Dec(updated)
  //Latest Update (Role Was Not Fetching properly)
  Future<void> _fetchRole() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _user = userProvider.user;
    setState(() {
      _role=_user!.role;
    });
    print('provider check add or Edit ${_role}');
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
      // Fetch customer and bills
      final customer = await _billService.getCustomerById(_selectedCustomerId!);
      final allBills = await _billService.getBillsByCustomerId(_selectedCustomerId!);

      // Filter bills to show only SaleBill type
      final saleBills = allBills.where((bill) => bill.billType == 'Sale Bill').toList();

      setState(() {
        _selectedCustomer = customer;
        _previousBills = saleBills.take(5).toList(); // Show only the recent 5 SaleBills
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

  void _addItemToBill(Item item) async {
    if (item.availableQuantity > 0) {
      await _fetchItemPreviousRates(item.id);
      await _fetchItemPreviousPurchaseRates(item.id);

      setState(() {
        // Initialize controllers if not already initialized
        if (!_quantityControllers.containsKey(item.id)) {
          _quantityControllers[item.id] = TextEditingController(text: '1');
        }
        if (!_discountControllers.containsKey(item.id)) {
          _discountControllers[item.id] = TextEditingController(text: '0.00');
        }
        if (!_saleRateControllers.containsKey(item.id)) {
          _saleRateControllers[item.id] = TextEditingController(text: item.saleRate.toString());
        }

        BillItem? existingItem;
        for (var selectedItem in _selectedItems) {
          if (selectedItem.itemId == item.id) {
            existingItem = selectedItem;
            break;
          }
        }

        if (existingItem != null) {
          // Increment the quantity of the existing item
          existingItem.quantity++;
          existingItem.total = existingItem.saleRate * existingItem.quantity;

          // Update the quantity controller to reflect the new quantity
          _quantityControllers[item.id]!.text = existingItem.quantity.toString();
        } else {
          // Add new item to the bill
          _selectedItems.add(BillItem(
            itemId: item.id,
            name: item.name,
            quantity: 1,
            saleRate: item.saleRate,
            purchaseRate: item.purchaseRate,
            total: item.saleRate,
            itemDiscount: 0,
            miniUnit: item.miniUnit
          ));
          // Set the quantity controller for the new item
          _quantityControllers[item.id]!.text = '1';
        }

        _calculateTotalAmount();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected item is out of stock')),
      );
    }
  }
  void _removeItemFromBill(BillItem item) {
    setState(() {
      _selectedItems.remove(item);
      _calculateTotalAmount();
    });
  }

  // todo handle update item quantity alert
  void _updateItemQuantity(BillItem item, int quantity) {
    if (quantity <= _items
        .firstWhere((i) => i.id == item.itemId)
        .availableQuantity) {
      setState(() {
        item.quantity = quantity;
        item.total = item.saleRate * quantity;
        _calculateTotalAmount();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quantity exceeds available stock')),
      );
    }
  }

  void _updateItemRateForBill(BillItem item, double saleRate) {
    setState(() {
      item.saleRate = saleRate;
      item.total = item.saleRate * item.quantity;
      print(item.total);
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

    final date = _dateController.text;
    final paymentPromisedDate = _paymentPromisedDateController.text;
    double creditAmount = double.parse(_creditController.text); // Parse credit amount

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
      // New bill creation
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
        billType: "Sale Bill",
        description: _descriptionController.text,
      );

      await _billService.addBill(newBill);

      // Reduce the items from inventory only if status is not 'Non Completed'
      if (_selectedStatus != 'Non Completed') {
        _billService.reduceItemsQuantity(_selectedItems);
        await _updateCustomerBalanceForNewBill(creditAmount);

      }



    } else {
      // Updating an existing bill
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
        billType: "Sale Bill",
        description: _descriptionController.text,
      );

      await _billService.updateBill(widget.bill!.id, newBill);

      // Update customer balance for existing bill
      await _updateCustomerBalanceForExistingBill(creditAmount);
    }

    setState(() {
      _isLoading = false;
    });

    widget.onBillSaved();

    if (printBill) {
      // Fetch customer details before printing the bill
      final customer = await _billService.getCustomerById(_selectedCustomerId!);
      // Pass the correct parameters to generatePdfAndView

      BillPdfGenerator.generatePdfAndView(newBill, customer, newBill.billType,bussinessDetails);
    }

    Navigator.pop(context);
  }

// Function to update customer balance for a new bill
  Future<void> _updateCustomerBalanceForNewBill(double creditAmount) async {
    final newBalance = _selectedCustomer!.balance + _totalAmount - creditAmount;
    await _billService.updateCustomerBalance(_selectedCustomerId!, newBalance);
    print('Customer balance updated for ID: $_selectedCustomerId to $newBalance');
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
      final newBalance = _selectedCustomer!.balance - previousTotal + previousCredit;

      // Update the customer balance
      await _billService.updateCustomerBalance(_selectedCustomerId!, newBalance);
      print('Customer balance updated for ID: $_selectedCustomerId with Non Completed status. Previous total and credit removed. New balance: $newBalance');

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
      final newBalance = _selectedCustomer!.balance + combinedBalanceChange;
      await _billService.updateCustomerBalance(_selectedCustomerId!, newBalance);

      print('Customer balance updated for ID: $_selectedCustomerId with combined changes. New balance: $newBalance');

      if (_totalAmount == previousTotal && creditAmount == previousCredit) {
        print('No balance update needed as both total and credit amounts are unchanged.');
      }
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

  void compare_updateItemListsFromDB (List<BillItem> oldList, List<BillItem> newList) {
    // Create maps to store items by their ID or name
    Map<String, BillItem> oldItemMap = {for (var item in oldList) item.itemId: item};
    Map<String, BillItem> newItemMap = {for (var item in newList) item.itemId: item};

    // Check for items in the old list that are not in the new list (removed items)
    for (var item in oldList) {
      if (!newItemMap.containsKey(item.itemId)) {

        /* This means that a certain item was removed from the edit
        bill which was earlier added in the orignal bill */

        print("item quantity to be added back  ${item.quantity}");
        _billService.updateItemQuantity(item.itemId,item.quantity,increase: true);

        print('Item removed: ${item.name}, quantity was ${item.quantity}');

      } else {
        BillItem newItem = newItemMap[item.itemId]!;
        if (newItem.quantity != item.quantity) {

          /*
          Quantity Difference: The difference between the newItem.quantity and item.quantity is calculated.
          If the difference is positive (quantityDifference > 0), it means the quantity in the new bill is higher than in the old bill, so you should increase the quantity.
          If the difference is negative (quantityDifference < 0), it means the quantity in the new bill is lower than in the old bill, so you should decrease the quantity.
          Absolute Value: The quantityDifference.abs() is used to ensure that the quantity is always a positive number, regardless of whether you're increasing or decreasing.
          Increase or Decrease: The shouldIncrease variable determines whether to call the updateItemQuantity function with increase: true or increase: false.
          */

          // Calculate the difference between the new and old quantities
          final quantityDifference = newItem.quantity - item.quantity;

          // Determine if we need to increase or decrease the quantity
          final shouldIncrease = quantityDifference < 0;

          // Update the item quantity based on the calculated difference
          _billService.updateItemQuantity(
            item.itemId,
            quantityDifference.abs(), // Use the absolute value of the difference
            increase: shouldIncrease,
          );

          print('Item quantity changed for ${item.name}: old = ${item.quantity}, new = ${newItem.quantity}');
        }
        if (newItem.saleRate != item.saleRate) {
          print('Sale rate changed for ${item.name}: old = ${item.saleRate}, new = ${newItem.saleRate}');
        }
        if (newItem.purchaseRate != item.purchaseRate) {
          print('Purchase rate changed for ${item.name}: old = ${item.purchaseRate}, new = ${newItem.purchaseRate}');
        }
        if (newItem.total != item.total) {
          print('Total changed for ${item.name}: old = ${item.total}, new = ${newItem.total}');
        }
      }
    }

    // Check for items in the new list that are not in the old list (added items)
    for (var item in newList) {
      if (!oldItemMap.containsKey(item.itemId)) {
        /* This means that a certain item was added from the edit
        bill which was earlier not in the orignal bill */
        _billService.updateItemQuantity(item.itemId,item.quantity,increase: false);
        print('New item added: ${item.name}, quantity: ${item.quantity}');
      }
    }

    // Optionally, check if both lists are identical
    bool listsAreIdentical = true;
    if (oldItemMap.length != newItemMap.length) {
      listsAreIdentical = false;
    } else {
      for (var item in oldList) {
        if (!newItemMap.containsKey(item.itemId) ||
            newItemMap[item.itemId]!.quantity != item.quantity ||
            newItemMap[item.itemId]!.saleRate != item.saleRate ||
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
    final items = await _billService
        .getItems(); // Fetch items from your service
    showDialog(
      context: context,
      builder: (context) =>
          ItemSelectionDialog(
            items: items,
            onItemsSelected: (selectedItems) {
              for (var item in selectedItems) {
                _addItemToBill(item);
              }
            },
          ),
    );
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


  @override
  Widget build(BuildContext context) {

    final businessProvider = Provider.of<BusinessDetailsProvider>(context,listen :true);
    double dialogWidth = MediaQuery.of(context).size.width; // Default width

    // Adjust dialog size based on depth
    if (widget.depth > 0) {
      dialogWidth = MediaQuery.of(context).size.width * (1 - widget.depth * 0.1); // Decrease width as depth increases
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),

      backgroundColor: Colors.white, // Set the background color to white
      child: Container(
        padding: EdgeInsets.all(16),
        width: dialogWidth,
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align items with space between
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed:() => Navigator.of(context).pop(),
                      ),
                      Text(
                        widget.bill == null ? 'Add Bill' : 'Edit Bill',
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 60,
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

                            //name and input  fields
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                                  children: [
                                    SizedBox(width :50),
                                    Center(
                                      child: Text(
                                        'BILL INVOICE',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 28,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),

                                    ElevatedButton(
                                      onPressed: () {
                                        if (widget.depth < 5){
                                          _billDialog();
                                        }
                                        else
                                          {
                                            return;
                                          }
                                        //_showAddDebitDialog(false); // Call your function to add a debit bill
                                      },
                                      child: Text('Quick Bill',style: TextStyle(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue, // Set button color if needed
                                      ),
                                    ),



                                  ],
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

                                    _role == "admin" ? SizedBox(
                                      width: 200,
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedStatus,
                                        iconEnabledColor: _selectedStatus == 'Completed' ? Colors.green : Colors.red,
                                        iconDisabledColor: _selectedStatus == 'Completed' ? Colors.green : Colors.red,
                                        hint: Text(
                                          'Select Status',
                                          style: TextStyle(
                                            color: _selectedStatus == 'Completed' ? Colors.green : Colors.red,
                                          ),
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedStatus = value!;

                                          });
                                        },
                                        items: ['Completed', 'Non Completed'].map((status) {
                                          return DropdownMenuItem(
                                            value: status,
                                            child: Text(
                                              status,
                                              style: TextStyle(
                                                color: status == 'Completed' ? Colors.green : Colors.red,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: _selectedStatus == 'Completed' ? Colors.green : Colors.red,
                                            ),
                                            borderRadius: BorderRadius.circular(30.0),
                                          ),

                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: _selectedStatus == 'Completed' ? Colors.green : Colors.red,
                                            ),
                                            borderRadius: BorderRadius.circular(30.0),
                                          ),
                                          labelText: 'Status',
                                          labelStyle: TextStyle(
                                            color: _selectedStatus == 'Completed' ? Colors.green : Colors.red,
                                          ),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                        ),
                                      ),
                                    ) :
                                    SizedBox(
                                      width: 200,
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedStatus,
                                        iconEnabledColor: _selectedStatus == 'Completed' ? Colors.green : Colors.red,
                                        iconDisabledColor: _selectedStatus == 'Completed' ? Colors.green : Colors.red,
                                        hint: Text(
                                          'Select Status',
                                          style: TextStyle(
                                            color: _selectedStatus == 'Completed' ? Colors.green : Colors.red,
                                          ),
                                        ),
                                        onChanged: null,
                                        items: ['Completed', 'Non Completed'].map((status) {
                                          return DropdownMenuItem(
                                            value: status,
                                            child: Text(
                                              status,
                                              style: TextStyle(
                                                color: status == 'Completed' ? Colors.green : Colors.red,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: _selectedStatus == 'Completed' ? Colors.green : Colors.red,
                                            ),
                                            borderRadius: BorderRadius.circular(30.0),
                                          ),

                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: _selectedStatus == 'Completed' ? Colors.green : Colors.red,
                                            ),
                                            borderRadius: BorderRadius.circular(30.0),
                                          ),
                                          labelText: 'Status',
                                          labelStyle: TextStyle(
                                            color: _selectedStatus == 'Completed' ? Colors.green : Colors.red,
                                          ),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                        ),
                                      ),
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
                                                    child: Icon(Icons.person_add_outlined, color: Colors.blueAccent),
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
                                    color: Colors.blue[100],
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
                                                decoration: InputDecoration(
                                                  border: OutlineInputBorder(),
                                                  contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                                                ),
                                                controller: _quantityControllers[_selectedItems[i].itemId],

                                                onChanged: (value) {
                                                  final quantity = int.tryParse(value) ?? 0;
                                                  setState(() {
                                                    _selectedItems[i].quantity = quantity;
                                                    _updateItemRateForBill(_selectedItems[i], _selectedItems[i].saleRate);
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
                                                          _selectedItems[i].quantity++;
                                                          _quantityControllers[_selectedItems[i].itemId]?.text = _selectedItems[i].quantity.toString(); // Update controller
                                                          _updateItemRateForBill(_selectedItems[i], _selectedItems[i].saleRate);
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
                                                          if (_selectedItems[i].quantity > 0) {
                                                            _selectedItems[i].quantity--;
                                                            _quantityControllers[_selectedItems[i].itemId]?.text = _selectedItems[i].quantity.toString(); // Update controller
                                                            _updateItemRateForBill(_selectedItems[i], _selectedItems[i].saleRate);
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
                            if (_selectedCustomer != null && _customerNameController.text.trim().isNotEmpty)
                              Card(
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
                                          "CUSTOMER BALANCE",
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
                                                      ? "Rs ${_selectedCustomer!.balance - widget.bill!.totalAmount + double.parse(_creditController.text)}"
                                                      : "Rs ${_selectedCustomer!.balance.toString()}",
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
                                                      ? "Rs ${_selectedCustomer!.balance - widget.bill!.totalAmount + double.parse(_creditController.text)}"
                                                      : _selectedStatus == 'Non Completed'
                                                      ? "Rs ${_selectedCustomer!.balance}"
                                                      : widget.bill != null
                                                      ? "Rs ${_selectedCustomer!.balance + _totalAmount - widget.bill!.totalAmount + double.parse(_creditController.text)}"
                                                      : "Rs ${_selectedCustomer!.balance + _totalAmount + double.parse(_creditController.text)}",
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
                                                  ? "Rs ${_selectedCustomer!.balance - widget.bill!.totalAmount + double.parse(_creditController.text)}"
                                                  : "Rs ${_selectedCustomer!.balance}",
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
                                                  ? "Rs ${_selectedCustomer!.balance - widget.bill!.totalAmount + double.parse(_creditController.text)}"
                                                  : _selectedStatus == 'Non Completed'
                                                  ? "Rs ${_selectedCustomer!.balance + 0}"
                                                  : widget.bill != null
                                                  ? "Rs ${_selectedCustomer!.balance + _totalAmount - widget.bill!.totalAmount + double.parse(_creditController.text)}"
                                                  : "Rs ${_selectedCustomer!.balance + _totalAmount + double.parse(_creditController.text)}",
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
                                                  double allowedAmount = _selectedCustomer!.balance + _totalAmount;

                                                  _creditController.addListener(() {
                                                    setState(() {});
                                                  });

                                                  return Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      TextField(
                                                        readOnly: _selectedStatus == 'Non Completed' ? true : false,
                                                        controller: _selectedStatus == 'Non Completed' ? TextEditingController(text :"0.00") : _creditController,
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

                                        // Conditional Button or Loader
                                        SizedBox(height: 30),
                                        if (_selectedItems.isNotEmpty &&
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
                                                ElevatedButton(
                                                  onPressed: _handleSave,
                                                  // onPressed : (){
                                                  //   print("Bill ID: ${widget.bill!.id}");
                                                  //   print("Customer ID: $_selectedCustomerId");
                                                  //   print("Items: $_selectedItems");
                                                  //   print("Total Amount: $_totalAmount");
                                                  //   print("Discount: $_discount");
                                                  //   print("Status: $_selectedStatus");
                                                  //   print("Amount Given: ${double.parse(_creditController.text)}");
                                                  //   print("Bill Type: Sale Bill");
                                                  //   print("Description: ${_descriptionController.text}");
                                                  // },
                                                  style: ElevatedButton.styleFrom(
                                                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    elevation: 5,
                                                    shadowColor: Colors.black54,
                                                  ),
                                                  child: Text('Save Bill', style: TextStyle(fontSize: 16)),
                                                ),
                                                SizedBox(width: 20),
                                                _selectedStatus == 'Non Completed'
                                                    ? SizedBox()
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
                                                    shadowColor: Colors.black54,
                                                  ),
                                                  child: Text('Save & Print Bill', style: TextStyle(fontSize: 16)),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 16),

                  Expanded(
                    flex: _selectedCustomer != null && _customerNameController.text.trim().isNotEmpty || _selectedItems.isNotEmpty ? 40 : 0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.blue[100],
                      ),
                      child: Column(
                        children: [
                          // Checklist Item

                          // Customer Details Card
                          if (_selectedCustomer != null && _customerNameController.text.trim().isNotEmpty && _previousBills.isNotEmpty)
                            PreviousCustomerBillsCard(previousBills: _previousBills,),

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

}
