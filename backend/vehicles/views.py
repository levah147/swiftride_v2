from rest_framework import generics, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from django.db.models import Q
import math
from decimal import Decimal

from .models import City, VehicleType, VehiclePricing, SurgePricing, FuelPriceAdjustment
from .serializers import (
    CitySerializer, VehicleTypeListSerializer,
    FareCalculationSerializer, FareCalculationResponseSerializer
)

 
class CityListView(generics.ListAPIView):
    """Get all active cities where service is available"""
    serializer_class = CitySerializer
    permission_classes = [AllowAny]
    queryset = City.objects.filter(is_active=True)


@api_view(['POST'])
@permission_classes([AllowAny])
def detect_city(request):
    """Detect city from coordinates using reverse geocoding"""
    latitude = request.data.get('latitude')
    longitude = request.data.get('longitude')
    
    if not latitude or not longitude:
        return Response(
            {'error': 'latitude and longitude are required'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # TODO: Implement Google Maps reverse geocoding
    # For now, return nearest city by coordinates
    lat = float(latitude)
    lon = float(longitude)
    
    # Find nearest city
    cities = City.objects.filter(is_active=True)
    nearest_city = None
    min_distance = float('inf')
    
    for city in cities:
        if city.latitude and city.longitude:
            distance = calculate_distance(
                lat, lon,
                float(city.latitude), float(city.longitude)
            )
            if distance < min_distance:
                min_distance = distance
                nearest_city = city
    
    if nearest_city:
        serializer = CitySerializer(nearest_city)
        return Response(serializer.data)
    
    return Response(
        {'error': 'No service available in your area'},
        status=status.HTTP_404_NOT_FOUND
    )


@api_view(['GET'])
@permission_classes([AllowAny])
def get_available_vehicles(request):
    """Get available vehicle types for a city"""
    city_name = request.query_params.get('city')
    
    if not city_name:
        return Response(
            {'error': 'city parameter is required'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        city = City.objects.get(name__iexact=city_name, is_active=True)
    except City.DoesNotExist:
        return Response(
            {'error': f'City {city_name} not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    
    # Filter vehicles by city availability
    vehicle_ids = []
    if city.has_bike:
        vehicle_ids.append('bike')
    if city.has_keke:
        vehicle_ids.append('keke')
    if city.has_car:
        vehicle_ids.append('car')
    if city.has_suv:
        vehicle_ids.append('suv')
    
    vehicles = VehicleType.objects.filter(
        id__in=vehicle_ids,
        is_active=True
    )
    
    serializer = VehicleTypeListSerializer(
        vehicles,
        many=True,
        context={'city': city, 'request': request}
    )
    
    return Response({
        'city': city.name,
        'vehicles': serializer.data
    })


@api_view(['POST'])
@permission_classes([AllowAny])
def calculate_fare(request):
    """Calculate fare for a ride"""
    serializer = FareCalculationSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    
    data = serializer.validated_data
    
    # Calculate distance
    distance_km = calculate_distance(
        float(data['pickup_latitude']),
        float(data['pickup_longitude']),
        float(data['destination_latitude']),
        float(data['destination_longitude'])
    )
    
    # Estimate duration (rough: 30 km/h average speed)
    duration_minutes = int((distance_km / 30) * 60)
    
    # Get city
    city = None
    if data.get('city_name'):
        try:
            city = City.objects.get(name__iexact=data['city_name'], is_active=True)
        except City.DoesNotExist:
            pass
    
    # Get vehicle pricing
    vehicle_type = VehicleType.objects.get(id=data['vehicle_type'])
    pricing = vehicle_type.get_base_pricing(city)
    
    if not pricing:
        return Response(
            {'error': 'Pricing not available for this vehicle'},
            status=status.HTTP_404_NOT_FOUND
        )
    
    # Calculate base fare
    base_fare = pricing.base_fare
    distance_fare = pricing.price_per_km * Decimal(str(distance_km))
    time_fare = pricing.price_per_minute * Decimal(str(duration_minutes))
    
    # Get surge multiplier
    surge_multiplier = Decimal(str(SurgePricing.get_current_multiplier(city)))
    
    # Get fuel adjustment
    fuel_adjustment = Decimal('0.00')
    if city:
        fuel_adj = FuelPriceAdjustment.objects.filter(
            city=city,
            is_active=True
        ).first()
        if fuel_adj:
            fuel_adjustment = fuel_adj.calculate_adjustment() * Decimal(str(distance_km))
    
    # Calculate subtotal
    subtotal = base_fare + distance_fare + time_fare + fuel_adjustment
    
    # Apply surge
    total_fare = subtotal * surge_multiplier
    
    # Ensure minimum fare
    total_fare = max(total_fare, pricing.minimum_fare)
    
    response_data = {
        'vehicle_type': vehicle_type.name,
        'distance_km': round(distance_km, 2),
        'estimated_duration_minutes': duration_minutes,
        'base_fare': float(base_fare),
        'distance_fare': float(distance_fare),
        'time_fare': float(time_fare),
        'surge_multiplier': float(surge_multiplier),
        'fuel_adjustment': float(fuel_adjustment),
        'subtotal': float(subtotal),
        'total_fare': float(total_fare),
        'currency': 'NGN',
        'breakdown': {
            'base': f'₦{base_fare}',
            'distance': f'₦{distance_fare:.2f} ({distance_km:.1f} km × ₦{pricing.price_per_km})',
            'time': f'₦{time_fare:.2f} ({duration_minutes} min × ₦{pricing.price_per_minute})',
            'surge': f'{surge_multiplier}x',
            'fuel': f'₦{fuel_adjustment:.2f}',
            'total': f'₦{total_fare:.2f}'
        }
    }
    
    return Response(response_data)


def calculate_distance(lat1, lon1, lat2, lon2):
    """Calculate distance between two points using Haversine formula"""
    R = 6371  # Earth radius in km
    
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    
    a = (math.sin(dlat / 2) ** 2 + 
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * 
         math.sin(dlon / 2) ** 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    distance = R * c
    
    return distance