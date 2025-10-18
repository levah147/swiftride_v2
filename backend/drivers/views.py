from rest_framework import status, generics, viewsets
from rest_framework.decorators import api_view, permission_classes, action
from rest_framework.permissions import AllowAny, IsAuthenticated, IsAdminUser
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.db.models import Q

from .models import Driver, DriverVerificationDocument, VehicleImage, DriverRating
from accounts.models import User
from .serializers import (
    DriverApplicationSerializer,
    DriverProfileSerializer,
    DriverStatusSerializer,
    AdminDriverApprovalSerializer,
    DriverVerificationDocumentSerializer,
    VehicleImageSerializer,
    DriverRatingSerializer
)


class DriverApplicationView(generics.CreateAPIView):
    """Apply to become a driver"""
    serializer_class = DriverApplicationSerializer
    permission_classes = [IsAuthenticated]
    
    def create(self, request, *args, **kwargs):
        # Check if user already has a driver application
        if hasattr(request.user, 'driver_profile'):
            return Response(
                {'error': 'You already have a driver application pending or approved.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        # Create driver profile
        driver = Driver.objects.create(
            user=request.user,
            **serializer.validated_data
        )
        
        return Response(
            DriverProfileSerializer(driver, context={'request': request}).data,
            status=status.HTTP_201_CREATED
        )


class DriverProfileView(generics.RetrieveUpdateAPIView):
    """Get/update current user's driver profile"""
    serializer_class = DriverProfileSerializer
    permission_classes = [IsAuthenticated]
    
    def get_object(self):
        try:
            return self.request.user.driver_profile
        except Driver.DoesNotExist:
            return None
    
    def retrieve(self, request, *args, **kwargs):
        driver = self.get_object()
        if driver is None:
            return Response(
                {'error': 'You do not have a driver profile.'},
                status=status.HTTP_404_NOT_FOUND
            )
        serializer = self.get_serializer(driver)
        return Response(serializer.data)
    
    def update(self, request, *args, **kwargs):
        driver = self.get_object()
        if driver is None:
            return Response(
                {'error': 'You do not have a driver profile.'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Prevent updating sensitive fields
        if 'status' in request.data or 'background_check_passed' in request.data:
            return Response(
                {'error': 'You cannot update status or background check status.'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        serializer = self.get_serializer(driver, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        
        return Response(serializer.data)


class UploadVerificationDocumentView(generics.CreateAPIView):
    """Upload driver verification documents"""
    serializer_class = DriverVerificationDocumentSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = (MultiPartParser, FormParser)
    
    def create(self, request, *args, **kwargs):
        try:
            driver = request.user.driver_profile
        except Driver.DoesNotExist:
            return Response(
                {'error': 'You do not have a driver profile.'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        document_type = request.data.get('document_type')
        if not document_type:
            return Response(
                {'error': 'document_type is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Delete existing document of same type
        DriverVerificationDocument.objects.filter(
            driver=driver,
            document_type=document_type
        ).delete()
        
        # Create new document
        try:
            doc = DriverVerificationDocument.objects.create(
                driver=driver,
                document_type=document_type,
                document=request.FILES.get('document')
            )
            
            return Response(
                DriverVerificationDocumentSerializer(doc, context={'request': request}).data,
                status=status.HTTP_201_CREATED
            )
        except Exception as e:
            return Response(
                {'error': f'Failed to upload document: {str(e)}'},
                status=status.HTTP_400_BAD_REQUEST
            )


class UploadVehicleImageView(generics.CreateAPIView):
    """Upload vehicle images"""
    serializer_class = VehicleImageSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = (MultiPartParser, FormParser)
    
    def create(self, request, *args, **kwargs):
        try:
            driver = request.user.driver_profile
        except Driver.DoesNotExist:
            return Response(
                {'error': 'You do not have a driver profile.'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        image_type = request.data.get('image_type')
        if not image_type:
            return Response(
                {'error': 'image_type is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Delete existing image of same type
        VehicleImage.objects.filter(
            driver=driver,
            image_type=image_type
        ).delete()
        
        # Create new image
        try:
            image = VehicleImage.objects.create(
                driver=driver,
                image_type=image_type,
                image=request.FILES.get('image')
            )
            
            return Response(
                VehicleImageSerializer(image, context={'request': request}).data,
                status=status.HTTP_201_CREATED
            )
        except Exception as e:
            return Response(
                {'error': f'Failed to upload image: {str(e)}'},
                status=status.HTTP_400_BAD_REQUEST
            )


class DriverStatusView(generics.RetrieveAPIView):
    """Check if current user is a driver and their status"""
    permission_classes = [IsAuthenticated]
    
    def retrieve(self, request, *args, **kwargs):
        try:
            driver = request.user.driver_profile
            serializer = DriverStatusSerializer(driver)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Driver.DoesNotExist:
            # User doesn't have a driver profile yet
            return Response(
                {'is_driver': False},
                status=status.HTTP_200_OK
            )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_driver_documents_status(request):
    """Get status of all driver documents (how many verified)"""
    try:
        driver = request.user.driver_profile
        total_docs = driver.verification_documents.count()
        verified_docs = driver.verification_documents.filter(is_verified=True).count()
        total_images = driver.vehicle_images.count()
        
        return Response({
            'total_documents': total_docs,
            'verified_documents': verified_docs,
            'total_vehicle_images': total_images,
            'all_documents_verified': total_docs > 0 and verified_docs == total_docs,
            'documents': DriverVerificationDocumentSerializer(
                driver.verification_documents.all(),
                many=True,
                context={'request': request}
            ).data
        }, status=status.HTTP_200_OK)
    except Driver.DoesNotExist:
        return Response(
            {'error': 'You do not have a driver profile.'},
            status=status.HTTP_404_NOT_FOUND
        )


# ==================== ADMIN VIEWS ====================

class AdminDriverListView(generics.ListAPIView):
    """Admin: List all driver applications"""
    serializer_class = AdminDriverApprovalSerializer
    permission_classes = [IsAdminUser]
    
    def get_queryset(self):
        status_filter = self.request.query_params.get('status')
        queryset = Driver.objects.all()
        
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        return queryset.order_by('-created_at')


class AdminApproveDriverView(generics.UpdateAPIView):
    """Admin: Approve driver application"""
    serializer_class = AdminDriverApprovalSerializer
    permission_classes = [IsAdminUser]
    queryset = Driver.objects.all()
    
    def update(self, request, *args, **kwargs):
        driver = self.get_object()
        
        if driver.status != 'pending':
            return Response(
                {'error': 'Only pending applications can be approved.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        driver.status = 'approved'
        driver.approved_by = request.user
        driver.approved_date = timezone.now()
        driver.save()
        
        # Update user's is_driver flag
        driver.user.is_driver = True
        driver.user.save()
        
        return Response(
            AdminDriverApprovalSerializer(driver, context={'request': request}).data,
            status=status.HTTP_200_OK
        )


class AdminRejectDriverView(generics.UpdateAPIView):
    """Admin: Reject driver application"""
    serializer_class = AdminDriverApprovalSerializer
    permission_classes = [IsAdminUser]
    queryset = Driver.objects.all()
    
    def update(self, request, *args, **kwargs):
        driver = self.get_object()
        rejection_reason = request.data.get('rejection_reason')
        
        if not rejection_reason:
            return Response(
                {'error': 'Rejection reason is required.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if driver.status != 'pending':
            return Response(
                {'error': 'Only pending applications can be rejected.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        driver.status = 'rejected'
        driver.rejection_reason = rejection_reason
        driver.approved_by = request.user
        driver.approved_date = timezone.now()
        driver.save()
        
        return Response(
            AdminDriverApprovalSerializer(driver, context={'request': request}).data,
            status=status.HTTP_200_OK
        )


class AdminVerifyDocumentView(generics.UpdateAPIView):
    """Admin: Verify individual driver document"""
    permission_classes = [IsAdminUser]
    queryset = DriverVerificationDocument.objects.all()
    
    def update(self, request, *args, **kwargs):
        doc = self.get_object()
        
        doc.is_verified = True
        doc.verified_by = request.user
        doc.verified_date = timezone.now()
        doc.notes = request.data.get('notes', '')
        doc.save()
        
        return Response(
            DriverVerificationDocumentSerializer(doc, context={'request': request}).data,
            status=status.HTTP_200_OK
        )