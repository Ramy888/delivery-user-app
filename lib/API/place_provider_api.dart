import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../Models/suggestion_model.dart';

class PlaceApiProvider {
  static String sessionToken = '';
  // static const apiKey = 'AIzaSyCGA0CAQ2Z_LvRGT34jxE1Ob3wZJ-BcGUc';
  static const apiKey = 'AIzaSyCOPYHD2q4Q0eNvP9xUjM9XTREJcpBu-lY';

  Future<List<Suggestion>> fetchSuggestions(BuildContext context, String query) async {
    List<Suggestion> suggestions = [];
    try {
      final response = await http.get(
        Uri.parse('https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&sessiontoken=$sessionToken&types=establishment&language=ar|en&key=$apiKey'),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final String status = result['status'];

        if (status == 'OK') {
          Iterable jsonList = result['predictions'];
          suggestions = List<Suggestion>.from(jsonList.map((prediction) => Suggestion.fromJson(prediction)));
        } else if (status == 'ZERO_RESULTS') {
          return [];
        }
      }
    } catch (e) {
      debugPrint('Error fetching suggestions: $e');
    }
    return suggestions;
  }

  Future<LatLng> getPlaceDetailFromId(BuildContext context, String placeId) async {
    try {
      final response = await http.get(
        Uri.parse('https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$apiKey&sessiontoken=$sessionToken'),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final String status = result['status'];

        if (status == 'OK') {
          final geometry = result['result']['geometry']['location'];
          final lat = geometry['lat'];
          final lng = geometry['lng'];
          return LatLng(lat, lng);
        }
      }
    } catch (e) {
      debugPrint('Error getting place details: $e');
      // Returning a default LatLng in case of failure. Consider a more graceful error handling approach.
      return LatLng(0.0, 0.0);
    }
    // Returning a default LatLng in case of failure. Consider a more graceful error handling approach.
    return LatLng(0.0, 0.0);
  }
}
