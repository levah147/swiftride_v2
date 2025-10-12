from django.db import models
from django.contrib.auth import get_user_model
from django.core.validators import MinValueValidator, MaxValueValidator

User = get_user_model()

class Ride(models.Model):
    RIDE_STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('confirmed', 'Confirmed'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]
    
    RIDE_TYPE_CHOICES = [
        ('immediate', 'Immediate'),
        ('scheduled', 'Scheduled'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='rides')
    pickup_location = models.CharField(max_length=255)
    pickup_latitude = models.DecimalField(max_digits=10, decimal_places=8)
    pickup_longitude = models.DecimalField(max_digits=11, decimal_places=8)
    destination_location = models.CharField(max_length=255)
    destination_latitude = models.DecimalField(max_digits=10, decimal_places=8)
    destination_longitude = models.DecimalField(max_digits=11, decimal_places=8)
    
    ride_type = models.CharField(max_length=20, choices=RIDE_TYPE_CHOICES, default='immediate')
    status = models.CharField(max_length=20, choices=RIDE_STATUS_CHOICES, default='pending')
    
    scheduled_time = models.DateTimeField(null=True, blank=True)
    fare_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    distance_km = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    duration_minutes = models.IntegerField(null=True, blank=True)
    
    driver_name = models.CharField(max_length=100, null=True, blank=True)
    driver_phone = models.CharField(max_length=20, null=True, blank=True)
    vehicle_info = models.CharField(max_length=100, null=True, blank=True)
    
    rating = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        null=True, blank=True
    )
    feedback = models.TextField(null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Ride {self.id} - {self.user.phone_number} - {self.status}"

class Promotion(models.Model):
    title = models.CharField(max_length=100)
    description = models.TextField()
    discount_percentage = models.IntegerField(validators=[MinValueValidator(1), MaxValueValidator(100)])
    max_rides = models.IntegerField(default=1)
    is_active = models.BooleanField(default=True)
    valid_from = models.DateTimeField()
    valid_until = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"{self.title} - {self.discount_percentage}% off"
