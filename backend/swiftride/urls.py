from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/', include('accounts.urls')),
    path('api/rides/', include('rides.urls')),
    path('api/locations/', include('locations.urls')),
]
