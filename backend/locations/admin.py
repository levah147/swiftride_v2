from django.contrib import admin
from .models import SavedLocation, RecentLocation

@admin.register(SavedLocation)
class SavedLocationAdmin(admin.ModelAdmin):
    list_display = ['user', 'location_type', 'address', 'is_active', 'created_at']
    list_filter = ['location_type', 'is_active', 'created_at']
    search_fields = ['user__phone_number', 'address']

@admin.register(RecentLocation)
class RecentLocationAdmin(admin.ModelAdmin):
    list_display = ['user', 'address', 'search_count', 'last_used']
    list_filter = ['last_used', 'created_at']
    search_fields = ['user__phone_number', 'address']
