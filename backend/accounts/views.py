from rest_framework import status, generics
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from django.utils import timezone
from datetime import timedelta
import random
import string

from .models import User, OTPVerification
from locations.models import SavedLocation

from .serializers import (
    UserRegistrationSerializer, 
    OTPVerificationSerializer,
    UserProfileSerializer,
    LoginSerializer
)
from locations.serializers import SavedLocationSerializer

@api_view(['POST'])
@permission_classes([AllowAny])
def send_otp(request):
    """Send OTP to phone number for verification"""
    phone_number = request.data.get('phone_number')
    
    if not phone_number:
        return Response({'error': 'Phone number is required'}, status=status.HTTP_400_BAD_REQUEST)
    
    # Generate 6-digit OTP
    otp_code = ''.join(random.choices(string.digits, k=6))
    
    # Create or update OTP record
    otp_record, created = OTPVerification.objects.get_or_create(
        phone_number=phone_number,
        defaults={
            'otp_code': otp_code,
            'expires_at': timezone.now() + timedelta(minutes=10)
        }
    )
    
    if not created:
        otp_record.otp_code = otp_code
        otp_record.expires_at = timezone.now() + timedelta(minutes=10)
        otp_record.is_verified = False
        otp_record.save()
    
    # TODO: Integrate with SMS service (Twilio, etc.)
    # For development, return OTP in response
    return Response({
        'message': 'OTP sent successfully',
        'otp_code': otp_code,  # Remove in production
        'expires_in': 600  # 10 minutes
    }, status=status.HTTP_200_OK)

@api_view(['POST'])
@permission_classes([AllowAny])
def verify_otp(request):
    """Verify OTP and create/login user"""
    serializer = OTPVerificationSerializer(data=request.data)
    
    if serializer.is_valid():
        phone_number = serializer.validated_data['phone_number']
        otp_code = serializer.validated_data['otp_code']
        
        try:
            otp_record = OTPVerification.objects.get(
                phone_number=phone_number,
                otp_code=otp_code,
                is_verified=False,
                expires_at__gt=timezone.now()
            )
            
            # Mark OTP as verified
            otp_record.is_verified = True
            otp_record.save()
            
            # Get or create user
            user, created = User.objects.get_or_create(
                phone_number=phone_number,
                defaults={
                    'is_phone_verified': True,
                    'first_name': 'User',  # Default name
                    'last_name': ''
                }
            )
            
            if not created:
                user.is_phone_verified = True
                user.save()
            
            # Generate JWT tokens
            refresh = RefreshToken.for_user(user)
            
            return Response({
                'message': 'OTP verified successfully',
                'user_created': created,
                'tokens': {
                    'refresh': str(refresh),
                    'access': str(refresh.access_token),
                },
                'user': UserProfileSerializer(user).data
            }, status=status.HTTP_200_OK)
            
        except OTPVerification.DoesNotExist:
            return Response({
                'error': 'Invalid or expired OTP'
            }, status=status.HTTP_400_BAD_REQUEST)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class UserProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = UserProfileSerializer
    permission_classes = [IsAuthenticated]
    
    def get_object(self):
        return self.request.user

class SavedLocationListCreateView(generics.ListCreateAPIView):
    serializer_class = SavedLocationSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return SavedLocation.objects.filter(user=self.request.user)
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
