from rest_framework import generics, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from .models import SavedLocation, RecentLocation
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