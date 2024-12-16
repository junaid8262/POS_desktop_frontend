import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:namer_app/models/businessInfo.dart';
import '../../../models/bills.dart';
import '../../../models/customer.dart';

class ShowBillItems {
  static void show(BuildContext context, Bill bill,Customer customer , BusinessDetails? businessDetails) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),  // Round top-left corner
            topRight: Radius.circular(20), // Round top-right corner
            bottomLeft: Radius.circular(20), // Round bottom-left corner
            bottomRight: Radius.circular(20), // Round bottom-right corner
          ),
        ),
        titlePadding: EdgeInsets.zero,
        title: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
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
                          'Invoice',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,

                              color:bill.billType == 'Return Bill' ? Colors.red :Colors.blue),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            backgroundColor: bill.billType == 'Return Bill' ? Colors.red : Colors.blue ,
                            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                          child: bill.billType == 'Return Bill' ? Text('RETURN BILL', style: TextStyle(color: Colors.white)) :
                          Text('SALE BILL', style: TextStyle(color: Colors.white)),
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
                    Text('Invoice Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Customer Name: ${customer.name}', style: TextStyle(fontSize: 14)),
                            SizedBox(height: 5),
                            Text('Customer Address: ${customer.address}', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Customer Phone: ${customer.phoneNumber}', style: TextStyle(fontSize: 14)),
                            SizedBox(height: 5),
                            Text(
                              'Sales Date: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(bill.date))}',
                              style: TextStyle(fontSize: 14),
                            ),                        ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
                    4: FlexColumnWidth(2),
                    5: FlexColumnWidth(2),
                    6: FlexColumnWidth(2),
                  },
                  border: TableBorder.all(color: Colors.grey),
                  children: [
                    TableRow(
                      children: [
                        _tableHeader('No'),
                        _tableHeader('Product Name'),
                        _tableHeader('Qty'),
                        _tableHeader('Unit'),
                        _tableHeader('Disc %'),
                        _tableHeader('Sale Price'),
                        _tableHeader('Total'),
                      ],
                    ),
                    ...bill.items.asMap().entries.map((entry) {
                      int index = entry.key;
                      var item = entry.value;
                      return TableRow(
                        children: [
                          _tableCell((index + 1).toString()),
                          _tableCell(item.name),
                          _tableCell(item.quantity.toString()),
                          _tableCell(item.miniUnit.toString()),
                          _tableCell(item.itemDiscount.toString()),
                          _tableCell(item.saleRate.toStringAsFixed(2)),
                          _tableCell((item.quantity * item.saleRate).toStringAsFixed(2)),
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
                    Text('Description : ' + (bill.description.trim().isEmpty ? "N/A" : bill.description),
                        style: TextStyle(fontStyle: FontStyle.italic)),

                  ],
                ),
              ),
              SizedBox(height: 20),

              // Total Amount Section
              Container(
                padding: EdgeInsets.all(16),
                color: Colors.grey[200],
                child: Column(
                  children: [



                    /*Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Credit Amount :', style: TextStyle(fontSize: 16, )),
                        Text(
                          'Rs ${bill.amountGiven.toString()}',
                          style: TextStyle(fontSize: 16, color: Colors.green),
                        ),
                      ],
                    ),*/
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          'Rs ${bill.items.fold(0.0, (double sum, item) => sum + item.quantity * item.saleRate).toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                    if(bill.billType != 'Return Bill')
                      Text('Credit Amount : ' + (bill.amountGiven.toString()),style: TextStyle(fontStyle: FontStyle.italic)),
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
                backgroundColor:bill.billType == 'Return Bill' ? Colors.redAccent : Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: Text('Close', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  static void showDebitAndDiscountBill(BuildContext context, Bill bill, Customer customer ,BusinessDetails? businessDetails) {
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
