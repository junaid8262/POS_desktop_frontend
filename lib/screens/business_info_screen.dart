import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../components/bussiness_info_provider.dart';
import '../models/businessInfo.dart'; // Update with the actual model file
import '../services/businessInfo.dart'; // Update with the actual service file

class BusinessInfoScreen extends StatefulWidget {
  @override
  _BusinessInfoScreenState createState() => _BusinessInfoScreenState();
}

class _BusinessInfoScreenState extends State<BusinessInfoScreen> {
  final BusinessDetailsService _businessDetailsService = BusinessDetailsService();
  BusinessDetails? _businessDetails;
  bool _isEditing = true;
  String logoURL = '';
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  File? _image;

  @override
  void initState() {
    super.initState();
    _fetchBusinessDetails();
  }

  Future<void> _pickImage() async {
    try {
      final typeGroup = XTypeGroup(
        label: 'images',
        extensions: <String>['jpg', 'png', 'jpeg'],
      );
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file != null) {
        setState(() {
          _image = File(file.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }


  Future<void> _fetchBusinessDetails() async {
    try {
      // Fetch the single business detail from the DB
      final details = await _businessDetailsService.getBusinessDetails(); // Fetch the single record
      if (details != null) {
        setState(() {
          _businessDetails = details[0];
          logoURL = details[0].companyLogo;
          _addressController.text = details[0].companyAddress;
          _phoneController.text = details[0].companyPhoneNo;
          _nameController.text = details[0].companyName;
        });
      } else {
        // If no business details exist, treat it as the first time

      }
    } catch (e) {
      // Handle errors while fetching data
      print("Error fetching business details: $e");
    }
  }

  Future<void> _saveBusinessDetails() async {
    try {
      setState(() {
        _isEditing = false;
      });

      // Only upload an image if a new one is selected
      if (_image != null) {
        logoURL = await _businessDetailsService.uploadImage(_image!);
      }

      // Create or update the business details
      BusinessDetails updatedDetails = BusinessDetails(
        id: _businessDetails?.id ?? '', // Empty if creating a new record
        companyLogo: logoURL, // Use the existing logoURL if no new image is uploaded
        companyAddress: _addressController.text,
        companyPhoneNo: _phoneController.text,
        companyName: _nameController.text,
      );

      if (_businessDetails == null) {
        // Create new business details
        await _businessDetailsService.createBusinessDetail(updatedDetails);
      } else {
        // Update existing business details
        await _businessDetailsService.updateBusinessDetail(_businessDetails!.id!, updatedDetails);
      }

      // Update the provider with the new business details
      final businessProvider = Provider.of<BusinessDetailsProvider>(context, listen: false);
      businessProvider.setBusinessDetails(updatedDetails);

      // Optionally fetch the updated data from the backend and refresh the provider
      final List<BusinessDetails> fetchedDetails = await _businessDetailsService.getBusinessDetails();
      if (fetchedDetails.isNotEmpty) {
        businessProvider.setBusinessDetails(fetchedDetails[0]);
      }

      setState(() {
        _isEditing = true;
        _businessDetails = updatedDetails; // Update the local state as well
      });
    } catch (e) {
      print("Error saving business details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: !_isEditing
          ? Center(child: CircularProgressIndicator()) // Show loading spinner while fetching
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Company Logo:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                logoURL.isNotEmpty && _image == null
                    ? SizedBox(
                  width: 300,
                  height: 200,
                  child: Image.network('${dotenv.env['BACKEND_URL']!}${logoURL}'),
                )
                    : _image != null
                    ? SizedBox(
                  width: 300,
                  height: 200,
                  child: Image.file(
                    _image!,
                    fit: BoxFit.cover,
                  ),
                )
                    : SizedBox(),
                _image == null
                    ? TextButton.icon(
                  icon: Icon(Icons.image),
                  label: Text('Pick Image'),
                  onPressed: _pickImage,
                )
                    : Column(
                  children: [
                    TextButton.icon(
                      icon: Icon(Icons.image),
                      label: Text('Change Image'),
                      onPressed: _pickImage,
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'Company Name:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                _isEditing
                    ? SizedBox(
                  width: 500,
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter company Name',
                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    ),
                  ),
                )
                    : SizedBox(
                  width: 500,
                  child: TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'No Name available',
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    ),
                    controller: TextEditingController(
                        text: _businessDetails?.companyName ?? 'No Name available'),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Company Address:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                _isEditing
                    ? SizedBox(
                  width: 500,
                  child: TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter company address',
                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    ),
                  ),
                )
                    : SizedBox(
                  width: 500,
                  child: TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'No address available',
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    ),
                    controller: TextEditingController(
                        text: _businessDetails?.companyAddress ?? 'No address available'),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Company Phone Number:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                _isEditing
                    ? SizedBox(
                  width: 500,
                  child: TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter company phone number',
                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    ),
                  ),
                )
                    : SizedBox(
                  width: 500,
                  child: TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'No phone number available',
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    ),
                    controller: TextEditingController(
                        text: _businessDetails?.companyPhoneNo ?? 'No phone number available'),
                  ),
                ),
                SizedBox(height: 24),
                _isEditing
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _saveBusinessDetails,
                      child: Text('Save'),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                        });
                      },
                      child: Text('Cancel'),
                    ),
                  ],
                )
                    : ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  child: Text('Edit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
