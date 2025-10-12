from rest_framework import generics, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.utils import timezone
from .models import Ride, Promotion
from .serializers import RideSerializer, RideCreateSerializer, PromotionSerializer

class RideListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return Ride.objects.filter(user=self.request.user)
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return RideCreateSerializer
        return RideSerializer
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

class RideDetailView(generics.RetrieveUpdateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = RideSerializer
    
    def get_queryset(self):
        return Ride.objects.filter(user=self.request.user)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def upcoming_rides(request):
    rides = Ride.objects.filter(
        user=request.user,
        status__in=['pending', 'confirmed'],
        scheduled_time__gte=timezone.now()
    ).order_by('scheduled_time')
    serializer = RideSerializer(rides, many=True)
    return Response(serializer.data)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def past_rides(request):
    rides = Ride.objects.filter(
        user=request.user,
        status__in=['completed', 'cancelled']
    ).order_by('-created_at')
    serializer = RideSerializer(rides, many=True)
    return Response(serializer.data)

class ActivePromotionsView(generics.ListAPIView):
    serializer_class = PromotionSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return Promotion.objects.filter(
            is_active=True,
            valid_from__lte=timezone.now(),
            valid_until__gte=timezone.now()
        )
