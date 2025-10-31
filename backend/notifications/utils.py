"""
FILE LOCATION: notifications/utils.py

Utility functions for sending notifications via different channels.
Includes FCM push notifications, SMS, and email functions.
"""
import os
import logging
import requests
from django.conf import settings
from django.core.mail import send_mail
from django.template.loader import render_to_string
from .models import PushToken

logger = logging.getLogger(__name__)


# ========================================
# FIREBASE CLOUD MESSAGING (FCM)
# ========================================

def send_fcm_push_notification(user, title, body, data=None):
    """
    Send push notification via Firebase Cloud Messaging.
    
    Args:
        user: User object
        title: Notification title
        body: Notification body
        data: Additional data payload
    
    Returns:
        dict: {'success': bool, 'message': str}
    """
    try:
        # Get user's active push tokens
        tokens = PushToken.objects.filter(
            user=user,
            is_active=True
        ).values_list('token', flat=True)
        
        if not tokens:
            return {'success': False, 'error': 'No active push tokens'}
        
        # Get FCM server key from settings
        fcm_server_key = getattr(settings, 'FCM_SERVER_KEY', None)
        if not fcm_server_key:
            logger.error("FCM_SERVER_KEY not configured")
            return {'success': False, 'error': 'FCM not configured'}
        
        # Prepare FCM payload
        fcm_url = 'https://fcm.googleapis.com/fcm/send'
        headers = {
            'Authorization': f'Bearer {fcm_server_key}',
            'Content-Type': 'application/json'
        }
        
        success_count = 0
        failed_count = 0
        
        for token in tokens:
            payload = {
                'to': token,
                'notification': {
                    'title': title,
                    'body': body,
                    'sound': 'default',
                    'badge': '1'
                },
                'data': data or {},
                'priority': 'high'
            }
            
            try:
                response = requests.post(
                    fcm_url,
                    json=payload,
                    headers=headers,
                    timeout=10
                )
                
                if response.status_code == 200:
                    result = response.json()
                    if result.get('success') == 1:
                        success_count += 1
                    else:
                        # Token might be invalid
                        error = result.get('results', [{}])[0].get('error')
                        if error in ['InvalidRegistration', 'NotRegistered']:
                            # Deactivate invalid token
                            PushToken.objects.filter(token=token).update(is_active=False)
                        failed_count += 1
                else:
                    failed_count += 1
                    
            except Exception as e:
                logger.error(f"Error sending FCM to token {token[:20]}: {str(e)}")
                failed_count += 1
        
        return {
            'success': success_count > 0,
            'sent': success_count,
            'failed': failed_count
        }
        
    except Exception as e:
        logger.error(f"Error in send_fcm_push_notification: {str(e)}")
        return {'success': False, 'error': str(e)}


# ========================================
# SMS PROVIDERS
# ========================================

def send_sms_africastalking(phone_number, message):
    """
    Send SMS via Africa's Talking.
    
    Args:
        phone_number: Phone number (e.g., +234XXXXXXXXXX)
        message: SMS message
    
    Returns:
        dict: {'success': bool, 'message_id': str, 'cost': Decimal}
    """
    try:
        import africastalking
        
        # Get credentials from settings
        username = getattr(settings, 'AFRICASTALKING_USERNAME', 'sandbox')
        api_key = getattr(settings, 'AFRICASTALKING_API_KEY', '')
        
        if not api_key:
            return {'success': False, 'error': 'AfricasTalking not configured'}
        
        # Initialize SDK
        africastalking.initialize(username, api_key)
        sms = africastalking.SMS
        
        # Send SMS
        response = sms.send(message, [phone_number])
        
        if response['SMSMessageData']['Recipients']:
            recipient = response['SMSMessageData']['Recipients'][0]
            
            if recipient['status'] == 'Success':
                return {
                    'success': True,
                    'message_id': recipient.get('messageId'),
                    'cost': recipient.get('cost')
                }
            else:
                return {
                    'success': False,
                    'error': recipient.get('status')
                }
        else:
            return {'success': False, 'error': 'No recipients'}
            
    except Exception as e:
        logger.error(f"Error sending SMS via AfricasTalking: {str(e)}")
        return {'success': False, 'error': str(e)}


