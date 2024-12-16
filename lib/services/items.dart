import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:namer_app/models/item.dart';

class ItemService {
  final String _baseUrl = 'http://localhost:3000';

  Future<List<Item>> getItems() async {
    final response = await http.get(Uri.parse('$_baseUrl/items'));
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((item) => Item.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load items');
    }
  }

  Future<Item> getItem(String id) async {
    final response = await http.get(Uri.parse('$_baseUrl/items/$id'));

    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, parse the JSON.
      return Item.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      // If the item is not found, throw an exception or handle it.
      throw Exception('Item not found');
    } else {
      // If the server returns any other error, throw an exception.
      throw Exception('Failed to load item');
    }
  }

  Future<void> addItem(Item item) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/items'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(item.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add item');
    }
  }

  Future<void> updateItem(String id, Item item) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/items/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(item.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update item');
    }
  }

  Future<void> deleteItem(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/items/$id'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete item');
    }
  }

  Future<String> uploadImage(File image) async {
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/upload'));
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
