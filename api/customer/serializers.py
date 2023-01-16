from datetime import date, datetime

from django.utils.translation import gettext_lazy as __
from rest_framework import serializers

from barber import models as barber_models, value_objects as barber_value_objects
from core import validators
from customer import models as customer_models, value_objects as customer_value_objects


class BookServiceSerializer(serializers.ModelSerializer):

    service_time = serializers.CharField(trim_whitespace=True)

    class Meta:
        model = customer_models.ServiceOrder
        fields = ('customer', 'service_time', 'offer')
        extra_kwargs = {
            'offer': {'error_messages': {'does_not_exist': __('Invalid service offer id.')}}
        }

    def validate_service_time(self, service_time: str) -> datetime:
        try:
            service_datetime = datetime.fromisoformat(service_time)
        except ValueError:
            raise serializers.ValidationError(__('Invalid service time format.'))
        validators.FullOrHalfHourValidator()(service_datetime)
        self._validate_if_date_not_from_the_past(service_datetime)
        self._validate_if_not_too_early_today(service_datetime)
        return service_datetime

    def validate(self, attrs: dict) -> dict:
        validated_data = super().validate(attrs)
        self._validate_if_not_in_unavailability_period(
            validated_data['service_time'].date(), validated_data['offer']
        )
        self._validate_if_working_day(validated_data['service_time'], validated_data['offer'])
        self._validate_if_working_hour(validated_data['service_time'], validated_data['offer'])
        self._validate_if_service_not_ordered_yet(
            validated_data['service_time'], validated_data['offer']
        )
        return validated_data

    def _validate_if_date_not_from_the_past(self, service_time: datetime) -> None:
        if service_time.date() < date.today():
            raise serializers.ValidationError(__('Invalid service date.'))

    def _validate_if_not_too_early_today(self, service_time: datetime) -> None:
        now = datetime.now()
        if service_time.date() == now.date() and (
            service_time.hour < now.hour
            or (service_time.hour == now.hour and service_time.minute <= now.minute)
        ):
            raise serializers.ValidationError(__('Invalid service time.'))

    def _validate_if_not_in_unavailability_period(
        self, service_date: date, service_offer: barber_models.ServiceOffer
    ) -> None:
        unavailability = barber_models.ServiceUnavailability.objects.filter(
            service_offer=service_offer, start_date__lte=service_date, end_date__gte=service_date
        ).first()
        if unavailability is not None:
            raise serializers.ValidationError(__('Service not available at this time.'))

    def _validate_if_working_day(
        self, service_time: datetime, service_offer: barber_models.ServiceOffer
    ) -> None:
        if (
            service_offer.working_days == barber_value_objects.WorkingDays.MONDAY_FRIDAY.name
            and service_time.weekday() > 4
        ) or (
            service_offer.working_days == barber_value_objects.WorkingDays.MONDAY_SATURDAY.name
            and service_time.weekday() > 5
        ):
            raise serializers.ValidationError(__('Service not available in this day of the week.'))

    def _validate_if_working_hour(
        self, service_time: datetime, service_offer: barber_models.ServiceOffer
    ) -> None:
        hour = service_time.hour
        error_message = __('Service not available at this hour of the day.')
        invalid_8_4 = (
            service_offer.open_hours == barber_value_objects.OpenHours.FROM_8AM_TO_4PM.name
            and (hour < 8 or hour >= 16)
        )
        invalid_9_5 = (
            service_offer.open_hours == barber_value_objects.OpenHours.FROM_9AM_TO_5PM.name
            and (hour < 9 or hour >= 17)
        )
        invalid_10_6 = (
            service_offer.open_hours == barber_value_objects.OpenHours.FROM_10AM_TO_6PM.name
            and (hour < 10 or hour >= 18)
        )
        invalid_11_7 = (
            service_offer.open_hours == barber_value_objects.OpenHours.FROM_11AM_TO_7PM.name
            and (hour < 11 or hour >= 19)
        )
        invalid_12_8 = (
            service_offer.open_hours == barber_value_objects.OpenHours.FROM_12AM_TO_8PM.name
            and (hour < 12 or hour >= 20)
        )
        if any((invalid_8_4, invalid_9_5, invalid_10_6, invalid_11_7, invalid_12_8)):
            raise serializers.ValidationError(error_message)

    def _validate_if_service_not_ordered_yet(
        self, service_time: datetime, service_offer: barber_models.ServiceOffer
    ) -> None:
        service_order = (
            customer_models.ServiceOrder.objects.filter(
                offer=service_offer, service_time=service_time
            )
            .exclude(status=customer_value_objects.ServiceOrderStatus.CLOSED.name)
            .first()
        )
        if service_order is not None:
            raise serializers.ValidationError(__('Service for this timebox booked already.'))

    def create(self, validated_data: dict) -> customer_models.ServiceOrder:
        return customer_models.ServiceOrder.objects.create(**validated_data)


class CancelServiceSerializer(serializers.ModelSerializer):

    token = serializers.CharField(max_length=8, min_length=8, trim_whitespace=True)

    class Meta:
        model = customer_models.ServiceOrder
        fields = ('token',)

    def validate_token(self, token: str) -> str:
        self._is_isalnum(token)
        return token.upper()

    def _is_isalnum(self, token: str) -> None:
        if not token.isalnum():
            raise serializers.ValidationError(__('Token must be alphanumeric.'))

    def validate(self, attrs: dict) -> dict:
        self.instance = (
            customer_models.ServiceOrder.objects.filter(
                token=attrs['token'], service_time__gt=datetime.now()
            )
            .exclude(status=customer_value_objects.ServiceOrderStatus.CLOSED.name)
            .first()
        )
        if self.instance is None:
            raise serializers.ValidationError(__('Invalid or inactive token.'))
        return attrs

    def update(
        self, instance: customer_models.ServiceOrder, validated_data: dict
    ) -> customer_models.ServiceOrder:
        instance.status = customer_value_objects.ServiceOrderStatus.CLOSED.name
        instance.save()
        return instance
