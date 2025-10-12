from rest_framework import generics, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .models import SavedLocation, RecentLocation
from .serializers import SavedLocationSerializer, RecentLocationSerializer

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
