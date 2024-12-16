import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../models/bills.dart';
import '../models/customer.dart';
import '../models/item.dart';
import '../models/vendor.dart';
import '../models/vendor_bills.dart';


class CsvExporter {

  static String timestamp = DateFormat('dd_MMM_yyyy_h-mm_a').format(DateTime.now());


  static Future<void> exportCustomerLedger(List<Bill> bills, BuildContext context) async {

    List<List<dynamic>> rows = [];
    rows.add(['S.No', 'Bill ID', 'Bill Type', 'Date', 'Credit', 'Debit', 'Balance']); // Headers

    for (int index = 0; index < bills.length; index++) {
      final Bill bill = bills[index];
      final debit = bill.billType == "Return Bill" ? bill.totalAmount ?? 0.0 : bill.amountGiven ?? 0.0;
      final credit = bill.billType == "Return Bill" ? bill.amountGiven ?? 0.0 : bill.totalAmount ?? 0.0;
      double balance = index == 0 ? credit - debit : _getPreviousRowBalanceCustomer(bills, index - 1) + credit - debit;

      rows.add([
        (index + 1).toString(),
        bill.id,
        bill.billType ?? "N/A",
        bill.date != null ? DateFormat('dd-MM-yyyy').format(DateTime.parse(bill.date!)) : 'N/A',
        credit.toStringAsFixed(2),
        debit.toStringAsFixed(2),
        balance.toStringAsFixed(2),
      ]);
    }

    // Convert to CSV
    String csv = const ListToCsvConverter().convert(rows);

    // Save the CSV file
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/CustomerLedger_${timestamp}.csv';
    File file = File(path);
    await file.writeAsString(csv);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV exported successfully to $path')),
    );
  }

  static Future<void> exportVendorLedger(List<VendorBill> bills, BuildContext context) async {

    List<List<dynamic>> rows = [];
    rows.add(['S.No', 'Bill ID', 'Bill Type', 'Date', 'Credit', 'Debit', 'Balance']); // Headers

    for (int index = 0; index < bills.length; index++) {
      final VendorBill bill = bills[index];
      final debit = bill.billType == "Return Bill" ? bill.totalAmount ?? 0.0 : bill.amountGiven ?? 0.0;
      final credit = bill.billType == "Return Bill" ? bill.amountGiven ?? 0.0 : bill.totalAmount ?? 0.0;
      double balance = index == 0 ? credit - debit : _getPreviousRowBalanceVendor(bills, index - 1) + credit - debit;

      rows.add([
        (index + 1).toString(),
        bill.id,
        bill.billType ?? "N/A",
        bill.date != null ? DateFormat('dd-MM-yyyy').format(DateTime.parse(bill.date!)) : 'N/A',
        credit.toStringAsFixed(2),
        debit.toStringAsFixed(2),
        balance.toStringAsFixed(2),
      ]);
    }

    // Convert to CSV
    String csv = const ListToCsvConverter().convert(rows);

    // Save the CSV file
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/VendorLedger_${timestamp}.csv';
    File file = File(path);
    await file.writeAsString(csv);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV exported successfully to $path')),
    );
  }

  static Future<void> exportCustomerData(List<Customer> customers, BuildContext context) async {
    List<List<dynamic>> rows = [];
    rows.add(['S.No','Customer Id', 'Customer Name', 'Phone Number', 'Address', 'Balance']); // Headers

    for (int index = 0; index < customers.length; index++) {
      final Customer customer = customers[index];

      rows.add([
        (index + 1).toString(),
        customer.id ?? "N/A",
        customer.name ?? "N/A",
        customer.phoneNumber ?? "N/A",
        customer.address ?? "N/A",
        customer.balance.toStringAsFixed(2),
      ]);
    }

    // Convert to CSV
    String csv = const ListToCsvConverter().convert(rows);

    // Save the CSV file
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/CustomerData_${timestamp}.csv';
    File file = File(path);
    await file.writeAsString(csv);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV exported successfully to $path')),
    );
  }

  static Future<void> exportVendorData(List<Vendor> vendors, BuildContext context) async {
    List<List<dynamic>> rows = [];
    rows.add(['S.No', 'Vendor Id','Vendor Name', 'Contact Number', 'Business Name', 'Address']); // Headers

    for (int index = 0; index < vendors.length; index++) {
      final Vendor vendor = vendors[index];

      rows.add([
        (index + 1).toString(),
        vendor.id ?? "N/A",
        vendor.name ?? "N/A",
        vendor.phoneNumber ?? "N/A",
        vendor.businessName ?? "N/A",
        vendor.address ?? "N/A",
      ]);
    }

    // Convert to CSV
    String csv = const ListToCsvConverter().convert(rows);

    // Save the CSV file
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/VendorData_${timestamp}.csv';
    File file = File(path);
    await file.writeAsString(csv);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV exported successfully to $path')),
    );
  }


  static Future<void> exportCustomerBills(List<Bill> bills, Map<String, Customer>? customers, BuildContext context) async {
    List<List<dynamic>> rows = [];
    rows.add(['S.No', 'Bill ID', 'Customer Name', 'Total Amount', 'Status', 'Bill Type', 'Date', 'Items']); // Headers

    for (int index = 0; index < bills.length; index++) {
      final Bill bill = bills[index];
      final Customer? customer = customers?[bill.customerId];
      final formattedDate = DateFormat('dd-MM-yyyy').format(DateTime.parse(bill.date));

      // Create a list of item details
      String itemDetails = bill.items.map((item) =>
      '${item.name} (Qty: ${item.quantity}, Sale Rate: \$${item.saleRate.toStringAsFixed(2)}, Total: \$${item.total.toStringAsFixed(2)}, Discount: \$${item.itemDiscount.toStringAsFixed(2)})'
      ).join('; '); // Joining multiple items with a semicolon

      rows.add([
        (index + 1).toString(),
        bill.id,
        customer?.name ?? "N/A",
        '\$${bill.totalAmount.toStringAsFixed(2)}',
        bill.status,
        bill.billType,
        formattedDate,
        itemDetails, // Add the concatenated item details here
      ]);
    }

    // Convert to CSV
    String csv = const ListToCsvConverter().convert(rows);

    // Save the CSV file
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/CustomerBills_${timestamp}.csv';
    File file = File(path);
    await file.writeAsString(csv);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV exported successfully to $path')),
    );
  }

  static Future<void> exportVendorBills(List<VendorBill> vendorBills, Map<String, Vendor>? vendors, BuildContext context) async {
    List<List<dynamic>> rows = [];
    rows.add(['S.No', 'Bill ID', 'Vendor Business Name', 'Total Amount', 'Bill Type', 'Date', 'Items']); // Headers

    for (int index = 0; index < vendorBills.length; index++) {
      final VendorBill bill = vendorBills[index];
      final Vendor? vendor = vendors?[bill.vendorId];
      final formattedDate = DateFormat('dd-MM-yyyy').format(DateTime.parse(bill.date));

      // Create a list of item details
      String itemDetails = bill.items.map((item) =>
      '${item.name} (Qty: ${item.quantity}, Sale Rate: \$${item.purchaseRate.toStringAsFixed(2)}, Total: \$${item.total.toStringAsFixed(2)}})'
      ).join('; '); // Joining multiple items with a semicolon

      rows.add([
        (index + 1).toString(),
        bill.id,
        vendor?.businessName ?? "N/A",
        '\$${bill.totalAmount.toStringAsFixed(2)}',
        bill.billType,
        formattedDate,
        itemDetails, // Add the concatenated item details here
      ]);
    }

    // Convert to CSV
    String csv = const ListToCsvConverter().convert(rows);

    // Save the CSV file
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/VendorBills_${timestamp}.csv';
    File file = File(path);
    await file.writeAsString(csv);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV exported successfully to $path')),
    );
  }

  static Future<void> exportItems(List<Item> items, BuildContext context) async {
    List<List<dynamic>> rows = [];
    rows.add(['S.No', 'Name', 'Brand', 'Available Quantity', 'Name in Urdu', 'Mini Unit', 'Packaging', 'Purchase Rate', 'Sale Rate', 'Min Stock', 'Location']); // Headers

    for (int index = 0; index < items.length; index++) {
      final item = items[index];
      rows.add([
        (index + 1).toString(),
        item.name,
        item.brand,
        item.availableQuantity.toString(),
        item.nameInUrdu ?? "N/A",
        item.miniUnit ?? "N/A",
        item.packaging ?? "N/A",
        item.purchaseRate.toString(),
        item.saleRate.toString(),
        item.minStock.toString(),
        item.location ?? "N/A",
      ]);
    }

    // Convert to CSV
    String csv = const ListToCsvConverter().convert(rows);

    // Save the CSV file
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/ItemsData_${timestamp}.csv';
    File file = File(path);
    await file.writeAsString(csv);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV exported successfully to $path')),
    );
  }

  static double _getPreviousRowBalanceCustomer(List<Bill> bills, int index) {
    final Bill previousBill = bills[index];
    final previousDebit = previousBill.billType == "Return Bill" ? previousBill.totalAmount ?? 0.0 : previousBill.amountGiven ?? 0.0;
    final previousCredit = previousBill.billType == "Return Bill" ? previousBill.amountGiven ?? 0.0 : previousBill.totalAmount ?? 0.0;
    double previousBalance = index == 0 ? 0 : _getPreviousRowBalanceCustomer(bills, index - 1);
    return previousBalance + previousCredit - previousDebit;
  }

  static double _getPreviousRowBalanceVendor(List<VendorBill> bills, int index) {
    final VendorBill previousBill = bills[index];
    final previousDebit = previousBill.billType == "Return Bill" ? previousBill.totalAmount ?? 0.0 : previousBill.amountGiven ?? 0.0;
    final previousCredit = previousBill.billType == "Return Bill" ? previousBill.amountGiven ?? 0.0 : previousBill.totalAmount ?? 0.0;
    double previousBalance = index == 0 ? 0 : _getPreviousRowBalanceVendor(bills, index - 1);
    return previousBalance + previousCredit - previousDebit;
  }


}