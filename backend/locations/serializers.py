
# location/serializers.py
from rest_framework import serializers
from .models import SavedLocation, RecentLocation

class SavedLocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = SavedLocation
        fields = ['id', 'location_type', 'address', 'latitude', 'longitude', 'created_at', 'updated_at']
        read_only_fields = ['id', 'user', 'created_at', 'updated_at']

class RecentLocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = RecentLocation
        fields = ['id', 'address', 'latitude', 'longitude', 'search_count', 'last_used']
        read_only_fields = ['id', 'user', 'search_count', 'last_used']

