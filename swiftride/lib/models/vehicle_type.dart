import 'package:flutter/material.dart';

class VehicleType {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final double basePrice; // Base fare in Naira
  final double pricePerKm; // Price per kilometer
  final String estimatedTime;
  final bool available;

  VehicleType({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.basePrice,
    required this.pricePerKm,
    required this.estimatedTime,
    this.available = true,
  });

  // Calculate estimated fare
  double calculateFare(double distanceKm) {
    return basePrice + (pricePerKm * distanceKm);
  }

  // Format price for display
  String formatPrice(double amount) {
    return '₦${amount.toStringAsFixed(0)}';
  }

  // Get formatted base price
  String get formattedBasePrice => formatPrice(basePrice);

  // From JSON (for API response)
  factory VehicleType.fromJson(Map<String, dynamic> json) {
    return VehicleType(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: _getIconFromString(json['icon_name'] ?? 'car'),
      color: _getColorFromString(json['color'] ?? '#0066FF'),
      basePrice: (json['base_price'] ?? 0).toDouble(),
      pricePerKm: (json['price_per_km'] ?? 0).toDouble(),
      estimatedTime: json['estimated_time'] ?? 'N/A',
      available: json['available'] ?? true,
    );
  }

  // To JSON (for API request)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'base_price': basePrice,
      'price_per_km': pricePerKm,
      'estimated_time': estimatedTime,
      'available': available,
    };
  }

  // Helper to convert string to IconData
  static IconData _getIconFromString(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'bike':
      case 'motorcycle':
        return Icons.two_wheeler;
      case 'keke':
      case 'tricycle':
      case 'rickshaw':
        return Icons.electric_rickshaw;
      case 'car':
        return Icons.directions_car;
      case 'suv':
      case 'van':
        return Icons.airport_shuttle;
      default:
        return Icons.directions_car;
    }
  }

  // Helper to convert hex string to Color
  static Color _getColorFromString(String colorHex) {
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return const Color(0xFF0066FF); // Default blue
    }
  }

  // Copy with method
  VehicleType copyWith({
    String? id,
    String? name,
    String? description,
    IconData? icon,
    Color? color,
    double? basePrice,
    double? pricePerKm,
    String? estimatedTime,
    bool? available,
  }) {
    return VehicleType(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      basePrice: basePrice ?? this.basePrice,
      pricePerKm: pricePerKm ?? this.pricePerKm,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      available: available ?? this.available,
    );
  }

  @override
  String toString() {
    return 'VehicleType(id: $id, name: $name, basePrice: ₦$basePrice)';
  }
}

// Predefined vehicle types for different cities
class VehicleTypes {
  // Makurdi vehicles (all types available)
  static List<VehicleType> makurdiVehicles() {
    return [
      VehicleType(
        id: 'bike',
        name: 'Bike',
        description: 'Fast & affordable',
        icon: Icons.two_wheeler,
        color: const Color(0xFFFF6B35), // Vibrant Orange
        basePrice: 200,
        pricePerKm: 50,
        estimatedTime: '5 min',
      ),
      VehicleType(
        id: 'keke',
        name: 'Keke',
        description: 'Comfortable tricycle',
        icon: Icons.electric_rickshaw,
        color: const Color(0xFFFFC107), // Bright Yellow
        basePrice: 300,
        pricePerKm: 70,
        estimatedTime: '7 min',
      ),
      VehicleType(
        id: 'car',
        name: 'Car',
        description: 'Private comfortable ride',
        icon: Icons.directions_car,
        color: const Color(0xFF0066FF), // Electric Blue
        basePrice: 500,
        pricePerKm: 100,
        estimatedTime: '8 min',
      ),
      VehicleType(
        id: 'suv',
        name: 'SUV',
        description: 'Premium spacious ride',
        icon: Icons.airport_shuttle,
        color: const Color(0xFF7C3AED), // Premium Purple
        basePrice: 800,
        pricePerKm: 150,
        estimatedTime: '10 min',
      ),
    ];
  }

  // Lagos/Abuja vehicles (no bikes/keke)
  static List<VehicleType> restrictedCityVehicles() {
    return [
      VehicleType(
        id: 'car',
        name: 'Car',
        description: 'Private comfortable ride',
        icon: Icons.directions_car,
        color: const Color(0xFF0066FF),
        basePrice: 800,
        pricePerKm: 150,
        estimatedTime: '8 min',
      ),
      VehicleType(
        id: 'suv',
        name: 'SUV',
        description: 'Premium spacious ride',
        icon: Icons.airport_shuttle,
        color: const Color(0xFF7C3AED),
        basePrice: 1200,
        pricePerKm: 200,
        estimatedTime: '10 min',
      ),
    ];
  }

  // Get vehicles based on city
  static List<VehicleType> getVehiclesForCity(String city) {
    // Cities where bikes/keke are banned
    final restrictedCities = ['lagos', 'abuja'];
    
    final cityLower = city.toLowerCase();
    
    if (restrictedCities.any((c) => cityLower.contains(c))) {
      return restrictedCityVehicles();
    }
    
    // Default: all vehicles available
    return makurdiVehicles();
  }
}