def send_sms_twilio(phone_number, message):
    """
    Send SMS via Twilio.
    
    Args:
        phone_number: Phone number (e.g., +234XXXXXXXXXX)
        message: SMS message
    
    Returns:
        dict: {'success': bool, 'message_id': str}
    """
    try:
        from twilio.rest import Client
        
        # Get credentials from settings
        account_sid = getattr(settings, 'TWILIO_ACCOUNT_SID', '')
        auth_token = getattr(settings, 'TWILIO_AUTH_TOKEN', '')
        from_number = getattr(settings, 'TWILIO_PHONE_NUMBER', '')
        
        if not all([account_sid, auth_token, from_number]):
            return {'success': False, 'error': 'Twilio not configured'}
        
        # Initialize client
        client = Client(account_sid, auth_token)
        
        # Send SMS
        message_obj = client.messages.create(
            body=message,
            from_=from_number,
            to=phone_number
        )
        
        return {
            'success': True,
            'message_id': message_obj.sid,
            'status': message_obj.status
        }
        
    except Exception as e:
        logger.error(f"Error sending SMS via Twilio: {str(e)}")
        return {'success': False, 'error': str(e)}


def send_sms_termii(phone_number, message):
    """
    Send SMS via Termii.
    
    Args:
        phone_number: Phone number (e.g., 234XXXXXXXXXX - no +)
        message: SMS message
    
    Returns:
        dict: {'success': bool, 'message_id': str}
    """
    try:
        # Get credentials from settings
        api_key = getattr(settings, 'TERMII_API_KEY', '')
        sender_id = getattr(settings, 'TERMII_SENDER_ID', 'SwiftRide')
        
        if not api_key:
            return {'success': False, 'error': 'Termii not configured'}
        
        # Remove + if present
        if phone_number.startswith('+'):
            phone_number = phone_number[1:]
        
        # Prepare payload
        url = 'https://api.ng.termii.com/api/sms/send'
        payload = {
            'to': phone_number,
            'from': sender_id,
            'sms': message,
            'type': 'plain',
            'channel': 'generic',
            'api_key': api_key
        }
        
        # Send request
        response = requests.post(url, json=payload, timeout=10)
        
        if response.status_code == 200:
            result = response.json()
            return {
                'success': True,
                'message_id': result.get('message_id'),
                'balance': result.get('balance')
            }
        else:
            return {
                'success': False,
                'error': response.text
            }
            
    except Exception as e:
        logger.error(f"Error sending SMS via Termii: {str(e)}")
        return {'success': False, 'error': str(e)}


# ========================================
# EMAIL
# ========================================

def send_email_notification(to_email, subject, body, html_body=None):
    """
    Send email notification.
    
    Args:
        to_email: Recipient email address
        subject: Email subject
        body: Plain text body
        html_body: HTML body (optional)
    
    Returns:
        dict: {'success': bool}
    """
    try:
        from_email = getattr(settings, 'DEFAULT_FROM_EMAIL', 'noreply@swiftride.com')
        
        send_mail(
            subject=subject,
            message=body,
            from_email=from_email,
            recipient_list=[to_email],
            html_message=html_body,
            fail_silently=False
        )
        
        return {'success': True}
        
    except Exception as e:
        logger.error(f"Error sending email: {str(e)}")
        return {'success': False, 'error': str(e)}


def send_ride_receipt_email(user, ride):
    """
    Send ride receipt via email.
    
    Args:
        user: User object
        ride: Ride object
    
    Returns:
        dict: {'success': bool}
    """
    try:
        if not user.email:
            return {'success': False, 'error': 'User has no email'}
        
        # Prepare context for email template
        context = {
            'user': user,
            'ride': ride,
            'pickup_address': ride.pickup_address,
            'dropoff_address': ride.dropoff_address,
            'fare': ride.final_fare,
            'driver': ride.driver.user if ride.driver else None,
            'date': ride.created_at
        }
        
        # Render email templates
        subject = f'SwiftRide Receipt - Ride #{ride.id}'
        text_body = render_to_string('emails/ride_receipt.txt', context)
        html_body = render_to_string('emails/ride_receipt.html', context)
        
        return send_email_notification(
            to_email=user.email,
            subject=subject,
            body=text_body,
            html_body=html_body
        )
        
    except Exception as e:
        logger.error(f"Error sending ride receipt email: {str(e)}")
        return {'success': False, 'error': str(e)}


