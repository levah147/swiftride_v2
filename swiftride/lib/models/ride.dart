enum RideStatus {
  pending,
  driverAssigned,
  driverArriving,
  inProgress,
  completed,
  cancelled,
}

enum RideType {
  swiftGo,
  swiftComfort,
  swiftXL,
}

class Ride {
  final String id;
  final String userId;
  final String? driverId;
  final RideType rideType;
  final RideStatus status;
  final String pickupAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final String destinationAddress;
  final double destinationLatitude;
  final double destinationLongitude;
  final double? fare;
  final double? distance;
  final int? estimatedDuration;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Driver? driver;

  Ride({
    required this.id,
    required this.userId,
    this.driverId,
    required this.rideType,
    required this.status,
    required this.pickupAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.destinationAddress,
    required this.destinationLatitude,
    required this.destinationLongitude,
    this.fare,
    this.distance,
    this.estimatedDuration,
    required this.createdAt,
    this.completedAt,
    this.driver,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      driverId: json['driver_id']?.toString(),
      rideType: _parseRideType(json['ride_type']),
      status: _parseRideStatus(json['status']),
      pickupAddress: json['pickup_address'],
      pickupLatitude: json['pickup_latitude'].toDouble(),
      pickupLongitude: json['pickup_longitude'].toDouble(),
      destinationAddress: json['destination_address'],
      destinationLatitude: json['destination_latitude'].toDouble(),
      destinationLongitude: json['destination_longitude'].toDouble(),
      fare: json['fare']?.toDouble(),
      distance: json['distance']?.toDouble(),
      estimatedDuration: json['estimated_duration'],
      createdAt: DateTime.parse(json['created_at']),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      driver: json['driver'] != null ? Driver.fromJson(json['driver']) : null,
    );
  }

  static RideType _parseRideType(String type) {
    switch (type.toLowerCase()) {
      case 'swift_go':
        return RideType.swiftGo;
      case 'swift_comfort':
        return RideType.swiftComfort;
      case 'swift_xl':
        return RideType.swiftXL;
      default:
        return RideType.swiftGo;
    }
  }

  static RideStatus _parseRideStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return RideStatus.pending;
      case 'driver_assigned':
        return RideStatus.driverAssigned;
      case 'driver_arriving':
        return RideStatus.driverArriving;
      case 'in_progress':
        return RideStatus.inProgress;
      case 'completed':
        return RideStatus.completed;
      case 'cancelled':
        return RideStatus.cancelled;
      default:
        return RideStatus.pending;
    }
  }
}
 
class Driver {
  final String id;
  final String name;
  final String phoneNumber;
  final double rating;
  final String vehicleModel;
  final String vehicleColor;
  final String licensePlate;
  final String? profileImage;

  Driver({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.rating,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.licensePlate,
    this.profileImage,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'].toString(),
      name: json['name'],
      phoneNumber: json['phone_number'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      vehicleModel: json['vehicle_model'],
      vehicleColor: json['vehicle_color'],
      licensePlate: json['license_plate'],
      profileImage: json['profile_image'],
    );
  }
}
