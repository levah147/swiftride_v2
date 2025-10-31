

"""
FILE LOCATION: promotions/tasks.py
"""
from celery import shared_task
import logging

logger = logging.getLogger(__name__)

@shared_task
def expire_old_promos():
    """Mark expired promos as inactive"""
    from django.utils import timezone
    from .models import PromoCode
    
    count = PromoCode.objects.filter(
        is_active=True,
        end_date__lt=timezone.now()
    ).update(is_active=False)
    
    logger.info(f"Expired {count} promo codes")
    return {'success': True, 'count': count}

@shared_task
def process_referral_rewards():
    """Process completed referrals"""
    from .models import Referral
    
    pending = Referral.objects.filter(status='completed')
    
    for referral in pending:
        # Add rewards logic here
        referral.status = 'rewarded'
        referral.save()
    
    return {'success': True, 'count': pending.count()}

