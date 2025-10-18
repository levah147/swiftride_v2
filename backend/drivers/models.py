from django.db import models
from django.core.validators import RegexValidator, FileExtensionValidator
from accounts.models import User
import os
from django.utils.text import slugify


def driver_document_path(instance, filename):
    """Generate file path for driver documents"""
    ext = os.path.splitext(filename)[1]
    filename = f"{slugify(instance.driver.user.phone_number)}_{instance.document_type}{ext}"
    return os.path.join('driver_documents', f'driver_{instance.driver.id}', filename)


def vehicle_image_path(instance, filename):
    """Generate file path for vehicle images"""
    ext = os.path.splitext(filename)[1]
    filename = f"vehicle_{instance.id}{ext}"
    return os.path.join('vehicle_images', f'driver_{instance.driver.id}', filename)


class Driver(models.Model):
    """Driver profile model"""
    
    STATUS_CHOICES = [
        ('pending', 'Pending Approval'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
        ('suspended', 'Suspended'),
    ]
    
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='driver_profile')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    
    # Vehicle Information
    vehicle_type = models.CharField(
        max_length=50,
        choices=[
            ('sedan', 'Sedan'),
            ('suv', 'SUV'),
            ('hatchback', 'Hatchback'),
            ('van', 'Van'),
            ('truck', 'Truck'),
        ]
    )
    vehicle_color = models.CharField(max_length=50)
    license_plate = models.CharField(
        max_length=20,
        unique=True,
        help_text="Vehicle license plate number"
    )
    vehicle_year = models.IntegerField(null=True, blank=True)
    
    # Driver Information
    driver_license_number = models.CharField(max_length=50, unique=True)
    driver_license_expiry = models.DateField()
    
    # Background Check
    background_check_passed = models.BooleanField(default=False)
    background_check_date = models.DateTimeField(null=True, blank=True)
    
    # Approval Information
    approved_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='approved_drivers'
    )
    approved_date = models.DateTimeField(null=True, blank=True)
    rejection_reason = models.TextField(null=True, blank=True)
    
    # Statistics
    total_rides = models.IntegerField(default=0)
    rating = models.DecimalField(max_digits=3, decimal_places=2, default=5.00)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'status']),
            models.Index(fields=['status']),
            models.Index(fields=['license_plate']),
        ]
    
    def __str__(self):
        return f"{self.user.get_full_name()} - {self.get_status_display()}"
    
    @property
    def is_approved(self):
        return self.status == 'approved'
    
    @property
    def is_rejected(self):
        return self.status == 'rejected'
    
    @property
    def is_pending(self):
        return self.status == 'pending'


class DriverVerificationDocument(models.Model):
    """Store driver verification documents"""
    
    DOCUMENT_TYPES = [
        ('license', 'Driver License'),
        ('registration', 'Vehicle Registration'),
        ('insurance', 'Insurance Document'),
        ('vehicle_picture', 'Vehicle Picture'),
        ('driver_picture', 'Driver Picture'),
    ]
    
    driver = models.ForeignKey(
        Driver,
        on_delete=models.CASCADE,
        related_name='verification_documents'
    )
    document_type = models.CharField(max_length=50, choices=DOCUMENT_TYPES)
    document = models.FileField(
        upload_to=driver_document_path,
        validators=[FileExtensionValidator(allowed_extensions=['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'])]
    )
    is_verified = models.BooleanField(default=False)
    verified_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='verified_documents'
    )
    verified_date = models.DateTimeField(null=True, blank=True)
    notes = models.TextField(null=True, blank=True)
    uploaded_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ('driver', 'document_type')
        ordering = ['-uploaded_at']
    
    def __str__(self):
        return f"{self.driver.user.phone_number} - {self.get_document_type_display()}"
    
    @property
    def document_url(self):
        """Return full URL for the document"""
        if self.document:
            return self.document.url
        return None


class VehicleImage(models.Model):
    """Store vehicle images"""
    
    IMAGE_TYPES = [
        ('front', 'Front View'),
        ('back', 'Back View'),
        ('side', 'Side View'),
        ('interior', 'Interior'),
        ('registration', 'Registration Plate'),
    ]
    
    driver = models.ForeignKey(
        Driver,
        on_delete=models.CASCADE,
        related_name='vehicle_images'
    )
    image_type = models.CharField(max_length=50, choices=IMAGE_TYPES)
    image = models.ImageField(upload_to=vehicle_image_path)
    uploaded_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ('driver', 'image_type')
        ordering = ['-uploaded_at']
    
    def __str__(self):
        return f"{self.driver.user.phone_number} - {self.get_image_type_display()}"
    
    @property
    def image_url(self):
        """Return full URL for the image"""
        if self.image:
            return self.image.url
        return None


class DriverRating(models.Model):
    """Store individual driver ratings from passengers"""
    
    driver = models.ForeignKey(
        Driver,
        on_delete=models.CASCADE,
        related_name='ratings'
    )
    rider = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name='driver_ratings'
    )
    rating = models.DecimalField(
        max_digits=3,
        decimal_places=1,
        choices=[(i, str(i)) for i in [1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0]]
    )
    comment = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ('driver', 'rider')  # One rating per rider per driver
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.driver.user.phone_number} - {self.rating} stars"