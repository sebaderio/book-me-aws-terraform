from django.urls import path

from customer import views

urlpatterns = [
    path('service_order/', views.ServiceOrderView.as_view(), name='book-cancel-barber-service'),
]
