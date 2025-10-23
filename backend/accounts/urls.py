from django.urls import path
from . import views

urlpatterns = [
    # OTP & Authentication
    path('send-otp/', views.send_otp, name='send_otp'),
    path('verify-otp/', views.verify_otp, name='verify_otp'),
    path('logout/', views.logout, name='logout'),
    
    # User Profile
    path('profile/', views.UserProfileView.as_view(), name='user_profile'),
    path('profile/update/', views.UserProfileUpdateView.as_view(), name='user_profile_update'),
    path('delete-account/', views.delete_account, name='delete_account'),
    
    # # Saved Locations
    # path('saved-locations/', views.SavedLocationListCreateView.as_view(), name='saved_locations'),
    # path('saved-locations/<int:pk>/', views.SavedLocationDetailView.as_view(), name='saved_location_detail'),
]