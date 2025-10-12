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
