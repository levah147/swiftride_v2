from django.contrib import admin
from .models import (
    Ride, RideRequest, DriverRideResponse,
    RideTracking, MutualRating, Promotion
)


# =======================
# INLINE MODELS
# =======================
class RideTrackingInline(admin.TabularInline):
    model = RideTracking
    extra = 0
    readonly_fields = ("latitude", "longitude", "speed_kmh", "bearing", "accuracy_meters", "timestamp")
    can_delete = False


class DriverRideResponseInline(admin.TabularInline):
    model = DriverRideResponse
    extra = 0
    readonly_fields = ("driver", "response", "decline_reason", "response_time_seconds", "created_at")
    can_delete = False


# =======================
# MAIN ADMIN MODELS
# =======================
@admin.register(Ride)
class RideAdmin(admin.ModelAdmin):
    list_display = (
        "id", "user", "driver_full_name", "status", "ride_type",
        "fare_amount", "created_at", "completed_at"
    )
    list_filter = (
        "status", "ride_type", "cancelled_by",
        "created_at", "completed_at"
    )
    search_fields = (
        "user__phone_number", "driver__user__phone_number",
        "pickup_location", "destination_location"
    )
    readonly_fields = (
        "created_at", "updated_at", "accepted_at", "started_at",
        "completed_at", "cancelled_at"
    )
    inlines = [RideTrackingInline]
    list_per_page = 20
    date_hierarchy = "created_at"
    ordering = ("-created_at",)
    fieldsets = (
        ("Rider & Driver Info", {
            "fields": ("user", "driver", "driver_name", "driver_phone", "vehicle_info")
        }),
        ("Ride Details", {
            "fields": (
                "pickup_location", "pickup_latitude", "pickup_longitude",
                "destination_location", "destination_latitude", "destination_longitude",
                "ride_type", "status", "fare_amount", "distance_km", "duration_minutes", "scheduled_time"
            )
        }),
        ("Cancellation", {
            "fields": ("cancelled_by", "cancellation_reason")
        }),
        ("Rating & Feedback", {
            "fields": ("rating", "feedback")
        }),
        ("Timestamps", {
            "fields": ("accepted_at", "started_at", "completed_at", "cancelled_at", "created_at", "updated_at")
        }),
    )


@admin.register(RideRequest)
class RideRequestAdmin(admin.ModelAdmin):
    list_display = ("id", "ride", "status", "expires_at", "created_at")
    list_filter = ("status", "expires_at")
    search_fields = ("ride__id", "ride__user__phone_number", "ride__driver__user__phone_number")
    readonly_fields = ("created_at", "updated_at")
    inlines = [DriverRideResponseInline]
    date_hierarchy = "created_at"
    ordering = ("-created_at",)


@admin.register(DriverRideResponse)
class DriverRideResponseAdmin(admin.ModelAdmin):
    list_display = ("ride_request", "driver", "response", "response_time_seconds", "created_at")
    list_filter = ("response", "created_at")
    search_fields = (
        "driver__user__phone_number", "ride_request__ride__id",
        "ride_request__ride__user__phone_number"
    )
    readonly_fields = ("created_at",)
    ordering = ("-created_at",)


@admin.register(RideTracking)
class RideTrackingAdmin(admin.ModelAdmin):
    list_display = ("ride", "latitude", "longitude", "speed_kmh", "timestamp")
    list_filter = ("timestamp",)
    search_fields = ("ride__id",)
    readonly_fields = ("timestamp",)
    ordering = ("-timestamp",)


@admin.register(MutualRating)
class MutualRatingAdmin(admin.ModelAdmin):
    list_display = (
        "ride", "rider_rating", "driver_rating",
        "rider_rated_at", "driver_rated_at", "is_complete"
    )
    list_filter = ("rider_rating", "driver_rating", "created_at")
    search_fields = ("ride__id", "ride__user__phone_number", "ride__driver__user__phone_number")
    readonly_fields = ("created_at", "updated_at")
    date_hierarchy = "created_at"
    ordering = ("-created_at",)


@admin.register(Promotion)
class PromotionAdmin(admin.ModelAdmin):
    list_display = (
        "title", "discount_percentage", "max_rides",
        "is_active", "valid_from", "valid_until", "created_at"
    )
    list_filter = ("is_active", "valid_from", "valid_until")
    search_fields = ("title", "description")
    date_hierarchy = "valid_from"
    ordering = ("-created_at",)
