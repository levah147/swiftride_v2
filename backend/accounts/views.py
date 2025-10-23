from rest_framework import status, generics
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework_simplejwt.tokens import RefreshToken
from django.utils import timezone
from datetime import timedelta
import random
import string

from .models import User, OTPVerification
# from locations.models import SavedLocation

from .serializers import (
    UserRegistrationSerializer, 
    OTPVerificationSerializer,
    UserProfileSerializer,
    UserProfileUpdateSerializer,
    LoginSerializer
)
# from locations.serializers import SavedLocationSerializer


@api_view(['POST'])
@permission_classes([AllowAny])
def send_otp(request):
    """Send OTP to phone number for verification"""
    phone_number = request.data.get('phone_number')
    
    if not phone_number:
        return Response({'error': 'Phone number is required'}, status=status.HTTP_400_BAD_REQUEST)
    
    # Normalize phone number before processing
    phone_number = User.objects.normalize_phone_number(phone_number)
    
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
    
    # Print OTP to terminal for testing (PRODUCTION READY FOR DEVELOPMENT)
    print("\n" + "="*60)
    print(f"🔐 OTP REQUEST")
    print(f"Phone Number: {phone_number}")
    print(f"OTP Code: {otp_code}")
    print(f"Expires At: {otp_record.expires_at.strftime('%Y-%m-%d %H:%M:%S')}")
    print("="*60 + "\n")
    
    # TODO: In production, integrate with SMS service (Twilio, Africa's Talking, etc.)
    # Example:
    # from twilio.rest import Client
    # client = Client(account_sid, auth_token)
    # message = client.messages.create(
    #     body=f"Your SwiftRide verification code is: {otp_code}",
    #     from_='+1234567890',
    #     to=phone_number
    # )
    
    return Response({
        'message': 'OTP sent successfully',
        'expires_in': 600  # 10 minutes in seconds
    }, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([AllowAny])
def verify_otp(request):
    """Verify OTP and create/login user"""
    print("\n" + "="*60)
    print(f"🔥 VERIFY OTP REQUEST DATA:")
    print(f"Raw request data: {request.data}")
    print("="*60 + "\n")
    
    serializer = OTPVerificationSerializer(data=request.data)
    
    if not serializer.is_valid():
        print("\n" + "="*60)
        print(f"❌ SERIALIZER VALIDATION FAILED")
        print(f"Errors: {serializer.errors}")
        print("="*60 + "\n")
    
    if serializer.is_valid():
        phone_number = serializer.validated_data['phone_number']
        otp_code = serializer.validated_data['otp_code']
        
        # Normalize phone number before database lookup
        phone_number = User.objects.normalize_phone_number(phone_number)
        
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
            
            # Print verification success to terminal
            print("\n" + "="*60)
            print(f"✅ OTP VERIFICATION SUCCESS")
            print(f"Phone Number: {phone_number}")
            print(f"User Created: {'Yes' if created else 'No (Existing User)'}")
            print(f"User ID: {user.id}")
            print("="*60 + "\n")
            
            # Generate JWT tokens
            refresh = RefreshToken.for_user(user)
            
            return Response({
                'message': 'OTP verified successfully',
                'user_created': created,
                'tokens': {
                    'refresh': str(refresh),
                    'access': str(refresh.access_token),
                },
                'user': UserProfileSerializer(user, context={'request': request}).data
            }, status=status.HTTP_200_OK)
            
        except OTPVerification.DoesNotExist:
            # Print verification failure to terminal
            print("\n" + "="*60)
            print(f"❌ OTP VERIFICATION FAILED")
            print(f"Phone Number: {phone_number}")
            print(f"OTP Code: {otp_code}")
            print(f"Reason: Invalid or expired OTP")
            print("="*60 + "\n")
            
            return Response({
                'error': 'Invalid or expired OTP'
            }, status=status.HTTP_400_BAD_REQUEST)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class UserProfileView(generics.RetrieveAPIView):
    """Retrieve current user's profile"""
    serializer_class = UserProfileSerializer
    permission_classes = [IsAuthenticated]
    
    def get_object(self):
        return self.request.user


class UserProfileUpdateView(generics.UpdateAPIView):
    """Update current user's profile including profile picture upload"""
    serializer_class = UserProfileUpdateSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = (MultiPartParser, FormParser)
    
    def get_object(self):
        return self.request.user
    
    def perform_update(self, serializer):
        serializer.save()
    
    def update(self, request, *args, **kwargs):
        """Override update to return full user profile after update"""
        response = super().update(request, *args, **kwargs)
        user = self.get_object()
        user.refresh_from_db()
        response.data = UserProfileSerializer(user, context={'request': request}).data
        return response


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout(request):
    """
    Logout endpoint - invalidates user session.
    Note: With JWT tokens, you may want to implement token blacklist.
    """
    return Response({
        'message': 'Logout successful'
    }, status=status.HTTP_200_OK)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_account(request):
    """
    Delete user account permanently.
    WARNING: This action cannot be undone.
    """
    user = request.user
    phone_number = user.phone_number
    user.delete()
    
    return Response({
        'message': 'Account deleted successfully',
        'deleted_phone_number': phone_number
    }, status=status.HTTP_200_OK)


# class SavedLocationListCreateView(generics.ListCreateAPIView):
#     """List and create saved locations for current user"""
#     serializer_class = SavedLocationSerializer
#     permission_classes = [IsAuthenticated]
    
#     def get_queryset(self):
#         return SavedLocation.objects.filter(user=self.request.user)
    
#     def perform_create(self, serializer):
#         serializer.save(user=self.request.user)


# class SavedLocationDetailView(generics.RetrieveUpdateDestroyAPIView):
#     """Retrieve, update, or delete a specific saved location"""
#     serializer_class = SavedLocationSerializer
#     permission_classes = [IsAuthenticated]
    
#     def get_queryset(self):
#         return SavedLocation.objects.filter(user=self.request.user)