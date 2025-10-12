from rest_framework import serializers
from .models import Ride, Promotion

class RideSerializer(serializers.ModelSerializer):
    class Meta:
        model = Ride
        fields = [
            'id', 'pickup_location', 'pickup_latitude', 'pickup_longitude',
            'destination_location', 'destination_latitude', 'destination_longitude',
            'ride_type', 'status', 'scheduled_time', 'fare_amount', 'distance_km',
            'duration_minutes', 'driver_name', 'driver_phone', 'vehicle_info',
            'rating', 'feedback', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'user', 'created_at', 'updated_at']

class RideCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Ride
        fields = [
            'pickup_location', 'pickup_latitude', 'pickup_longitude',
            'destination_location', 'destination_latitude', 'destination_longitude',
            'ride_type', 'scheduled_time'
        ]

class PromotionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Promotion
        fields = ['id', 'title', 'description', 'discount_percentage', 'max_rides', 'valid_until']
