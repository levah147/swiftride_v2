from rest_framework import serializers
from django.contrib.auth import authenticate
from .models import User, OTPVerification

class UserRegistrationSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['phone_number', 'first_name', 'last_name']

class OTPVerificationSerializer(serializers.Serializer):
    phone_number = serializers.CharField()
    otp = serializers.CharField(max_length=6)  # Changed from otp_code to otp
    
    def to_internal_value(self, data):
        """Convert 'otp' field to 'otp_code' for internal use"""
        internal_data = super().to_internal_value(data)
        if 'otp' in internal_data:
            internal_data['otp_code'] = internal_data.pop('otp')
        return internal_data

class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            'id', 'phone_number', 'first_name', 'last_name', 
            'email', 'rating', 'total_rides', 'profile_picture',
            'is_driver', 'created_at'
        ]
        read_only_fields = ['id', 'rating', 'total_rides', 'created_at']

class LoginSerializer(serializers.Serializer):
    phone_number = serializers.CharField()
    
    def validate(self, attrs):
        phone_number = attrs.get('phone_number')
        
        if phone_number:
            try:
                user = User.objects.get(phone_number=phone_number)
                if not user.is_phone_verified:
                    raise serializers.ValidationError('Phone number not verified.')
            except User.DoesNotExist:
                raise serializers.ValidationError('User with this phone number does not exist.')
        else:
            raise serializers.ValidationError('Phone number is required.')
        
        attrs['user'] = user
        return attrs