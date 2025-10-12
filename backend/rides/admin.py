from django.contrib import admin
from .models import Ride, Promotion

@admin.register(Ride)
class RideAdmin(admin.ModelAdmin):
    list_display = ['id', 'user', 'pickup_location', 'destination_location', 'status', 'fare_amount', 'created_at']
    list_filter = ['status', 'ride_type', 'created_at']
    search_fields = ['user__phone_number', 'pickup_location', 'destination_location']
    readonly_fields = ['created_at', 'updated_at']

@admin.register(Promotion)
class PromotionAdmin(admin.ModelAdmin):
    list_display = ['title', 'discount_percentage', 'is_active', 'valid_from', 'valid_until']
    list_filter = ['is_active', 'valid_from', 'valid_until']
    search_fields = ['title', 'description']
