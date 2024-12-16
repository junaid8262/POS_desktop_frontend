import 'package:namer_app/models/vendor_bills.dart';
import 'package:namer_app/models/vendor.dart';
import 'package:namer_app/models/item.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';


class VendorBillService {
  final String apiUrl = 'http://localhost:3000';

  Future<List<VendorBill>> getAllBill() async {
    final response = await http.get(Uri.parse('$apiUrl/vendor-bills/all'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((bill) => VendorBill.fromJson(bill)).toList();
    } else {
      throw Exception('Failed to load all vendor bills');
    }
  }


  Future<List<VendorBill>> getVendorBills() async {
    final response = await http.get(Uri.parse('$apiUrl/vendor-bills'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((bill) => VendorBill.fromJson(bill)).toList();
    } else {
      throw Exception('Failed to load vendor bills');
    }
  }

  Future<void> addVendorBill(VendorBill bill) async {
    final response = await http.post(
      Uri.parse('$apiUrl/vendor-bills'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(bill.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add vendor bill');
    }
  }

  Future<void> updateVendorBill(String id, VendorBill bill) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.put(
      Uri.parse('$apiUrl/vendor-bills/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': '${prefs.get('token')}',
      },
      body: json.encode(bill.toJson()),
    );
    if (response.statusCode != 200) {
      print('error ${response.body}');
      throw Exception('Failed to update vendor bill');
    }
  }

  Future<void> deleteVendorBill(String id) async {
    final response = await http.delete(Uri.parse('$apiUrl/vendor-bills/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete vendor bill');
    }
  }

  Future<Vendor> getVendorById(String id) async {
    final response = await http.get(Uri.parse('$apiUrl/vendors/$id'));
    if (response.statusCode == 200) {
      return Vendor.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load vendor');
    }
  }

  Future<void> updateVendorBillDueDate(String billId, DateTime dueDate) async {
    final response = await http.put(
      Uri.parse('$apiUrl/vendor-bills/$billId/due-date'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'dueDate': dueDate.toIso8601String()}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update due date');
    }
  }

  Future<void> updateVendorBillAmountPaid(String billId, double amountPaid) async {
    final response = await http.put(
      Uri.parse('$apiUrl/vendor-bills/$billId/amount-paid'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'amountPaid': amountPaid}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update amount paid');
    }
  }

  Future<List<Item>> getItems() async {
    final response = await http.get(Uri.parse('$apiUrl/items'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => Item.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load items');
    }
  }

  Future<void> updateItemQuantity(String itemId, int quantity, {bool increase = true}) async {
    final endpoint = increase ? 'increase-quantity' : 'quantity';
    final response = await http.put(
      Uri.parse('$apiUrl/items/$itemId/$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'quantity': quantity}),
    );

    if (response.statusCode != 200) {
      final action = increase ? 'increase' : 'decrease';
      throw Exception('Failed to $action item quantity');
    }
  }

  Future<void> reduceItemsQuantity(List<VendorBillItem> items) async {
    for (var item in items) {
      await updateItemQuantity(item.itemId, item.quantity, increase: false);
    }
  }

  Future<void> increaseVendorBillItemsQuantity(List<VendorBillItem> items) async {
    for (var item in items) {
      await updateItemQuantity(item.itemId, item.quantity, increase: true);
    }
  }

  Future<List<Vendor>> getVendors() async {
    final response = await http.get(Uri.parse('$apiUrl/vendors'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((vendor) => Vendor.fromJson(vendor)).toList();
    } else {
      throw Exception('Failed to load vendors');
    }
  }
  Future<List<VendorBillItem>> getItemRatesById(String itemId) async {
    final response = await http.get(Uri.parse('$apiUrl/items/$itemId/rates'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      print(data);
      return data.map((item) => VendorBillItem.fromJson(item)).toList().reversed.toList();
    } else {
      throw Exception('Failed to load item rates');
    }
  }

  Future<VendorBill?> getVendorBill(String id) async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/vendor-bills/$id'));

      if (response.statusCode == 200) {
        // Parse the JSON response for a single vendor bill object
        dynamic data = json.decode(response.body);
        return VendorBill.fromJson(data);
      } else if (response.statusCode == 404) {
        print('Vendor bill not found');
        return null;
      } else {
        print('Failed to fetch vendor bill with status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error occurred: $e');
      return null;
    }
  }


  Future<List<VendorBill>> getVendorBillsByVendorId(String vendorId) async {
    final response = await http.get(Uri.parse('$apiUrl/vendor-bills?vendorId=$vendorId'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((bill) => VendorBill.fromJson(bill)).toList();
    } else {
      throw Exception('Failed to load vendor bills');
    }
  }

  Future<List<VendorBillItem>> getItemRatesByVendorId(String itemId) async {
    final response = await http.get(Uri.parse('$apiUrl/items/$itemId/vendor-rates'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      print(data);  // Debugging to check the fetched data
      return data.map((item) => VendorBillItem.fromJson(item)).toList().reversed.toList();
    } else {
      throw Exception('Failed to load vendor item rates');
    }
  }

  Future<void> updateVendorBalance(String id, double balance) async {
    final response = await http.put(
      Uri.parse('$apiUrl/vendors/$id/addBalance'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'balance': balance}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to add balance');
    }
  }


}
