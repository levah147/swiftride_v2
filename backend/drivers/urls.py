from django.urls import path
from . import views

app_name = 'drivers'

urlpatterns = [
    # Driver Application & Profile
    path('apply/', views.DriverApplicationView.as_view(), name='driver_apply'),
    path('profile/', views.DriverProfileView.as_view(), name='driver_profile'),
    path('status/', views.DriverStatusView.as_view(), name='driver_status'),
    path('documents-status/', views.get_driver_documents_status, name='driver_documents_status'),
    
    # Document & Image Upload
    path('upload-document/', views.UploadVerificationDocumentView.as_view(), name='upload_document'),
    path('upload-vehicle-image/', views.UploadVehicleImageView.as_view(), name='upload_vehicle_image'),
    
    # Admin Endpoints
    path('admin/list/', views.AdminDriverListView.as_view(), name='admin_driver_list'),
    path('admin/approve/<int:pk>/', views.AdminApproveDriverView.as_view(), name='admin_approve_driver'),
    path('admin/reject/<int:pk>/', views.AdminRejectDriverView.as_view(), name='admin_reject_driver'),
    path('admin/verify-document/<int:pk>/', views.AdminVerifyDocumentView.as_view(), name='admin_verify_document'),
]