"""
FILE LOCATION: accounts/signals.py

Signal handlers for accounts app integration.
"""
from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import User


@receiver(post_save, sender=User)
def user_created_handler(sender, instance, created, **kwargs):
    """
    Handle user creation events.
    
    When a new user is created:
    1. Send welcome notification
    2. Log user registration
    3. Trigger analytics event
    """
    if created:
        print(f"✅ New user registered: {instance.phone_number}")
        
        # TODO: Send welcome notification
        # from notifications.services import send_notification
        # send_notification(
        #     user=instance,
        #     title='Welcome to SwiftRide!',
        #     message='Thanks for joining us!'
        # )


@receiver(post_save, sender=User)
def user_becomes_driver(sender, instance, **kwargs):
    """Handle when user becomes a driver"""
    if instance.is_driver:
        # Check if this is a new driver registration
        if not hasattr(instance, '_driver_status_changed'):
            instance._driver_status_changed = True
            print(f"✅ User {instance.phone_number} is now a driver")
            
            # TODO: Send driver welcome notification
            # TODO: Create driver profile if needed

