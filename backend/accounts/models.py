from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.db import models
from django.core.validators import RegexValidator
import os
from django.utils.text import slugify


def user_profile_picture_path(instance, filename):
    """
    Generate file path for user profile pictures.
    Format: profile_pictures/user_{id}/{filename}
    """
    ext = os.path.splitext(filename)[1]
    filename = f"{slugify(instance.phone_number)}{ext}"
    return os.path.join('profile_pictures', f'user_{instance.id}', filename)


class UserManager(BaseUserManager):
    """Custom user manager for phone number authentication."""
    
    def normalize_phone_number(self, phone_number):
        """
        Normalize phone number to international format.
        Converts '08167791934' to '+2348167791934'
        """
        if not phone_number:
            return phone_number
        
        # Remove any spaces, dashes, or parentheses
        phone_number = ''.join(filter(str.isdigit, phone_number.replace('+', '')))
        
        # If starts with 0 and has 11 digits (Nigerian format), convert to +234
        if phone_number.startswith('0') and len(phone_number) == 11:
            phone_number = '+234' + phone_number[1:]
        # If doesn't start with +, assume it needs +234
        elif not phone_number.startswith('+'):
            # If it's 10 digits, add +234
            if len(phone_number) == 10:
                phone_number = '+234' + phone_number
            # If it's 13 digits starting with 234, add +
            elif len(phone_number) == 13 and phone_number.startswith('234'):
                phone_number = '+' + phone_number
            else:
                phone_number = '+' + phone_number
        else:
            phone_number = '+' + phone_number
        
        return phone_number
    
    def create_user(self, phone_number, password=None, **extra_fields):
        """Create and return a regular user with a phone number."""
        if not phone_number:
            raise ValueError('The Phone Number field must be set')
        
        # Normalize the phone number
        phone_number = self.normalize_phone_number(phone_number)
        
        user = self.model(phone_number=phone_number, **extra_fields)
        if password:
            user.set_password(password)
        user.save(using=self._db)
        return user
    
    def create_superuser(self, phone_number, password=None, **extra_fields):
        """Create and return a superuser with a phone number."""
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_phone_verified', True)
        
        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')
        
        return self.create_user(phone_number, password, **extra_fields)
    
    def get_by_natural_key(self, phone_number):
        """
        Override to normalize phone number during authentication.
        This allows login with either 08167791934 or +2348167791934
        """
        phone_number = self.normalize_phone_number(phone_number)
        return self.get(**{self.model.USERNAME_FIELD: phone_number})


class User(AbstractUser):
    phone_regex = RegexValidator(
        regex=r'^\+?1?\d{9,15}$',
        message="Phone number must be entered in the format: '+999999999'. Up to 15 digits allowed."
    )
    
    phone_number = models.CharField(
        validators=[phone_regex], 
        max_length=17, 
        unique=True,
        help_text="Phone number in international format"
    )
    is_phone_verified = models.BooleanField(default=False)
    rating = models.DecimalField(max_digits=3, decimal_places=2, default=5.00)
    total_rides = models.IntegerField(default=0)
    profile_picture = models.ImageField(
        upload_to=user_profile_picture_path,
        blank=True,
        null=True,
        help_text="User's profile picture"
    )
    is_driver = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    # Override username requirement
    username = None
    USERNAME_FIELD = 'phone_number'
    REQUIRED_FIELDS = ['first_name', 'last_name']
    
    # Assign the custom manager
    objects = UserManager()
    
    def save(self, *args, **kwargs):
        """Override save to normalize phone number before saving."""
        if self.phone_number:
            self.phone_number = User.objects.normalize_phone_number(self.phone_number)
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.first_name} {self.last_name} - {self.phone_number}"


class OTPVerification(models.Model):
    phone_number = models.CharField(max_length=17)
    otp_code = models.CharField(max_length=6)
    is_verified = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()

    class Meta:
        ordering = ['-created_at']
    
    def save(self, *args, **kwargs):
        """Normalize phone number before saving."""
        if self.phone_number:
            self.phone_number = User.objects.normalize_phone_number(self.phone_number)
        super().save(*args, **kwargs)

    def __str__(self):
        return f"OTP for {self.phone_number}"