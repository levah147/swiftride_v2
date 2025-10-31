from datetime import timedelta, timezone
from rest_framework import generics, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response

# from backend.rides.views import calculate_distance
from .models import DriverLocation, SavedLocation, RecentLocation
from .serializers import SavedLocationSerializer, RecentLocationSerializer
import requests
from django.conf import settings
from rest_framework.permissions import AllowAny, IsAuthenticated



class SavedLocationListCreateView(generics.ListCreateAPIView):
    serializer_class = SavedLocationSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return SavedLocation.objects.filter(user=self.request.user, is_active=True)
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

class SavedLocationDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = SavedLocationSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return SavedLocation.objects.filter(user=self.request.user)

class RecentLocationListView(generics.ListAPIView):
    serializer_class = RecentLocationSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return RecentLocation.objects.filter(user=self.request.user)[:10]

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_recent_location(request):
    address = request.data.get('address')
    latitude = request.data.get('latitude')
    longitude = request.data.get('longitude')
    
    if not all([address, latitude, longitude]):
        return Response(
            {'error': 'Address, latitude, and longitude are required'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    recent_location, created = RecentLocation.objects.get_or_create(
        user=request.user,
        address=address,
        defaults={
            'latitude': latitude,
            'longitude': longitude
        }
    )
    
    if not created:
        recent_location.search_count += 1
        recent_location.save()
    
    serializer = RecentLocationSerializer(recent_location)
    return Response(serializer.data)




@api_view(['POST'])
@permission_classes([AllowAny])
def detect_city_from_coordinates(request):
    """Detect city using Google Maps Geocoding API"""
    latitude = request.data.get('latitude')
    longitude = request.data.get('longitude')
    
    if not latitude or not longitude:
        return Response(
            {'error': 'latitude and longitude are required'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Call Google Maps Geocoding API
    # TODO: Add your Google Maps API key to settings.py
    api_key = getattr(settings, 'GOOGLE_MAPS_API_KEY', None)
    
    if not api_key:
        return Response(
            {'error': 'Google Maps API key not configured'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
    
    url = f"https://maps.googleapis.com/maps/api/geocode/json?latlng={latitude},{longitude}&key={api_key}"
    
    try:
        response = requests.get(url)
        data = response.json()
        
        if data['status'] == 'OK' and data['results']:
            # Extract city from address components
            for component in data['results'][0]['address_components']:
                if 'locality' in component['types']:
                    city = component['long_name']
                    return Response({
                        'city': city,
                        'formatted_address': data['results'][0]['formatted_address']
                    })
        
        return Response(
            {'error': 'Could not detect city'},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
        
        
        


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def update_driver_location(request):
    """Update driver's current location"""
    try:
        driver = request.user.driver_profile
    except:
        return Response({'error': 'Only drivers can update location'}, status=403)
    
    lat = request.data.get('latitude')
    lon = request.data.get('longitude')
    
    if not lat or not lon:
        return Response({'error': 'latitude and longitude required'}, status=400)
    
    location, created = DriverLocation.objects.update_or_create(
        driver=driver,
        defaults={
            'latitude': lat,
            'longitude': lon,
            'bearing': request.data.get('bearing'),
            'speed_kmh': request.data.get('speed_kmh'),
            'accuracy_meters': request.data.get('accuracy_meters'),
        }
    )
    
    return Response({
        'success': True,
        'message': 'Location updated'
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_nearby_drivers(request):
    """Get nearby online drivers"""
    lat = request.query_params.get('latitude')
    lon = request.query_params.get('longitude')
    radius_km = float(request.query_params.get('radius', 10))
    
    if not lat or not lon:
        return Response({'error': 'latitude and longitude required'}, status=400)
    
    # Get online drivers with recent location updates
    cutoff_time = timezone.now() - timedelta(minutes=5)
    nearby_drivers = DriverLocation.objects.filter(
        driver__status='approved',
        driver__is_online=True,
        driver__is_available=True,
        last_updated__gte=cutoff_time
    ).select_related('driver__user')
    
    # Filter by distance (implement haversine or use PostGIS)
    results = []
    for driver_loc in nearby_drivers:
        distance = calculate_distance(
            float(lat), float(lon),
            float(driver_loc.latitude), float(driver_loc.longitude)
        )
        if distance <= radius_km:
            results.append({
                'driver_id': driver_loc.driver.id,
                'driver_name': driver_loc.driver.user.get_full_name(),
                'latitude': float(driver_loc.latitude),
                'longitude': float(driver_loc.longitude),
                'distance_km': round(distance, 2),
                'rating': float(driver_loc.driver.rating)
            })
    
    return Response(results)