import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/businessInfo.dart';
import '../../../models/vendor.dart';
import '../../../models/vendor_bills.dart';

class ShowVendorBillItems {
  static void show(BuildContext context, VendorBill vendorBill, Vendor vendor,BusinessDetails? businessDetails) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        titlePadding: EdgeInsets.zero,
        title: Column(
          children: [
            // Company Header
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(businessDetails!.companyName,
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                      SizedBox(height: 5),
                      Text(businessDetails.companyAddress,
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(businessDetails.companyPhoneNo, style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Vendor Invoice',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                            color: vendorBill.billType == "Return Bill" ?  Colors.red :Colors.blue),
                      ),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          backgroundColor: vendorBill.billType == "Return Bill" ?  Colors.red :Colors.blue,
                          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        child: Text( vendorBill.billType == "Return Bill" ?'RETURN BILL'  :'SALE BILL', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Vendor and Invoice Details
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Invoice Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Vendor Name: ${vendor.name}', style: TextStyle(fontSize: 14)),
                          SizedBox(height: 5),
                          Text('Vendor Address: ${vendor.address}', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Vendor Phone: ${vendor.phoneNumber}', style: TextStyle(fontSize: 14)),
                          SizedBox(height: 5),
                          Text(
                            'Invoice Date: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(vendorBill.date))}',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              // Items Table
              Container(
                child: Table(
                  columnWidths: {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(4),
                    2: FlexColumnWidth(1.5),
                    3: FlexColumnWidth(1.5),
                    4: FlexColumnWidth(2.5),
                    5: FlexColumnWidth(2),
                  },
                  border: TableBorder.all(color: Colors.grey),
                  children: [
                    TableRow(
                      children: [
                        _tableHeader('No'),
                        _tableHeader('Product Name'),
                        _tableHeader('Qty'),
                        _tableHeader('Unit'),
                        _tableHeader('Price'),
                        _tableHeader('Total'),
                      ],
                    ),
                    ...vendorBill.items.asMap().entries.map((entry) {
                      int index = entry.key;
                      var item = entry.value;
                      return TableRow(
                        children: [
                          _tableCell((index + 1).toString()),
                          _tableCell(item.name),
                          _tableCell(item.quantity.toString()),
                          _tableCell(item.miniUnit.toString()),
                          _tableCell(item.purchaseRate.toStringAsFixed(2)),
                          _tableCell((item.quantity * item.purchaseRate).toStringAsFixed(2)),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Description : ' + (vendorBill.description.trim().isEmpty ? "N/A" : vendorBill.description),
                        style: TextStyle(fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Total Amount Section
              Container(
                padding: EdgeInsets.all(16),
                color: Colors.grey[200],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                      'Rs ${vendorBill.items.fold(0.0, (double sum, item) => sum + item.quantity * item.purchaseRate).toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
              ),

              // Footer
            ],
          ),
        ),
        actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: Text('Close', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  static void showDebitAndDiscountBill(BuildContext context, VendorBill bill, Vendor customer,BusinessDetails? businessDetails) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            titlePadding: EdgeInsets.zero,
            title: Column(
              children: [
                // Company Header
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            businessDetails!.companyName,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            businessDetails.companyAddress,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            businessDetails.companyPhoneNo,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Invoice',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: bill.billType == 'Debit Bill' ? Colors.green : Colors.amber ,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              backgroundColor: bill.billType == 'Debit Bill' ? Colors.green : Colors.amber,
                              padding: EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: Text(
                              bill.billType == 'Debit Bill' ? 'DEBIT BILL' : 'DISCOUNT BILL',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Customer and Invoice Details
                Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invoice Details',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Customer Name: ${customer.name}',
                                style: TextStyle(fontSize: 14),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Customer Address: ${customer.address}',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Customer Phone: ${customer.phoneNumber}',
                                style: TextStyle(fontSize: 14),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Sales Date: ${DateFormat('dd-MM-yyyy').format(
                                    DateTime.parse(bill.date))}',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  // Description and Amount Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description: ${bill.description
                              .trim()
                              .isEmpty ? "N/A" : bill.description}',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Amount:',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Rs ${bill.amountGiven?.toStringAsFixed(2) ??
                                  "0.00"}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
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
                    backgroundColor:bill.billType == 'Debit Bill' ? Colors.green : Colors.amber,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Text('Close', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
    );
  }

  static Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  static Widget _tableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(text),
    );
  }
}
