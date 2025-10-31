

"""
FILE LOCATION: analytics/tasks.py
"""
from celery import shared_task
from django.utils import timezone
from datetime import timedelta
from decimal import Decimal
import logging

logger = logging.getLogger(__name__)

@shared_task
def generate_daily_analytics():
    """Generate daily analytics for yesterday"""
    from .models import RideAnalytics, DriverEarnings
    from rides.models import Ride
    from drivers.models import Driver
    
    yesterday = timezone.now().date() - timedelta(days=1)
    
    try:
        # Generate ride analytics
        rides = Ride.objects.filter(created_at__date=yesterday)
        
        analytics, created = RideAnalytics.objects.update_or_create(
            date=yesterday,
            defaults={
                'total_rides': rides.count(),
                'completed_rides': rides.filter(status='completed').count(),
                'cancelled_by_rider': rides.filter(
                    status='cancelled',
                    cancelled_by='rider'
                ).count(),
                # Add more fields...
            }
        )
        
        # Generate driver earnings
        for driver in Driver.objects.filter(is_active=True):
            driver_rides = rides.filter(driver=driver, status='completed')
            
            if driver_rides.exists():
                earnings, _ = DriverEarnings.objects.update_or_create(
                    driver=driver,
                    date=yesterday,
                    defaults={
                        'completed_rides': driver_rides.count(),
                        'gross_earnings': driver_rides.aggregate(
                            total=Sum('final_fare')
                        )['total'] or Decimal('0.00'),
                        # Add more fields...
                    }
                )
        
        logger.info(f"Generated analytics for {yesterday}")
        return {'success': True, 'date': str(yesterday)}
        
    except Exception as e:
        logger.error(f"Error generating analytics: {str(e)}")
        return {'success': False, 'error': str(e)}

@shared_task
def generate_weekly_revenue_report():
    """Generate weekly revenue report"""
    from .models import RevenueReport
    
    today = timezone.now().date()
    start_date = today - timedelta(days=7)
    
    try:
        report, created = RevenueReport.objects.update_or_create(
            period_type='weekly',
            start_date=start_date,
            end_date=today,
            defaults={
                # Calculate revenue...
            }
        )
        
        logger.info(f"Generated weekly report for {start_date} to {today}")
        return {'success': True}
        
    except Exception as e:
        logger.error(f"Error generating report: {str(e)}")
        return {'success': False, 'error': str(e)}



