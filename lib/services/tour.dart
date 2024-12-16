import 'package:namer_app/models/tour.dart'; // Ensure you have a Tour model
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TourService {
  final String apiUrl = 'http://localhost:3000/tour';

  Future<List<Tour>> getTours() async {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((tour) => Tour.fromJson(tour)).toList();
    } else {
      throw Exception('Failed to load tours');
    }
  }

  Future<Tour> getTourById(String id) async {
    final response = await http.get(Uri.parse('$apiUrl/$id'));
    if (response.statusCode == 200) {
      return Tour.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load tour');
    }
  }

  Future<void> createTour(Tour tour) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(tour.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create tour');
    }
  }

  Future<void> updateTour(String id, Tour tour) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.put(
      Uri.parse('$apiUrl/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': '${prefs.get('token')}'
      },
      body: json.encode(tour.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update tour');
    }
  }

  Future<void> deleteTour(String id) async {
    final response = await http.delete(Uri.parse('$apiUrl/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete tour');
    }
  }

  Future<List<Tour>> getToursByDay(String dayOfRoute) async {
    final response = await http.get(Uri.parse('$apiUrl/by-day?dayOfRoute=$dayOfRoute'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((tour) => Tour.fromJson(tour)).toList();
    } else {
      throw Exception('Failed to load tours by day');
    }
  }

  Future<void> addHistory(String tourId, History newHistory) async {
    final response = await http.post(
      Uri.parse('$apiUrl/history/add'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'tourId': tourId, 'newHistory': newHistory}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to add history to tour');
    }
  }

  // New deleteHistory function
  Future<void> deleteHistory(String tourId, History historyToRemove) async {
    final response = await http.delete(
      Uri.parse('$apiUrl/history/delete'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'tourId': tourId, 'historyToRemove': historyToRemove}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete history from tour');
    }
  }

// New function to get the history of a specific tour
  Future<List<dynamic>> getHistoryByTourId(String tourId) async {
    final response = await http.get(Uri.parse('$apiUrl/history/$tourId'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data; // Return the history data
    } else {
      throw Exception('Failed to load history for tour');
    }
  }

// New function to get all tour histories
Future<List<Map<String, dynamic>>> getAllHistory() async {
  final response = await http.get(Uri.parse('$apiUrl/history/all'));
  if (response.statusCode == 200) {
    List<dynamic> data = json.decode(response.body);
    return data.map((item) => item as Map<String, dynamic>).toList(); // Return all history data
  } else {
    throw Exception('Failed to load all tour histories');
  }
}
}
