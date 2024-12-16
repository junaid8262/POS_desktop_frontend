import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import '../../components/bussiness_info_provider.dart';
import '../../models/bills.dart';
import '../../models/businessInfo.dart';
import '../../models/customer.dart';
import '../../models/item.dart';
import '../../models/request.dart';
import '../../models/vendor.dart';
import '../../models/vendor_bills.dart';
import '../../services/bills.dart';
import '../../services/items.dart';
import '../../services/request.dart';
import '../../services/vendor_bills.dart';
import '../Customer Bills/Bill Widgets/show_bill_items.dart';
import '../Vendor Bills/Vendor Bill Widgets/show_vendor_ bill_items.dart';

class RequestDetailsPopup {
  final BuildContext context;
  final RequestService _requestService = RequestService();
  Bill? _bill;
  VendorBill? _vendorBill;
  Vendor? _vendor;
  Customer? _customer;
  BusinessDetails? _businessDetails;
  Item? _item;

  RequestDetailsPopup(this.context);

  Future<void> _fetchRequestDetails(Request request) async {
    // Show loading indicator while fetching data
    _showLoadingDialog();

    print("type ${request.documentType}");
    print("id  ${request.documentId}");
    final businessProvider = Provider.of<BusinessDetailsProvider>(context, listen: false);
    _businessDetails = businessProvider.businessDetails;

    BillService billService = BillService();
    VendorBillService vendorBillService = VendorBillService();

    if (request.documentType == 'Bill') {
      _bill = await billService.getBill(request.documentId);
      if (_bill != null) {
        _customer = await billService.getCustomerById(_bill!.customerId);
      }
    } else if (request.documentType == 'VendorBill') {
      _vendorBill = await vendorBillService.getVendorBill(request.documentId);
      if (_vendorBill != null) {
        _vendor = await vendorBillService.getVendorById(_vendorBill!.vendorId);
      }
    } else if (request.documentType == 'Customer') {
      _customer = await billService.getCustomerById(request.documentId);
    } else if (request.documentType == 'Vendor') {
      _vendor = await vendorBillService.getVendorById(request.documentId);
    }
    else if (request.documentType == 'Item') {
      ItemService itemService = ItemService();
      _item = await itemService.getItem(request.documentId);
    }

    // Close the loading dialog
    Navigator.pop(context);

    // Show the actual request details
    _showRequestDetailsPopup(request);
  }

  void _showRequestDetailsPopup(Request request) {
    // Use WidgetsBinding to ensure that the dialog is shown after the build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (request.documentType == 'Bill' && _bill != null && _customer != null) {
        // Show Bill details using ShowBillItems.show
        ShowBillItems.show(context, _bill!, _customer!, _businessDetails);
      } else if (request.documentType == 'VendorBill' && _vendorBill != null && _vendor != null) {
        // Show Vendor Bill details using ShowVendorBillItems.show
        ShowVendorBillItems.show(context, _vendorBill!, _vendor!, _businessDetails);
      } else if (request.documentType == 'Customer' && _customer != null) {
        _showCustomerDetailsDialog();
      } else if (request.documentType == 'Vendor' && _vendor != null) {
        _showVendorDetailsDialog();
      }
      else if (request.documentType == 'Item' && _item != null) {
        _showItemDetailsDialog();
      }
      else {
        // If data is still loading or incomplete, you can show a loading indicator
        _showLoadingDialog(); // To handle cases where loading is still needed
      }
    });
  }

  void _showItemDetailsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Center(
          child: Text(
            'Item Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.blueAccent,
            ),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item image
              _item?.picture != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: Image.network(
                    '${dotenv.env['BACKEND_URL']!}${_item?.picture}',
                    fit: BoxFit.cover,
                  ),
                ),
              )
                  : Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'No Image Available',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Item name and brand
              Text(
                'Name: ${_item?.name ?? 'Unknown'}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Brand: ${_item?.brand ?? 'Unknown'}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 20),

              // Available quantity, purchase rate, and sale rate
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Available Quantity: ${_item?.availableQuantity ?? 'Unknown'}',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Purchase Rate: ${_item?.purchaseRate ?? 'Unknown'}',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Sale Rate: ${_item?.saleRate ?? 'Unknown'}',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomerDetailsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Center(
          child: Text(
            'Customer Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.blueAccent, // Title color
            ),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Card(
                color: Colors.blue[50],
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Name:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('${_customer?.name ?? 'Unknown'}', style: TextStyle(color: Colors.grey[700])),
                      Divider(),
                      Text(
                        'Address:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('${_customer?.address ?? 'Unknown'}', style: TextStyle(color: Colors.grey[700])),
                      Divider(),
                      Text(
                        'Phone:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('${_customer?.phoneNumber ?? 'Unknown'}', style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showVendorDetailsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Center(
          child: Text(
            'Vendor Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.blue, // Title color
            ),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Card(
                color: Colors.blue[50],
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Name:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('${_vendor?.name ?? 'Unknown'}', style: TextStyle(color: Colors.grey[700])),
                      Divider(),
                      Text(
                        'Business Name:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('${_vendor?.businessName ?? 'Unknown'}', style: TextStyle(color: Colors.grey[700])),
                      Divider(),
                      Text(
                        'Phone:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('${_vendor?.phoneNumber ?? 'Unknown'}', style: TextStyle(color: Colors.grey[700])),
                      Divider(),
                      Text(
                        'Address:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('${_vendor?.address ?? 'Unknown'}', style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }


  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,  // Prevent closing by tapping outside
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),  // Space between spinner and text
            Text("Fetching details, please wait..."),
          ],
        ),
      ),
    );
  }

  // Call this method to initiate the process of showing request details
  void showRequestDetails(Request request) {
    _fetchRequestDetails(request);
  }
}
