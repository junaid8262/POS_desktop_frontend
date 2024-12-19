import 'package:flutter/material.dart';
import 'package:namer_app/models/vendor.dart';
import 'package:namer_app/services/vendors.dart';
import 'package:namer_app/theme/theme.dart';
import 'package:namer_app/components/input_field.dart';

class AddEditVendorDialog extends StatefulWidget {
  final Vendor? vendor;
  final VoidCallback onVendorSaved;

  const AddEditVendorDialog({Key? key, this.vendor, required this.onVendorSaved}) : super(key: key);

  @override
  _AddEditVendorDialogState createState() => _AddEditVendorDialogState();
}

class _AddEditVendorDialogState extends State<AddEditVendorDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController(text: '0');

  final VendorService _vendorService = VendorService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.vendor != null) {
      _nameController.text = widget.vendor!.name;
      _phoneNumberController.text = widget.vendor!.phoneNumber;
      _addressController.text = widget.vendor!.address;
      _businessNameController.text = widget.vendor!.businessName;
      _balanceController.text = widget.vendor!.balance.toString();

    }
  }

  Future<void> _handleSave() async {
    setState(() {
      _isLoading = true;
    });

    final name = _nameController.text.trim().isEmpty ? 'N/A' : _nameController.text;
    final phoneNumber = _phoneNumberController.text.trim().isEmpty ? 'N/A' : _phoneNumberController.text;
    final address = _addressController.text.trim().isEmpty ? 'N/A' : _addressController.text;
    final businessName = _businessNameController.text.trim().isEmpty ? 'N/A' : _businessNameController.text;
    final balance = double.tryParse(_balanceController.text.trim()) ?? 0.0;


    final vendor = Vendor(
      id: widget.vendor?.id ?? '',
      name: name,
      phoneNumber: phoneNumber,
      address: address,
      businessName: businessName,
      balance: widget.vendor == null ? 0 : balance,
    );

    if (widget.vendor == null) {
      await _vendorService.addVendor(vendor);
    } else {
      await _vendorService.updateVendor(widget.vendor!.id, vendor);
    }

    setState(() {
      _isLoading = false;
    });

    widget.onVendorSaved();
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
              Text(widget.vendor == null ? 'Add Vendor' : 'Edit Vendor', style: AppTheme.headline6),
              SizedBox(height: 16),
              CustomTextField(controller: _businessNameController, label: 'Business Name*',hintText:'Business Name*', onChanged: (value){setState(() {
                _businessNameController.text = value;
              });},),
              SizedBox(height: 16),
              CustomTextField(controller: _nameController, label: 'Name*',
                hintText: "Name",
                onChanged: (value) {
                  setState(() {}); // Trigger rebuild to check validation
                },),
              SizedBox(height: 16),
              CustomTextField(controller: _phoneNumberController, label: 'Phone Number*',hintText: '+92',),
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

              CustomTextField(readOnly: true , controller: _balanceController, label: 'Balance', keyboardType: TextInputType.number),
              SizedBox(height: 16),
              if(_businessNameController.text.trim().isNotEmpty && _nameController.text.trim().isNotEmpty &&
                  _phoneNumberController.text.trim().isNotEmpty ) ...[
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _handleSave,
                  style: AppTheme.elevatedButtonStyle,
                  child: Text('Save', style: AppTheme.button),
                ),
              ]
              else ...[
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: null,
                  style: AppTheme.elevatedButtonStyle.copyWith(
                    backgroundColor: MaterialStateProperty.all(Colors.grey), // Disabled color
                  ),
                  child: Text('Save', style: AppTheme.button),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
