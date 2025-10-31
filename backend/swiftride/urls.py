from django.contrib import admin
from django.urls import path, include

from django.conf import settings
from django.conf.urls.static import static
 
urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/accounts/', include('accounts.urls')),
    path('api/drivers/', include('drivers.urls')),
    path('api/vehicles/', include('vehicles.urls')),  # NEW
    path('api/pricing/', include('pricing.urls')),    # RENAMED
    path('api/locations/', include('locations.urls')),
    path('api/rides/', include('rides.urls')),
    path('api/payments/', include('payments.urls')),
    
    path('api/notifications/', include('notifications.urls')),
    path('api/chat/', include('chat.urls')),
    path('api/support/', include('support.urls')),
    path('api/analytics/', include('analytics.urls')),
    
    path('api/promotions/', include('promotions.urls')),
    path('api/safety/', include('safety.urls')),
    path('api/admin_dashboard/', include('admin_dashboard_app.urls')),
    
    ]

# Serve media files during development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)