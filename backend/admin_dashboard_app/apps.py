
"""
FILE LOCATION: admin_dashboard/apps.py

App configuration.
"""

from django.apps import AppConfig


class AdminDashboardConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'admin_dashboard_app'
    verbose_name = 'Admin Dashboard'




