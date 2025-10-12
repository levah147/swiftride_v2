import '../models/ride.dart';
import 'api_client.dart';

class RideService {
  final ApiClient _apiClient = ApiClient.instance;

  Future<ApiResponse<Ride>> bookRide({
    required String rideType,
    required String pickupAddress,
    required double pickupLatitude,
    required double pickupLongitude,
    required String destinationAddress,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async {
    return await _apiClient.post<Ride>(
      '/rides/',
      {
        'ride_type': rideType,
        'pickup_address': pickupAddress,
        'pickup_latitude': pickupLatitude,
        'pickup_longitude': pickupLongitude,
        'destination_address': destinationAddress,
        'destination_latitude': destinationLatitude,
        'destination_longitude': destinationLongitude,
      },
      fromJson: (json) => Ride.fromJson(json),
    );
  }

  Future<ApiResponse<List<Ride>>> getRideHistory() async {
    return await _apiClient.get<List<Ride>>(
      '/rides/',
      fromJson: (json) => (json as List).map((item) => Ride.fromJson(item)).toList(),
    );
  }

  Future<ApiResponse<Ride>> getRideDetails(String rideId) async {
    return await _apiClient.get<Ride>(
      '/rides/$rideId/',
      fromJson: (json) => Ride.fromJson(json),
    );
  }

  Future<ApiResponse<Ride>> updateRideStatus(String rideId, String status) async {
    return await _apiClient.put<Ride>(
      '/rides/$rideId/',
      {'status': status},
      fromJson: (json) => Ride.fromJson(json),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> cancelRide(String rideId) async {
    return await _apiClient.delete<Map<String, dynamic>>(
      '/rides/$rideId/',
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> rateRide(
    String rideId,
    int rating,
    String? feedback,
  ) async {
    return await _apiClient.post<Map<String, dynamic>>(
      '/rides/$rideId/rate/',
      {
        'rating': rating,
        if (feedback != null) 'feedback': feedback,
      },
    );
  }
 
  Future<ApiResponse<Map<String, dynamic>>> calculateFare({
    required String rideType,
    required double pickupLatitude,
    required double pickupLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async {
    return await _apiClient.post<Map<String, dynamic>>(
      '/rides/calculate-fare/',
      {
        'ride_type': rideType,
        'pickup_latitude': pickupLatitude,
        'pickup_longitude': pickupLongitude,
        'destination_latitude': destinationLatitude,
        'destination_longitude': destinationLongitude,
      },
    );
  }
}
