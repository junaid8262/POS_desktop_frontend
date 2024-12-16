import 'dart:io';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/businessInfo.dart';

class BusinessDetailsService {
  final String apiUrl = 'http://localhost:3000/businessDetails';

  // Get all business details
  Future<List<BusinessDetails>> getBusinessDetails() async {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((detail) => BusinessDetails.fromJson(detail)).toList();
    } else {
      throw Exception('Failed to load business details');
    }
  }

  // Get a single business detail by ID
  Future<BusinessDetails> getBusinessDetailById(String id) async {
    final response = await http.get(Uri.parse('$apiUrl/$id'));
    if (response.statusCode == 200) {
      return BusinessDetails.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load business detail');
    }
  }

  // Create a new business detail
  Future<void> createBusinessDetail(BusinessDetails businessDetail) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(businessDetail.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create business detail');
    }
  }

  // Update a business detail by ID
  Future<void> updateBusinessDetail(String id, BusinessDetails businessDetail) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.put(
      Uri.parse('$apiUrl/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': '${prefs.get('token')}'
      },
      body: json.encode(businessDetail.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update business detail');
    }
  }

  // Delete a business detail by ID
  Future<void> deleteBusinessDetail(String id) async {
    final response = await http.delete(Uri.parse('$apiUrl/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete business detail');
    }
  }

  // Update company logo
  Future<void> updateCompanyLogo(String id, String newLogo) async {
    final response = await http.put(
      Uri.parse('$apiUrl/$id/logo'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'companyLogo': newLogo}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update company logo');
    }
  }

  // Update company address
  Future<void> updateCompanyAddress(String id, String newAddress) async {
    final response = await http.put(
      Uri.parse('$apiUrl/$id/address'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'companyAddress': newAddress}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update company address');
    }
  }

  // Update company phone number
  Future<void> updateCompanyPhoneNo(String id, String newPhoneNo) async {
    final response = await http.put(
      Uri.parse('$apiUrl/$id/phone'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'companyPhoneNo': newPhoneNo}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update company phone number');
    }
  }

  Future<String> uploadImage(File image) async {
    final request = http.MultipartRequest('POST', Uri.parse('http://localhost:3000/upload'));
    request.files.add(await http.MultipartFile.fromPath('image', image.path));
    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);
      return jsonData['url'];
    } else {
      print(response.reasonPhrase);
      throw Exception('Failed to upload image');
    }
  }
}
