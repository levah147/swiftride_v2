from django.urls import path
from . import views

app_name = 'vehicles'

urlpatterns = [
    # Cities
    path('cities/', views.CityListView.as_view(), name='cities_list'),
    path('detect-city/', views.detect_city, name='detect_city'),
    
    # Vehicles
    path('types/', views.get_available_vehicles, name='vehicle_types'),
    
    # Fare calculation
    path('calculate-fare/', views.calculate_fare, name='calculate_fare'),
]