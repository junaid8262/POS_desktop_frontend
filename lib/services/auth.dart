import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class AuthService {
  Future<User?> login(String username, String password) async {
    try{
    final url = Uri.parse('${dotenv.env['BACKEND_URL']!}/users/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final token = response.headers['authorization'];
      print ("token is $token");
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token!);
      final Map<String, dynamic> responseBody = json.decode(response.body);
      User user = User(
        email: responseBody['username'],
        password: responseBody['password'],
        role: responseBody['role'],
        id: responseBody['_id'],
      );
      print("user id is ${user.id}");
      print("user role is ${user.role}");
      print("user email is ${user.email}");
      print("user password is ${user.password}");

      //final role = responseBody['role'];

      //await prefs.setString('role', role);
      return user;
    } else {
      // Handle login failure
      return null;
    }
    } catch (e) {
      return null;
    }
  }

  static Future<void> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

}
