
"""
FILE LOCATION: safety/models.py
"""
from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()


class EmergencySOS(models.Model):
    """Emergency SOS alerts"""
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('resolved', 'Resolved'),
        ('false_alarm', 'False Alarm'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sos_alerts')
    ride = models.ForeignKey('rides.Ride', on_delete=models.SET_NULL, null=True)
    
    latitude = models.DecimalField(max_digits=10, decimal_places=7)
    longitude = models.DecimalField(max_digits=10, decimal_places=7)
    address = models.CharField(max_length=500, blank=True)
    
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    notes = models.TextField(blank=True)
    
    # Emergency contacts notified
    contacts_notified = models.JSONField(default=list)
    
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    resolved_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        db_table = 'safety_emergency_sos'
        ordering = ['-created_at']


class TripShare(models.Model):
    """Share trip with contacts"""
    ride = models.OneToOneField('rides.Ride', on_delete=models.CASCADE, related_name='trip_share')
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    
    shared_with = models.JSONField(default=list, help_text="List of contacts (phone numbers)")
    share_link = models.CharField(max_length=200, unique=True)
    
    is_active = models.BooleanField(default=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    
    class Meta:
        db_table = 'safety_trip_share'


class SafetyCheck(models.Model):
    """Scheduled safety checks during ride"""
    ride = models.ForeignKey('rides.Ride', on_delete=models.CASCADE, related_name='safety_checks')
    
    check_time = models.DateTimeField()
    checked_at = models.DateTimeField(null=True, blank=True)
    
    response = models.CharField(
        max_length=20,
        choices=[
            ('ok', 'OK'),
            ('help', 'Need Help'),
            ('no_response', 'No Response'),
        ],
        blank=True
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'safety_check'
        ordering = ['check_time']


class EmergencyContact(models.Model):
    """User's emergency contacts"""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='emergency_contacts')
    
    name = models.CharField(max_length=200)
    phone_number = models.CharField(max_length=20)
    relationship = models.CharField(max_length=100, blank=True)
    
    is_primary = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'safety_emergency_contact'
        ordering = ['-is_primary', 'name']



