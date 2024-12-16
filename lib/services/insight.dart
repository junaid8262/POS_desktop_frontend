import 'package:namer_app/models/bills.dart';
import 'package:namer_app/models/vendor_bills.dart';
import 'package:namer_app/services/bills.dart';
import 'package:namer_app/services/vendor_bills.dart';
import 'dart:async';

class InsightService {
  final BillService _billService = BillService();
  final VendorBillService _vendorBillService = VendorBillService();

  Future<List<ProfitData>> getProfitData() async {
    final List<Bill> salesBills = await _billService.getBills();
    final List<VendorBill> purchaseBills = await _vendorBillService.getVendorBills();

    // Create a map to store the total sales and purchase amounts for each date
    Map<DateTime, double> salesMap = {};
    Map<DateTime, double> purchaseMap = {};

    // Populate salesMap
    for (var bill in salesBills) {
      DateTime salesDate = DateTime.parse(bill.date).toLocal();
      salesDate = DateTime(salesDate.year, salesDate.month, salesDate.day); // Removing time part
      salesMap[salesDate] = (salesMap[salesDate] ?? 0) + bill.totalAmount;
    }

    // Populate purchaseMap
    for (var bill in purchaseBills) {
      DateTime purchaseDate = DateTime.parse(bill.date).toLocal();
      purchaseDate = DateTime(purchaseDate.year, purchaseDate.month, purchaseDate.day); // Removing time part
      purchaseMap[purchaseDate] = (purchaseMap[purchaseDate] ?? 0) + bill.totalAmount;
    }

    // Calculate profit data by iterating over salesMap
    List<ProfitData> profitData = [];
    salesMap.forEach((date, salesAmount) {
      double purchaseAmount = purchaseMap[date] ?? 0.0;
      double profit = salesAmount - purchaseAmount;
      profitData.add(ProfitData(date: date, profit: profit));
    });

    return profitData;
  }

  Future<List<SalesData>> getSalesData() async {
    final List<Bill> salesBills = await _billService.getBills();

    // Using a map to aggregate sales by date
    Map<DateTime, double> salesMap = {};

    for (var bill in salesBills) {
      DateTime billDate = DateTime.parse(bill.date).toLocal();
      billDate = DateTime(billDate.year, billDate.month, billDate.day); // Removing time part
      salesMap[billDate] = (salesMap[billDate] ?? 0) + bill.totalAmount;
    }

    // Convert map to list of SalesData
    List<SalesData> salesData = salesMap.entries.map((entry) {
      return SalesData(date: entry.key, sales: entry.value);
    }).toList();

    return salesData;
  }

  Future<List<PurchaseData>> getPurchaseData() async {
    final List<VendorBill> purchaseBills = await _vendorBillService.getVendorBills();

    // Using a map to aggregate purchases by date
    Map<DateTime, double> purchaseMap = {};

    for (var bill in purchaseBills) {
      DateTime billDate = DateTime.parse(bill.date).toLocal();
      billDate = DateTime(billDate.year, billDate.month, billDate.day); // Removing time part
      purchaseMap[billDate] = (purchaseMap[billDate] ?? 0) + bill.totalAmount;
    }

    // Convert map to list of PurchaseData
    List<PurchaseData> purchaseData = purchaseMap.entries.map((entry) {
      return PurchaseData(date: entry.key, purchase: entry.value);
    }).toList();

    return purchaseData;
  }
}

// Example data models for the graphs
class ProfitData {
  final DateTime date;
  final double profit;

  ProfitData({required this.date, required this.profit});
}

class SalesData {
  final DateTime date;
  final double sales;

  SalesData({required this.date, required this.sales});
}

class PurchaseData {
  final DateTime date;
  final double purchase;

  PurchaseData({required this.date, required this.purchase});
}