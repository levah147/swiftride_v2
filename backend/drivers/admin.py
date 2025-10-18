from django.contrib import admin
from django.utils.html import format_html
from .models import Driver, DriverVerificationDocument, VehicleImage, DriverRating


@admin.register(Driver)
class DriverAdmin(admin.ModelAdmin):
    list_display = (
        'get_full_name', 'phone_number', 'status_badge', 'vehicle_type',
        'license_plate', 'total_rides', 'rating', 'created_at'
    )
    list_filter = ('status', 'background_check_passed', 'vehicle_type', 'created_at')
    search_fields = ('user__phone_number', 'user__first_name', 'user__last_name', 'license_plate')
    readonly_fields = (
        'user', 'total_rides', 'rating', 'approved_by', 'approved_date', 'created_at', 'updated_at'
    )
    
    fieldsets = (
        ('User Information', {
            'fields': ('user',)
        }),
        ('Vehicle Information', {
            'fields': ('vehicle_type', 'vehicle_color', 'license_plate', 'vehicle_year')
        }),
        ('Driver License', {
            'fields': ('driver_license_number', 'driver_license_expiry')
        }),
        ('Background Check', {
            'fields': ('background_check_passed',)
        }),
        ('Application Status', {
            'fields': ('status', 'rejection_reason')
        }),
        ('Approval Information', {
            'fields': ('approved_by', 'approved_date')
        }),
        ('Statistics', {
            'fields': ('total_rides', 'rating')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at')
        }),
    )
    
    actions = ['approve_drivers', 'reject_drivers', 'suspend_drivers']
    
    def get_full_name(self, obj):
        return obj.user.get_full_name()
    get_full_name.short_description = 'Full Name'
    
    def phone_number(self, obj):
        return obj.user.phone_number
    phone_number.short_description = 'Phone'
    
    def status_badge(self, obj):
        colors = {
            'pending': '#FFA500',    # Orange
            'approved': '#28a745',   # Green
            'rejected': '#dc3545',   # Red
            'suspended': '#6c757d',  # Gray
        }
        color = colors.get(obj.status, '#000000')
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 10px; border-radius: 3px;">{}</span>',
            color,
            obj.get_status_display()
        )
    status_badge.short_description = 'Status'
    
    def approve_drivers(self, request, queryset):
        updated = queryset.filter(status='pending').update(
            status='approved',
            approved_by=request.user,
            approved_date=timezone.now()
        )
        self.message_user(request, f'{updated} drivers approved.')
    approve_drivers.short_description = 'Approve selected drivers'
    
    def reject_drivers(self, request, queryset):
        updated = queryset.filter(status='pending').update(
            status='rejected',
            approved_by=request.user,
            approved_date=timezone.now()
        )
        self.message_user(request, f'{updated} drivers rejected.')
    reject_drivers.short_description = 'Reject selected drivers'
    
    def suspend_drivers(self, request, queryset):
        updated = queryset.update(status='suspended')
        self.message_user(request, f'{updated} drivers suspended.')
    suspend_drivers.short_description = 'Suspend selected drivers'


@admin.register(DriverVerificationDocument)
class DriverVerificationDocumentAdmin(admin.ModelAdmin):
    list_display = (
        'get_driver_name', 'document_type', 'get_file_size', 'is_verified_badge',
        'verified_by', 'uploaded_at'
    )
    list_filter = ('document_type', 'is_verified', 'uploaded_at')
    search_fields = ('driver__user__phone_number', 'driver__user__first_name')
    readonly_fields = ('driver', 'uploaded_at', 'updated_at', 'verified_date', 'document_preview')
    
    fieldsets = (
        ('Document Information', {
            'fields': ('driver', 'document_type', 'document', 'document_preview')
        }),
        ('Verification', {
            'fields': ('is_verified', 'verified_by', 'verified_date', 'notes')
        }),
        ('Timestamps', {
            'fields': ('uploaded_at', 'updated_at')
        }),
    )
    
    actions = ['mark_as_verified']
    
    def get_driver_name(self, obj):
        return obj.driver.user.get_full_name()
    get_driver_name.short_description = 'Driver'
    
    def get_file_size(self, obj):
        size_bytes = obj.document.size if obj.document else 0
        size_mb = size_bytes / (1024 * 1024)
        return f'{size_mb:.2f} MB'
    get_file_size.short_description = 'File Size'
    
    def is_verified_badge(self, obj):
        if obj.is_verified:
            return format_html(
                '<span style="background-color: #28a745; color: white; padding: 3px 10px; border-radius: 3px;">Verified</span>'
            )
        return format_html(
            '<span style="background-color: #ffc107; color: black; padding: 3px 10px; border-radius: 3px;">Pending</span>'
        )
    is_verified_badge.short_description = 'Verified'
    
    def document_preview(self, obj):
        if obj.document:
            return format_html(
                '<a href="{}" target="_blank">View Document</a>',
                obj.document.url
            )
        return 'No document'
    document_preview.short_description = 'Preview'
    
    def mark_as_verified(self, request, queryset):
        updated = queryset.update(
            is_verified=True,
            verified_by=request.user,
            verified_date=timezone.now()
        )
        self.message_user(request, f'{updated} documents marked as verified.')
    mark_as_verified.short_description = 'Mark as verified'


@admin.register(VehicleImage)
class VehicleImageAdmin(admin.ModelAdmin):
    list_display = ('get_driver_name', 'image_type', 'image_preview', 'uploaded_at')
    list_filter = ('image_type', 'uploaded_at')
    search_fields = ('driver__user__phone_number', 'driver__user__first_name')
    readonly_fields = ('driver', 'uploaded_at', 'image_preview')
    
    fieldsets = (
        ('Image Information', {
            'fields': ('driver', 'image_type', 'image', 'image_preview')
        }),
        ('Timestamps', {
            'fields': ('uploaded_at',)
        }),
    )
    
    def get_driver_name(self, obj):
        return obj.driver.user.get_full_name()
    get_driver_name.short_description = 'Driver'
    
    def image_preview(self, obj):
        if obj.image:
            return format_html(
                '<img src="{}" width="100" height="100" style="object-fit: cover; border-radius: 5px;"/>',
                obj.image.url
            )
        return 'No image'
    image_preview.short_description = 'Preview'


@admin.register(DriverRating)
class DriverRatingAdmin(admin.ModelAdmin):
    list_display = (
        'get_driver_name', 'get_rider_name', 'rating_stars', 'created_at'
    )
    list_filter = ('rating', 'created_at')
    search_fields = ('driver__user__phone_number', 'rider__phone_number')
    readonly_fields = ('driver', 'rider', 'rating', 'created_at')
    
    fieldsets = (
        ('Rating Information', {
            'fields': ('driver', 'rider', 'rating')
        }),
        ('Comment', {
            'fields': ('comment',)
        }),
        ('Timestamps', {
            'fields': ('created_at',)
        }),
    )
    
    def get_driver_name(self, obj):
        return obj.driver.user.get_full_name()
    get_driver_name.short_description = 'Driver'
    
    def get_rider_name(self, obj):
        return obj.rider.get_full_name() if obj.rider else 'Unknown'
    get_rider_name.short_description = 'Rider'
    
    def rating_stars(self, obj):
        stars = '⭐' * int(obj.rating)
        return format_html(
            '<span>{}</span>',
            stars
        )
    rating_stars.short_description = 'Rating'