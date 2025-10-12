from django.urls import path
from . import views

urlpatterns = [
    path('', views.RideListCreateView.as_view(), name='ride-list-create'),
    path('<int:pk>/', views.RideDetailView.as_view(), name='ride-detail'),
    path('upcoming/', views.upcoming_rides, name='upcoming-rides'),
    path('past/', views.past_rides, name='past-rides'),
    path('promotions/', views.ActivePromotionsView.as_view(), name='active-promotions'),
]
