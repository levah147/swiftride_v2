from django.apps import AppConfig


class DriversConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'drivers'
    verbose_name = 'Driver Management'
    
    def ready(self):
        # Import signals here if you create them later
        pass