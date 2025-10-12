from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.utils.html import format_html
from .models import User, OTPVerification


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    """Custom admin interface for User model."""
    
    list_display = [
        'phone_number', 
        'get_full_name', 
        'is_phone_verified', 
        'is_driver',
        'rating_display',
        'total_rides',
        'is_staff',
        'created_at'
    ]
    list_filter = [
        'is_phone_verified', 
        'is_driver', 
        'is_staff', 
        'is_superuser',
        'is_active',
        'created_at'
    ]
    search_fields = ['phone_number', 'first_name', 'last_name', 'email']
    ordering = ['-created_at']
    readonly_fields = ['created_at', 'updated_at', 'last_login', 'date_joined']
    
    fieldsets = (
        ('Personal Information', {
            'fields': ('phone_number', 'first_name', 'last_name', 'email', 'profile_picture')
        }),
        ('Verification & Status', {
            'fields': ('is_phone_verified', 'is_driver', 'rating', 'total_rides')
        }),
        ('Permissions', {
            'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions'),
            'classes': ('collapse',)
        }),
        ('Important Dates', {
            'fields': ('last_login', 'date_joined', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    add_fieldsets = (
        ('Create New User', {
            'classes': ('wide',),
            'fields': ('phone_number', 'first_name', 'last_name', 'password1', 'password2', 'is_phone_verified'),
        }),
    )
    
    def get_full_name(self, obj):
        """Display user's full name."""
        return f"{obj.first_name} {obj.last_name}".strip() or "N/A"
    get_full_name.short_description = 'Full Name'
    
    def rating_display(self, obj):
        """Display rating with stars."""
        stars = '⭐' * int(obj.rating)
        return format_html(f'{stars} <span style="color: #666;">({obj.rating})</span>')
    rating_display.short_description = 'Rating'


@admin.register(OTPVerification)
class OTPVerificationAdmin(admin.ModelAdmin):
    """Admin interface for OTP verification."""
    
    list_display = [
        'phone_number', 
        'otp_code', 
        'is_verified', 
        'created_at', 
        'expires_at',
        'is_expired'
    ]
    list_filter = ['is_verified', 'created_at']
    search_fields = ['phone_number', 'otp_code']
    ordering = ['-created_at']
    readonly_fields = ['created_at']
    
    fieldsets = (
        ('OTP Details', {
            'fields': ('phone_number', 'otp_code', 'is_verified')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'expires_at')
        }),
    )
    
    def is_expired(self, obj):
        """Check if OTP is expired."""
        from django.utils import timezone
        expired = obj.expires_at < timezone.now()
        if expired:
            return format_html('<span style="color: red; font-weight: bold;">✗ Expired</span>')
        return format_html('<span style="color: green; font-weight: bold;">✓ Valid</span>')
    is_expired.short_description = 'Status'
    
    def has_add_permission(self, request):
        """Disable manual OTP creation from admin."""
        return False