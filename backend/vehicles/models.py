from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
from decimal import Decimal


class City(models.Model):
    """Cities where SwiftRide operates"""
    
    name = models.CharField(max_length=100, unique=True)
    state = models.CharField(max_length=100)
    country = models.CharField(max_length=100, default='Nigeria')
    
    # Geographic data
    latitude = models.DecimalField(max_digits=10, decimal_places=8, null=True, blank=True)
    longitude = models.DecimalField(max_digits=11, decimal_places=8, null=True, blank=True)
    
    # Service availability
    is_active = models.BooleanField(default=True, help_text="Is service available in this city?")
    has_bike = models.BooleanField(default=True, help_text="Are bikes allowed in this city?")
    has_keke = models.BooleanField(default=True, help_text="Are kekes allowed in this city?")
    has_car = models.BooleanField(default=True, help_text="Are cars allowed in this city?")
    has_suv = models.BooleanField(default=True, help_text="Are SUVs allowed in this city?")
    
    # Settings
    timezone = models.CharField(max_length=50, default='Africa/Lagos')
    currency = models.CharField(max_length=10, default='NGN')
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name_plural = "Cities"
        ordering = ['name']
        indexes = [
            models.Index(fields=['name', 'is_active']),
        ]
    
    def __str__(self):
        return f"{self.name}, {self.state}"
    
    def get_available_vehicles(self):
        """Get list of available vehicle types in this city"""
        available = []
        if self.has_bike:
            available.append('bike')
        if self.has_keke:
            available.append('keke')
        if self.has_car:
            available.append('car')
        if self.has_suv:
            available.append('suv')
        return available


