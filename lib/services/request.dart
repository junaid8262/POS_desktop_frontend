import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/request.dart';




class RequestService {
  final String _baseUrl = 'http://localhost:3000/request';

  // Create a new request
  Future<Request?> createRequest(String employeeId, String documentType, String documentId) async {
    final url = Uri.parse('$_baseUrl/');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'employeeId': employeeId,
        'documentType': documentType,
        'documentId': documentId,
      }),
    );

    if (response.statusCode == 201) {
      return Request.fromJson(jsonDecode(response.body));
    } else {
      print('Error creating request: ${response.statusCode}');
      return null;
    }
  }

  // Get all pending requests
  Future<List<Request>?> getPendingRequests() async {
    final url = Uri.parse('$_baseUrl/pending');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((json) => Request.fromJson(json)).toList();
    } else {
      print('Error fetching pending requests: ${response.statusCode}');
      return null;
    }
  }

  // Respond to a request (approve or deny)
  Future<bool> respondToRequest(String requestId, String status, String adminResponse) async {
    final url = Uri.parse('$_baseUrl/respond');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'requestId': requestId,
        'status': status,
        'adminResponse': adminResponse,
      }),
    );

    if (response.statusCode == 200) {
      print('Request responded successfully');
      return true;
    } else {
      print('Error responding to request: ${response.statusCode}');
      return false;
    }
  }


// Function to update document status
  Future<Map<String, dynamic>?> performAction(String documentId, String status) async {
    print("document id is $documentId");
    final url = Uri.parse('$_baseUrl/perform/$documentId');

    try {
      // Step 1: Make sure the status is a valid non-empty string
      if (status.isEmpty) {
        print('Invalid status: Status must be a valid non-empty string');
        return {'error': 'Status must be a valid non-empty string'};
      }

      // Step 2: Send the PUT request to update the document status
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );

      // Step 3: Check if document was not found (404)
      if (response.statusCode == 404) {
        print('Document not found');
        return {'error': 'Document not found'};
      }

      // Step 4: Check if there was a server error (500)
      if (response.statusCode == 500) {
        print('Server error: ${response.body}');
        return {'error': 'Server error', 'details': jsonDecode(response.body)['details']};
      }

      // Step 5: Return the updated document if successful
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error updating document: ${response.statusCode}');
        return {'error': 'Failed to update document'};
      }
    } catch (e) {
      print('Error encountered: $e');
      return {'error': 'Server error', 'details': e.toString()};
    }
  }


  Future<Request?> getRequestByEmployeeAndDocument(String employeeId, String documentType, String documentId) async {
    final url = Uri.parse('$_baseUrl/getRequestByEmployeeAndDocument');

    // Assuming the API expects a JSON body with employeeId, documentType, and documentId
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'employeeId': employeeId,
        'documentType': documentType,
        'documentId': documentId,
      }),
    );

    if (response.statusCode == 200) {
      // If the request is successful, parse the JSON response and return a Request object
      return Request.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      print('Request not found');
      return null;
    } else {
      print('Error fetching request by employee and document: ${response.statusCode}');
      return null;
    }
  }


}
