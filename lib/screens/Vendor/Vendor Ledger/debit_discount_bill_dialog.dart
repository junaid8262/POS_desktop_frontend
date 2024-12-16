import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/vendor.dart';
import '../../../models/vendor_bills.dart';
import '../../../services/vendor_bills.dart';

class VendorBillDialog extends StatefulWidget {
  final String title;
  final Vendor vendor;
  final bool isDebitBill;
  final VoidCallback onBillAdded;
  final balance;

  VendorBillDialog({
    required this.title,
    required this.vendor,
    required this.isDebitBill,
    required this.onBillAdded,
    required this.balance
  });

  @override
  _VendorBillDialogState createState() => _VendorBillDialogState();
}

class _VendorBillDialogState extends State<VendorBillDialog> {
  final TextEditingController _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _warningMessage = '';
  String _description = '';
  bool _isLoading = false;

  Future<void> _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _handleAmountChange(String value) {
    double enteredAmount = double.tryParse(value) ?? 0.0;
    if (enteredAmount > widget.balance) {
      setState(() {
        _warningMessage = widget.isDebitBill
            ? 'Debit amount cannot exceed balance!'
            : 'Discount amount cannot exceed balance!';
      });
    } else {
      setState(() {
        _warningMessage = '';
      });
    }
  }

  void _handleConfirm() async {
    double enteredAmount = double.tryParse(_amountController.text) ?? 0.0;
    if (enteredAmount > widget.balance) {
      return; // Amount exceeds balance
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _addDebitAmount(enteredAmount, _description, _selectedDate, widget.isDebitBill);
      widget.onBillAdded();

      Navigator.of(context).pop();
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Failed to process! Please try again.',
          style: TextStyle(color: Colors.red),
        ),
      ));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addDebitAmount(double debitAmount, String description, DateTime date, bool isDebitBill) async {
    final VendorBillService _vendorBillService = VendorBillService();

    setState(() {
      _isLoading = true; // Show loader while tasks are running
    });

    try {
      // Format the passed DateTime argument
      final formattedDate = DateFormat('dd-MM-yyyy').format(date);

      // Create a new vendor bill for the debit amount
      await _vendorBillService.addVendorBill(
        VendorBill(
          id: '',
          vendorId: widget.vendor.id,
          date: formattedDate, // Use the formatted date
          totalAmount: 0,
          amountGiven: debitAmount,
          billType: isDebitBill ? "Debit Bill" : "Discount Bill",
          description: description,
          items: [],
          discount: 0,
          status: 'Completed',
          paymentPromiseDate: formattedDate, // Also use the formatted date here
        ),
      );

      // Update vendor balance
      double newBalance = widget.balance - debitAmount;
      await _vendorBillService.updateVendorBalance(widget.vendor.id, newBalance);

      // Update the state immediately after adding debit
      setState(() {
        widget.vendor.balance = newBalance;
      });

      // Refresh bills to update UI and display the new balance and bills list
    } catch (e) {
      // Handle errors if any
      print("Error: $e");
    } finally {
      setState(() {
        _isLoading = false; // Hide loader after tasks are completed
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Center(
        child: Text(
          widget.title,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount TextField
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Amount",
              hintText: '0',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.grey[200],
            ),
            onChanged: _handleAmountChange,
          ),
          if (_warningMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 20),
                  SizedBox(width: 5),
                  Text(
                    _warningMessage,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ],
              ),
            ),
          SizedBox(height: 16),
          // Date Picker
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Select Date:', style: TextStyle(fontSize: 16)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isDebitBill ? Colors.green : Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(Icons.calendar_today, color: Colors.white),
                label: Text(
                  DateFormat('dd/MM/yyyy').format(_selectedDate),
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: _pickDate,
              ),
            ],
          ),
          SizedBox(height: 16),
          // Description Text Field
          TextField(
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'Enter a brief description (max 3 lines)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.grey[200],
            ),
            onChanged: (value) {
              setState(() {
                _description = value;
              });
            },
          ),
          SizedBox(height: 16),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      actions: [
        // Cancel Button
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ),
        // Confirm Button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isDebitBill ? Colors.green : Colors.orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _handleConfirm,
          child: Text(
            widget.isDebitBill ? 'Add Debit' : 'Add Discount',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
