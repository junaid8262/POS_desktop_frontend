import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/bills.dart';
import '../../models/businessInfo.dart';
import '../../models/customer.dart';
import '../../models/request.dart';
import '../../services/request.dart';

class CustomerBillActionDataCell extends StatefulWidget {
  final Future<Request?> futureRequest;
  final String employeeId;
  final String documentType;
  final String documentId;
  final String userRole;
  final Function(Bill) onEdit;
  final Function(String) onDelete;
  final Function(Bill, Customer) showBillItems;
  final Function(Bill, Customer, String ,BusinessDetails?) printBill;
  final Bill bill;
  final Customer customer;
  final BusinessDetails? businessDetails;

  CustomerBillActionDataCell({
    required this.futureRequest,
    required this.employeeId,
    required this.documentType,
    required this.documentId,
    required this.userRole,
    required this.onEdit,
    required this.onDelete,
    required this.showBillItems,
    required this.printBill,
    required this.bill,
    required this.customer,
    required this.businessDetails,
  });

  @override
  _CustomerBillActionDataCellState createState() => _CustomerBillActionDataCellState();
}

class _CustomerBillActionDataCellState extends State<CustomerBillActionDataCell> {
  final RequestService _requestService = RequestService();
  late Future<Request?> _currentRequest;

  @override
  void initState() {
    super.initState();
    if (widget.userRole != "admin") {
      _currentRequest = widget.futureRequest;
    }
  }

  // Method to show confirmation alert and proceed based on user choice
  void createRequestOnAction(BuildContext context, String employeeId, String documentType, String documentId) async {
    try {
      // Show a confirmation dialog
      bool? shouldSendRequest = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Confirm Action"),
            content: Text("Do you want to send a request for editing or deleting this document?"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false); // Cancel action
                },
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true); // Confirm action
                },
                child: Text("Send Request"),
              ),
            ],
          );
        },
      );

      // If the user confirmed the action
      if (shouldSendRequest != null && shouldSendRequest) {
        // Proceed with sending the request
        Request? newRequest = await _requestService.createRequest(employeeId, documentType, documentId);

        if (newRequest != null) {
          print('Request created successfully: ${newRequest.id}');
          // Refresh the state by reloading the request
          setState(() {
            _currentRequest = _requestService.getRequestByEmployeeAndDocument(employeeId, documentType, documentId);
          });
        } else {
          print('Failed to create request');
        }
      } else {
        print('Request action was canceled by the user');
      }
    } catch (e) {
      print('Error creating request: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // If the user is an admin, show the icons without waiting for any request
    if (widget.userRole == "admin") {
      return _buildAdminCell();
    }

    // For non-admin users, use FutureBuilder to handle requests and determine actions
    return FutureBuilder<Request?>(
      future: _currentRequest,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: _buildShimmerCell(),
          );
        }

        final request = snapshot.data;

        if (request == null) {
          return _buildNonAdminCellWithoutRequest();
        } else {
          return _buildNonAdminCellWithRequest(request);
        }
      },
    );
  }

  // Widget to display shimmer effect while loading
  Widget _buildShimmerCell() {
    return Row(
      children: [
        Icon(Icons.edit, color: Colors.blue),
        SizedBox(width: 8),
        Icon(Icons.delete, color: Colors.redAccent),
        SizedBox(width: 8),
        Icon(Icons.list, color: Colors.green),
        SizedBox(width: 8),
        Icon(Icons.print, color: Colors.teal),
      ],
    );
  }

  // Widget for admin view (full access)
  Widget _buildAdminCell() {
    return Row(
      children: [
        Tooltip(
          message: 'Edit Bill',
          child: IconButton(
            icon: Icon(Icons.edit, color: Colors.blue),
            onPressed: () => widget.onEdit(widget.bill),
          ),
        ),
        Tooltip(
          message: 'Delete Bill',
          child: IconButton(
            icon: Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () => widget.onDelete(widget.bill.id),
          ),
        ),
        Tooltip(
          message: 'View Bill Items',
          child: IconButton(
            icon: Icon(Icons.list, color: Colors.green),
            onPressed: () => widget.showBillItems(widget.bill, widget.customer),
          ),
        ),
        Tooltip(
          message: 'Print Bill',
          child: IconButton(
            icon: Icon(Icons.print, color: Colors.teal),
            onPressed: () => widget.printBill(widget.bill, widget.customer, widget.bill.billType,widget.businessDetails),
          ),
        ),
      ],
    );
  }

  // Widget for non-admin view when no request is available
  Widget _buildNonAdminCellWithoutRequest() {
    return Row(
      children: [
        Tooltip(
          message: 'View Bill Items',
          child: IconButton(
            icon: Icon(Icons.list, color: Colors.green),
            onPressed: () => widget.showBillItems(widget.bill, widget.customer),
          ),
        ),
        Tooltip(
          message: 'Print Bill',
          child: IconButton(
            icon: Icon(Icons.print, color: Colors.teal),
            onPressed: () => widget.printBill(widget.bill, widget.customer, widget.bill.billType,widget.businessDetails),
          ),
        ),
        Tooltip(
          message: 'Send Edit & Delete Request',
          child: IconButton(
            icon: Icon(Icons.send, color: Colors.blue.shade300),
            onPressed: () => createRequestOnAction(context, widget.employeeId, widget.documentType, widget.bill.id,),
          ),
        ),
      ],
    );
  }

  // Widget for non-admin view when a request exists
  Widget _buildNonAdminCellWithRequest(Request request) {
    return Row(
      children: [
        Tooltip(
          message: 'View Bill Items',
          child: IconButton(
            icon: Icon(Icons.list, color: Colors.green),
            onPressed: () => widget.showBillItems(widget.bill, widget.customer),
          ),
        ),
        Tooltip(
          message: 'Print Bill',
          child: IconButton(
            icon: Icon(Icons.print, color: Colors.teal),
            onPressed: () => widget.printBill(widget.bill, widget.customer, widget.bill.billType,widget.businessDetails),
          ),
        ),
        if (request.status == "pending") ...[
          Tooltip(
            message: 'Pending Edit & Delete Request',
            child: IconButton(
              icon: Icon(Icons.hourglass_empty, color: Colors.orange),
              onPressed: null,
            ),
          ),
        ] else if (request.status == "denied") ...[
          Tooltip(
            message: 'Denied Edit & Delete Request',
            child: IconButton(
              icon: Icon(Icons.block, color: Colors.red),
              onPressed: null,
            ),
          ),
        ] else if (request.status == "approved") ...[
          Tooltip(
            message: 'Edit Bill',
            child: IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: () => widget.onEdit(widget.bill),
            ),
          ),
          Tooltip(
            message: 'Delete Bill',
            child: IconButton(
              icon: Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => widget.onDelete(widget.bill.id),
            ),
          ),
        ],
      ],
    );
  }
}
