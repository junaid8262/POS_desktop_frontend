import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:namer_app/models/vendor.dart';

class VendorService {
  final String apiUrl = 'http://localhost:3000'; // Replace with your actual API URL

  Future<List<Vendor>> getVendors() async {
    final response = await http.get(Uri.parse('$apiUrl/vendors'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((vendor) => Vendor.fromJson(vendor)).toList();
    } else {
      throw Exception('Failed to load vendors');
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

  Future<void> addVendor(Vendor vendor) async {
    final response = await http.post(
      Uri.parse('$apiUrl/vendors'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(vendor.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add vendor');
    }
  }

  Future<void> updateVendor(String id, Vendor vendor) async {
    final response = await http.put(
      Uri.parse('$apiUrl/vendors/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(vendor.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update vendor');
    }
  }

  Future<void> deleteVendor(String id) async {
    final response = await http.delete(Uri.parse('$apiUrl/vendors/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete vendor');
    }
  }

  Future<double> getVendorBalance(String vendorId) async {
    final response = await http.get(Uri.parse('$apiUrl/vendors/$vendorId/balance'));

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      // Ensure the balance is parsed as a double
      return (data['balance'] as num).toDouble();
    } else if (response.statusCode == 404) {
      throw Exception('vendor not found');
    } else {
      throw Exception('Failed to load vendor balance');
    }
  }


}
