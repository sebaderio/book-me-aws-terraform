from django.urls import path

from barber import views

urlpatterns = [
    path(
        'service_offer/<int:id>/',
        views.ServiceOfferViewSet.as_view({'get': 'retrieve'}),
        name='get-service-offer-details',
    ),
    path('service_offers/', views.ServiceOfferListView.as_view(), name='get-filtered-offers-list'),
]
