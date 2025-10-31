from django.urls import path
from . import views

urlpatterns = [
    path('saved/', views.SavedLocationListCreateView.as_view(), name='saved-locations'),
    path('saved/<int:pk>/', views.SavedLocationDetailView.as_view(), name='saved-location-detail'),
    path('recent/', views.RecentLocationListView.as_view(), name='recent-locations'),
    path('recent/add/', views.add_recent_location, name='add-recent-location'),
    path('detect-city/', views.detect_city_from_coordinates, name='detect_city'),
]
