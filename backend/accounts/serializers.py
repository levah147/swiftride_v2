from rest_framework import serializers
from django.contrib.auth import authenticate
from .models import User, OTPVerification

class UserRegistrationSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['phone_number', 'first_name', 'last_name']

class OTPVerificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = OTPVerification
        fields = ['phone_number', 'otp_code']

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