def send_weekly_summary_email(user):
    """
    Send weekly activity summary email to user.
    
    Args:
        user: User object
    
    Returns:
        dict: {'success': bool}
    """
    try:
        if not user.email:
            return {'success': False, 'error': 'User has no email'}
        
        from datetime import timedelta
        from django.utils import timezone
        from rides.models import Ride
        
        # Get user's rides from last week
        week_ago = timezone.now() - timedelta(days=7)
        rides = Ride.objects.filter(
            rider=user,
            status='completed',
            created_at__gte=week_ago
        )
        
        total_rides = rides.count()
        total_spent = sum(ride.final_fare for ride in rides)
        
        context = {
            'user': user,
            'total_rides': total_rides,
            'total_spent': total_spent,
            'rides': rides[:5]  # Show top 5 recent rides
        }
        
        subject = 'Your SwiftRide Weekly Summary'
        text_body = render_to_string('emails/weekly_summary.txt', context)
        html_body = render_to_string('emails/weekly_summary.html', context)
        
        return send_email_notification(
            to_email=user.email,
            subject=subject,
            body=text_body,
            html_body=html_body
        )
        
    except Exception as e:
        logger.error(f"Error sending weekly summary email: {str(e)}")
        return {'success': False, 'error': str(e)}


# ========================================
# HELPER FUNCTIONS
# ========================================

def get_sms_provider():
    """
    Get configured SMS provider from settings.
    
    Returns:
        str: 'africastalking', 'twilio', 'termii', or 'console'
    """
    return getattr(settings, 'SMS_PROVIDER', 'console')


def send_sms(phone_number, message):
    """
    Send SMS using configured provider.
    
    Args:
        phone_number: Phone number
        message: SMS message
    
    Returns:
        dict: {'success': bool, 'message_id': str}
    """
    provider = get_sms_provider()
    
    if provider == 'console':
        # For development: just log to console
        logger.info(f"SMS to {phone_number}: {message}")
        return {'success': True, 'message_id': 'console'}
    
    elif provider == 'africastalking':
        return send_sms_africastalking(phone_number, message)
    
    elif provider == 'twilio':
        return send_sms_twilio(phone_number, message)
    
    elif provider == 'termii':
        return send_sms_termii(phone_number, message)
    
    else:
        logger.error(f"Unknown SMS provider: {provider}")
        return {'success': False, 'error': 'Invalid SMS provider'}


def format_notification_message(notification_type, data):
    """
    Format notification message based on type.
    
    Args:
        notification_type: Type of notification
        data: Data context
    
    Returns:
        tuple: (title, body)
    """
    templates = {
        'ride_matched': (
            'Driver Found!',
            'Your ride has been matched with a driver. They will arrive shortly.'
        ),
        'ride_accepted': (
            'Ride Accepted',
            'Your driver has accepted your ride request and is on the way.'
        ),
        'ride_started': (
            'Ride Started',
            'Your ride has started. Enjoy your trip!'
        ),
        'ride_completed': (
            'Ride Completed',
            'Your ride has been completed. Thank you for using SwiftRide!'
        ),
        'ride_cancelled': (
            'Ride Cancelled',
            'Your ride has been cancelled.'
        ),
        'driver_arrived': (
            'Driver Arrived',
            'Your driver has arrived at the pickup location.'
        ),
        'payment_received': (
            'Payment Received',
            f'Payment of ₦{data.get("amount", 0)} has been received.'
        ),
        'wallet_credited': (
            'Wallet Credited',
            f'Your wallet has been credited with ₦{data.get("amount", 0)}.'
        ),
        'wallet_debited': (
            'Wallet Debited',
            f'₦{data.get("amount", 0)} has been debited from your wallet.'
        ),
    }
    
    return templates.get(notification_type, ('Notification', 'You have a new notification'))