from datetime import datetime
import decimal

from django.core import exceptions, validators as django_validators
from django.db import models as django_models
from django.utils.translation import gettext_lazy as __
from django_prometheus import models as prom_models  # type: ignore

from barber import value_objects as barber_value_objects
from core import utils, validators as core_validators
from customer import models as customer_models, value_objects as customer_value_objects

SERVICE_OFFER_IMAGE_PATH = 'barber/service_offers/image'
SERVICE_OFFER_THUMBNAIL_PATH = 'barber/service_offers/thumbnail'
MAX_THUMBNAIL_WIDTH = 250
MAX_THUMBNAIL_HEIGHT = 250


class ServiceOffer(prom_models.ExportModelOperationsMixin('barber.service_offer'), django_models.Model):  # type: ignore
    created_at = django_models.DateTimeField(__('Created at'), auto_now_add=True)
    updated_at = django_models.DateTimeField(__('Updated at'), auto_now=True)
    barber_name = django_models.CharField(
        __('Barber Name'),
        max_length=100,
        validators=[django_validators.MinLengthValidator(2)],
    )
    city = django_models.CharField(
        __('City'),
        max_length=100,
        validators=[django_validators.MinLengthValidator(2)],
    )
    address = django_models.CharField(
        __('Address'),
        max_length=100,
        validators=[django_validators.MinLengthValidator(2)],
    )
    description = django_models.CharField(
        __('Description'),
        max_length=400,
    )
    price = django_models.DecimalField(
        __('Price'),
        max_digits=9,
        decimal_places=2,
        validators=[django_validators.MinValueValidator(decimal.Decimal('0.01'))],
    )
    image = django_models.ImageField(
        __('Barber Image'), upload_to=SERVICE_OFFER_IMAGE_PATH, blank=True
    )
    thumbnail = django_models.ImageField(
        __('Barber Thumbnail'), upload_to=SERVICE_OFFER_THUMBNAIL_PATH, blank=True
    )
    specialization = django_models.CharField(
        __('Specialization'),
        **utils.enum_to_char_field_args(barber_value_objects.BarberSpecialization),
    )
    status = django_models.CharField(
        __('Status'), **utils.enum_to_char_field_args(barber_value_objects.OfferStatus)
    )
    open_hours = django_models.CharField(
        __('Open Hours'), **utils.enum_to_char_field_args(barber_value_objects.OpenHours)
    )
    working_days = django_models.CharField(
        __('Working Days'), **utils.enum_to_char_field_args(barber_value_objects.WorkingDays)
    )
    author = django_models.ForeignKey('authentication.User', on_delete=django_models.PROTECT)

    def __str__(self) -> str:
        return f'{self.barber_name}, {self.address} {self.city}'


class ServiceUnavailability(
    prom_models.ExportModelOperationsMixin('barber.service_unavailability'), django_models.Model  # type: ignore
):
    created_at = django_models.DateTimeField(__('Created at'), auto_now_add=True)
    updated_at = django_models.DateTimeField(__('Updated at'), auto_now=True)
    start_date = django_models.DateField(
        __('Start Date'), validators=[core_validators.DateNotInThePastValidator()]
    )
    end_date = django_models.DateField(__('End Date'))
    reason = django_models.CharField(
        __('Reason'),
        max_length=400,
    )
    service_offer = django_models.ForeignKey('barber.ServiceOffer', on_delete=django_models.PROTECT)

    def __str__(self) -> str:
        return f'{self.start_date}-{self.end_date}'

    def clean(self) -> None:
        self._check_end_is_higher_or_equal_to_start()
        self._check_if_service_ordered_in_absence_period()
        self._check_if_not_overlapping_absence()

    def _check_end_is_higher_or_equal_to_start(self) -> None:
        if self.start_date and self.end_date and self.start_date > self.end_date:
            raise exceptions.ValidationError(__('End date must be higher or equal to start date.'))

    def _check_if_service_ordered_in_absence_period(self) -> None:
        if self.start_date and self.end_date and self.service_offer:
            time_range = (
                datetime(self.start_date.year, self.start_date.month, self.start_date.day),
                datetime(self.end_date.year, self.end_date.month, self.end_date.day, 23),
            )
            service_orders = (
                customer_models.ServiceOrder.objects.filter(
                    offer=self.service_offer, service_time__range=time_range
                )
                .exclude(status=customer_value_objects.ServiceOrderStatus.CLOSED.name)
                .first()
            )
            if service_orders is not None:
                raise exceptions.ValidationError(
                    __('Service ordered in unavailability period. Cancel it first.')
                )

    def _check_if_not_overlapping_absence(self) -> None:
        if self.start_date and self.end_date:
            existing_absences = (
                ServiceUnavailability.objects.filter(
                    service_offer=self.service_offer, end_date__gte=self.start_date
                )
                .exclude(id=self.id)
                .all()
            )
            for absence in existing_absences:
                start_date_overlaps = self.start_date <= absence.start_date <= self.end_date
                end_date_overlaps = self.start_date <= absence.end_date <= self.end_date
                both_dates_overlap = (
                    absence.start_date < self.start_date and absence.end_date > self.end_date
                )
                if start_date_overlaps or end_date_overlaps or both_dates_overlap:
                    raise exceptions.ValidationError(__('Overlapping unavailability found.'))
