from rest_framework import serializers as rest_serializers

from barber import models, value_objects


class ServiceOfferListSerializer(rest_serializers.ModelSerializer):
    class Meta:
        model = models.ServiceOffer
        fields = ('address', 'barber_name', 'city', 'id', 'price', 'thumbnail', 'updated_at')


class ServiceOfferSerializer(rest_serializers.ModelSerializer):
    open_hours = rest_serializers.SerializerMethodField()
    specialization = rest_serializers.SerializerMethodField()
    working_days = rest_serializers.SerializerMethodField()

    class Meta:
        model = models.ServiceOffer
        exclude = ('author', 'created_at', 'image', 'status', 'updated_at')

    def get_open_hours(self, service_offer: models.ServiceOffer) -> str:
        return getattr(value_objects.OpenHours, service_offer.open_hours).value

    def get_specialization(self, service_offer: models.ServiceOffer) -> str:
        return getattr(value_objects.BarberSpecialization, service_offer.specialization).value

    def get_working_days(self, service_offer: models.ServiceOffer) -> str:
        return getattr(value_objects.WorkingDays, service_offer.working_days).value
