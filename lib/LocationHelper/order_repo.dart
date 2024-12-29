// lib/repositories/order_repository.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Models/delivery_status_enum.dart';
import '../Models/model_location.dart';
import '../Models/model_tracking_info.dart';

class OrderRepository {
  static const String _baseUrl = 'YOUR_API_BASE_URL'; // Replace with your API URL

  Future<TrackingInfo> getTrackingInfo(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/orders/$orderId/tracking'),
        headers: {
          'Content-Type': 'application/json',
          // Add any required authentication headers
          // 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        return TrackingInfo(
          pickupLocation: LocationPoint(
            latitude: data['pickup_location']['latitude'],
            longitude: data['pickup_location']['longitude'],
          ),
          dropOffLocation: LocationPoint(
            latitude: data['dropoff_location']['latitude'],
            longitude: data['dropoff_location']['longitude'],
          ),
          currentLocation: data['current_location'] != null
              ? LocationPoint(
            latitude: data['current_location']['latitude'],
            longitude: data['current_location']['longitude'],
          )
              : null,
          status: _parseDeliveryStatus(data['status']),
        );
      } else {
        throw Exception('Failed to get tracking info: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting tracking info: $e');
    }
  }

  DeliveryStatus _parseDeliveryStatus(String status) {
    switch (status.toLowerCase()) {
      case 'preparing':
        return DeliveryStatus.preparing;
      case 'on_the_way':
        return DeliveryStatus.onTheWay;
      case 'delivered':
        return DeliveryStatus.delivered;
      default:
        return DeliveryStatus.preparing;
    }
  }

  // Optional: Method to update delivery status
  Future<void> updateDeliveryStatus(String orderId, DeliveryStatus status) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/orders/$orderId/status'),
        headers: {
          'Content-Type': 'application/json',
          // Add any required authentication headers
        },
        body: json.encode({
          'status': status.toString().split('.').last,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating status: $e');
    }
  }
}