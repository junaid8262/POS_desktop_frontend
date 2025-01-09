import 'package:flutter/material.dart';
import 'package:namer_app/models/customer.dart';
import 'package:namer_app/services/customers.dart';
import 'package:namer_app/theme/theme.dart';
import 'package:namer_app/components/input_field.dart';


class AddEditCustomerDialog extends StatefulWidget {
  final Customer? customer;
  final VoidCallback onCustomerSaved;

  const AddEditCustomerDialog({Key? key, this.customer, required this.onCustomerSaved}) : super(key: key);

  @override
  _AddEditCustomerDialogState createState() => _AddEditCustomerDialogState();
}

class _AddEditCustomerDialogState extends State<AddEditCustomerDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController(text: '0');
  final CustomerService _customerService = CustomerService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _nameController.text = widget.customer!.name;
      _phoneNumberController.text = widget.customer!.phoneNumber;
      _addressController.text = widget.customer!.address;
      _balanceController.text = widget.customer!.balance.toString();
    }
  }

  Future<void> _handleSave() async {
    setState(() {
      _isLoading = true;
    });

    final name = _nameController.text.trim().isEmpty ? 'N/A' : _nameController.text;
    final phoneNumber = _phoneNumberController.text.trim().isEmpty ? 'N/A' : _phoneNumberController.text;
    final address = _addressController.text.trim().isEmpty ? 'N/A' : _addressController.text;
    final balance = double.tryParse(_balanceController.text.trim()) ?? 0.0;


    final customer = Customer(
      id: widget.customer?.id ?? '',
      name: name,
      phoneNumber: phoneNumber,
      address: address,
      tour: '',
      balance: widget.customer == null ? 0 : balance,
    );

    if (widget.customer == null) {
      await _customerService.addCustomer(customer);
    } else {
      await _customerService.updateCustomer(widget.customer!.id, customer);
    }

    setState(() {
      _isLoading = false;
    });

    widget.onCustomerSaved();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Color(0xFFF8F9FA),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        padding: EdgeInsets.all(16),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.customer == null ? 'Add Customer' : 'Edit Customer',
                style: AppTheme.headline6,
              ),
              SizedBox(height: 16),
              CustomTextField(
                controller: _nameController,
                label: 'Name*',
                hintText: "Name",
                onChanged: (value) {
                  setState(() {}); // Trigger rebuild to check validation
                },
              ),
              SizedBox(height: 16),
              CustomTextField(
                controller: _phoneNumberController,
                label: 'Phone Number*',
                hintText: '+92..........',
                keyboardType: TextInputType.phone,
                onChanged: (value) {
                  setState(() {}); // Trigger rebuild to check validation
                },
              ),
              SizedBox(height: 16),
              SizedBox(
                width: 400,
                child: TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Address',
                  ),
                  maxLines: 3,
                ),
              ),
              SizedBox(height: 16),
              CustomTextField(
                controller: _balanceController,
                label: 'Balance',
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),

              // Check if both fields are not empty
              if (_nameController.text.trim().isNotEmpty &&
                  _phoneNumberController.text.trim().isNotEmpty) ...[
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _handleSave,
                  style: AppTheme.elevatedButtonStyle,
                  child: Text('Save', style: AppTheme.button),
                ),
              ] else ...[
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: null,
                  style: AppTheme.elevatedButtonStyle.copyWith(
                    backgroundColor: MaterialStateProperty.all(Colors.grey), // Disabled color
                  ),
                  child: Text('Save', style: AppTheme.button),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

}
