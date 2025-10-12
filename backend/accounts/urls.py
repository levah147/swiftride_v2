from django.urls import path
from . import views

urlpatterns = [
    path('send-otp/', views.send_otp, name='send_otp'),
    path('verify-otp/', views.verify_otp, name='verify_otp'),
    path('profile/', views.UserProfileView.as_view(), name='user_profile'),
    path('saved-locations/', views.SavedLocationListCreateView.as_view(), name='saved_locations'),
]
