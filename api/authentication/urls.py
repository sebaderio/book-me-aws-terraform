from django.urls import path
from rest_framework_simplejwt import views as rest_views

from authentication import views as auth_views

urlpatterns = [
    path('login/admin/', auth_views.TokenObtainPairAdminView.as_view(), name='login-admin'),
    path('login/admin/refresh/', rest_views.TokenRefreshView.as_view(), name='login-refresh-admin'),
    path('login/barber/', auth_views.TokenObtainPairBarberView.as_view(), name='login-barber'),
    path(
        'login/barber/refresh/', rest_views.TokenRefreshView.as_view(), name='login-refresh-barber'
    ),
    path(
        'login/customer/', auth_views.TokenObtainPairCustomerView.as_view(), name='login-customer'
    ),
    path(
        'login/customer/refresh/',
        rest_views.TokenRefreshView.as_view(),
        name='login-refresh-customer',
    ),
    path('ping/', auth_views.PingView.as_view(), name='ping'),
    path(
        'register/activate/<slug:token>/',
        auth_views.AccountActivationView.as_view(),
        name='account-activation-link',
    ),
    path('register/', auth_views.RegisterUserView.as_view(), name='register-user'),
]
