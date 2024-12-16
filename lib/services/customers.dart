import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:namer_app/models/customer.dart';

class CustomerService {
  final String apiUrl = 'http://localhost:3000'; // Replace with your actual API URL

  Future<List<Customer>> getCustomers() async {
    final response = await http.get(Uri.parse('$apiUrl/customers'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((customer) => Customer.fromJson(customer)).toList();
    } else {
      throw Exception('Failed to load customers');
    }
  }

  Future<Customer> getCustomerById(String id) async {
    final response = await http.get(Uri.parse('$apiUrl/customers/$id'));
    if (response.statusCode == 200) {
      return Customer.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load customer');
    }
  }

  Future<void> addCustomer(Customer customer) async {
    final response = await http.post(
      Uri.parse('$apiUrl/customers'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(customer.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add customer');
    }
  }

  Future<void> updateCustomer(String id, Customer customer) async {
    final response = await http.put(
      Uri.parse('$apiUrl/customers/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(customer.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update customer');
    }
  }

  Future<void> deleteCustomer(String id) async {
    final response = await http.delete(Uri.parse('$apiUrl/customers/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete customer');
    }
  }

  Future<double> getCustomerBalance(String customerId) async {
    final response = await http.get(Uri.parse('$apiUrl/customers/$customerId/balance'));

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      // Ensure the balance is parsed as a double
      return (data['balance'] as num).toDouble();
    } else if (response.statusCode == 404) {
      throw Exception('Customer not found');
    } else {
      throw Exception('Failed to load customer balance');
    }
  }

}
