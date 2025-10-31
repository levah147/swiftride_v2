
"""
FILE LOCATION: safety/serializers.py
"""
from rest_framework import serializers
from .models import EmergencySOS, TripShare, EmergencyContact, SafetyCheck


class EmergencySOSSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmergencySOS
        fields = '__all__'
        read_only_fields = ['user', 'created_at', 'resolved_at']


class TripShareSerializer(serializers.ModelSerializer):
    class Meta:
        model = TripShare
        fields = '__all__'
        read_only_fields = ['user', 'share_link', 'created_at']


class EmergencyContactSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmergencyContact
        fields = '__all__'
        read_only_fields = ['user', 'created_at']


class SafetyCheckSerializer(serializers.ModelSerializer):
    class Meta:
        model = SafetyCheck
        fields = '__all__'


