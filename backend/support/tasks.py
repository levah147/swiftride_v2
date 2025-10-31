
"""
FILE LOCATION: support/tasks.py
"""
from celery import shared_task
from django.utils import timezone
from datetime import timedelta
from .models import SupportTicket
import logging

logger = logging.getLogger(__name__)

@shared_task
def auto_close_resolved_tickets():
    """Auto-close tickets resolved more than 7 days ago"""
    try:
        cutoff_date = timezone.now() - timedelta(days=7)
        tickets = SupportTicket.objects.filter(
            status='resolved',
            resolved_at__lt=cutoff_date
        )
        count = 0
        for ticket in tickets:
            ticket.mark_closed()
            count += 1
        logger.info(f"Auto-closed {count} tickets")
        return {'success': True, 'count': count}
    except Exception as e:
        logger.error(f"Error in auto_close_resolved_tickets: {str(e)}")
        return {'success': False, 'error': str(e)}


