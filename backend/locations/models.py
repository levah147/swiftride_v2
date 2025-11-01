from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()

class SavedLocation(models.Model):
    LOCATION_TYPE_CHOICES = [
        ('home', 'Home'),
        ('work', 'Work'),
        ('other', 'Other'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='saved_locations')
    location_type = models.CharField(max_length=10, choices=LOCATION_TYPE_CHOICES)
    address = models.CharField(max_length=255)
    latitude = models.DecimalField(max_digits=10, decimal_places=8)
    longitude = models.DecimalField(max_digits=11, decimal_places=8)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['user', 'location_type']
        ordering = ['-updated_at']

    
    def __str__(self):
        return f"{self.user.phone_number} - {self.location_type}: {self.address}"

class RecentLocation(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='recent_locations')
    address = models.CharField(max_length=255)
    latitude = models.DecimalField(max_digits=10, decimal_places=8)
    longitude = models.DecimalField(max_digits=11, decimal_places=8)
    search_count = models.IntegerField(default=1)
    last_used = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-last_used']
        unique_together = ['user', 'address']
    
    def __str__(self):
        return f"{self.user.phone_number} - {self.address}"




class DriverLocation(models.Model):
    """Real-time driver location tracking"""
    
    driver = models.OneToOneField(
        'drivers.Driver',
        on_delete=models.CASCADE,
        related_name='current_location'
    )
    latitude = models.DecimalField(max_digits=10, decimal_places=8)
    longitude = models.DecimalField(max_digits=11, decimal_places=8)
    bearing = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    speed_kmh = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    accuracy_meters = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)
    last_updated = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'locations_driver_location'
        indexes = [
            models.Index(fields=['latitude', 'longitude']),
            models.Index(fields=['last_updated']),
        ]
    
    def __str__(self):
        return f"{self.driver.user.get_full_name()} - Last updated: {self.last_updated}"


# MOVE RideTracking from rides app to here
class RideTracking(models.Model):
    """GPS tracking during active rides"""
    
    ride = models.ForeignKey(
        'rides.Ride',
        on_delete=models.CASCADE,
        related_name='tracking_points'
    )
    latitude = models.DecimalField(max_digits=10, decimal_places=8)
    longitude = models.DecimalField(max_digits=11, decimal_places=8)
    speed_kmh = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    bearing = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    accuracy_meters = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'locations_ride_tracking'
        ordering = ['timestamp']
        indexes = [
            models.Index(fields=['ride', 'timestamp']),
        ]