class VehicleType(models.Model):
    """Vehicle types available on the platform"""
    
    VEHICLE_CHOICES = [
        ('bike', 'Bike (Okada)'),
        ('keke', 'Keke (Tricycle)'),
        ('car', 'Car (Standard)'),
        ('suv', 'SUV (Premium)'),
    ]
    
    id = models.CharField(
        max_length=20,
        primary_key=True,
        choices=VEHICLE_CHOICES,
        help_text="Unique identifier for vehicle type"
    )
    name = models.CharField(max_length=50, help_text="Display name")
    description = models.TextField(help_text="Short description of vehicle type")
    
    # Visual
    icon_name = models.CharField(
        max_length=50,
        default='directions_car',
        help_text="Material icon name for Flutter"
    )
    color = models.CharField(
        max_length=7,
        default='#0066FF',
        help_text="Hex color code for UI"
    )
    
    # Capacity
    max_passengers = models.IntegerField(default=1)
    has_luggage_space = models.BooleanField(default=False)
    
    # Availability
    is_active = models.BooleanField(default=True)
    
    # Order/Priority
    display_order = models.IntegerField(
        default=0,
        help_text="Order in which to display in app (lower numbers first)"
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['display_order', 'name']
    
    def __str__(self):
        return self.name
    
    def get_base_pricing(self, city=None):
        """Get base pricing for this vehicle type in a city"""
        if city:
            try:
                return VehiclePricing.objects.get(vehicle_type=self, city=city)
            except VehiclePricing.DoesNotExist:
                pass
        # Return default pricing
        return VehiclePricing.objects.filter(
            vehicle_type=self,
            is_default=True
        ).first()


class VehiclePricing(models.Model):
    """Pricing structure for vehicles per city"""
    
    vehicle_type = models.ForeignKey(
        VehicleType,
        on_delete=models.CASCADE,
        related_name='pricing'
    )
    city = models.ForeignKey(
        City,
        on_delete=models.CASCADE,
        related_name='vehicle_pricing',
        null=True,
        blank=True,
        help_text="Leave blank for default pricing"
    )
    
    # Base pricing
    base_fare = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.00'))],
        help_text="Base fare in Naira"
    )
    price_per_km = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.00'))],
        help_text="Price per kilometer in Naira"
    )
    price_per_minute = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.00'))],
        help_text="Price per minute in Naira"
    )
    
    # Minimum fare
    minimum_fare = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.00'))],
        help_text="Minimum fare for this vehicle type"
    )
    
    # Settings
    is_default = models.BooleanField(
        default=False,
        help_text="Use this pricing when city-specific pricing not found"
    )
    is_active = models.BooleanField(default=True)
    
    # Metadata
    estimated_arrival_time = models.CharField(
        max_length=20,
        default='5 min',
        help_text="Estimated time for driver to arrive"
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ('vehicle_type', 'city')
        ordering = ['vehicle_type', 'city']
        indexes = [
            models.Index(fields=['vehicle_type', 'city', 'is_active']),
        ]
    
    def __str__(self):
        city_name = self.city.name if self.city else "Default"
        return f"{self.vehicle_type.name} - {city_name}"
    
    def calculate_fare(self, distance_km, duration_minutes, surge_multiplier=1.0):
        """Calculate total fare based on distance and time"""
        # Base calculation
        fare = (
            float(self.base_fare) +
            (float(self.price_per_km) * distance_km) +
            (float(self.price_per_minute) * duration_minutes)
        )
        
        # Apply surge if provided
        fare *= surge_multiplier
        
        # Ensure minimum fare
        fare = max(fare, float(self.minimum_fare))
        
        return round(Decimal(fare), 2)


class SurgePricing(models.Model):
    """Dynamic surge pricing rules"""
    
    SURGE_LEVEL_CHOICES = [
        ('normal', 'Normal (1.0x)'),
        ('light', 'Light Surge (1.2x)'),
        ('moderate', 'Moderate Surge (1.5x)'),
        ('heavy', 'Heavy Surge (2.0x)'),
    ]
    
    name = models.CharField(max_length=100, help_text="Surge rule name")
    description = models.TextField(blank=True)
    
    city = models.ForeignKey(
        City,
        on_delete=models.CASCADE,
        related_name='surge_rules',
        null=True,
        blank=True,
        help_text="Apply to specific city, or all cities if blank"
    )
    
    # Surge multiplier
    surge_level = models.CharField(
        max_length=20,
        choices=SURGE_LEVEL_CHOICES,
        default='normal'
    )
    multiplier = models.DecimalField(
        max_digits=3,
        decimal_places=2,
        default=Decimal('1.0'),
        validators=[MinValueValidator(Decimal('1.0')), MaxValueValidator(Decimal('5.0'))],
        help_text="Fare multiplier (1.0 = no surge, 2.0 = double fare)"
    )
    
    # Time-based rules
    start_time = models.TimeField(null=True, blank=True, help_text="Start time for surge")
    end_time = models.TimeField(null=True, blank=True, help_text="End time for surge")
    
    # Day-based rules
    monday = models.BooleanField(default=True)
    tuesday = models.BooleanField(default=True)
    wednesday = models.BooleanField(default=True)
    thursday = models.BooleanField(default=True)
    friday = models.BooleanField(default=True)
    saturday = models.BooleanField(default=True)
    sunday = models.BooleanField(default=True)
    
    # Conditions
    is_active = models.BooleanField(default=True)
    priority = models.IntegerField(
        default=0,
        help_text="Higher priority rules are applied first"
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-priority', '-multiplier']
        verbose_name_plural = "Surge pricing rules"
    
    def __str__(self):
        return f"{self.name} - {self.multiplier}x"
    
    @staticmethod
    def get_current_multiplier(city=None):
        """Get current surge multiplier for a city"""
        from django.utils import timezone
        now = timezone.now()
        current_time = now.time()
        current_day = now.strftime('%A').lower()
        
        # Build query
        query = models.Q(is_active=True)
        if city:
            query &= (models.Q(city=city) | models.Q(city__isnull=True))
        
        # Filter by time and day
        rules = SurgePricing.objects.filter(query)
        
        for rule in rules:
            # Check day
            day_field = f"{current_day}"
            if hasattr(rule, day_field) and getattr(rule, day_field):
                # Check time
                if rule.start_time and rule.end_time:
                    if rule.start_time <= current_time <= rule.end_time:
                        return float(rule.multiplier)
                else:
                    # No time restriction
                    return float(rule.multiplier)
        
        return 1.0  # No surge


class FuelPriceAdjustment(models.Model):
    """Dynamic pricing adjustment based on fuel prices"""
    
    city = models.ForeignKey(
        City,
        on_delete=models.CASCADE,
        related_name='fuel_adjustments',
        null=True,
        blank=True
    )
    
    # Fuel price threshold
    fuel_price_per_litre = models.DecimalField(
        max_digits=8,
        decimal_places=2,
        help_text="Current fuel price per litre in Naira"
    )
    baseline_fuel_price = models.DecimalField(
        max_digits=8,
        decimal_places=2,
        default=Decimal('800.00'),
        help_text="Baseline fuel price (no adjustment below this)"
    )
    
    # Adjustment per ₦100 increase
    adjustment_per_100_naira = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('10.00'),
        help_text="Add this amount per km for every ₦100 fuel increase"
    )
    
    is_active = models.BooleanField(default=True)
    effective_date = models.DateField(auto_now_add=True)
    
    class Meta:
        ordering = ['-effective_date']
        verbose_name_plural = "Fuel price adjustments"
    
    def __str__(self):
        city_name = self.city.name if self.city else "All Cities"
        return f"{city_name} - ₦{self.fuel_price_per_litre}/L"
    
    def calculate_adjustment(self):
        """Calculate per-km adjustment based on fuel price"""
        if self.fuel_price_per_litre <= self.baseline_fuel_price:
            return Decimal('0.00')
        
        price_increase = self.fuel_price_per_litre - self.baseline_fuel_price
        increments = price_increase / Decimal('100.00')
        adjustment = increments * self.adjustment_per_100_naira
        
        return round(adjustment, 2)