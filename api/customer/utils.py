# type:ignore
from datetime import datetime, timedelta

from django.contrib import admin
from django.utils.translation import gettext_lazy as __
from shortuuid import ShortUUID

from core import utils
from customer import value_objects


def generate_short_uuid() -> str:
    '''Generate 8 length uuid.'''
    return ShortUUID().random(length=8).upper()


class ServiceOrderStatusFilter(admin.SimpleListFilter):
    '''Custom filter on status field in ServiceOrder model.'''

    title = __('Order Status')
    parameter_name = 'status'

    def lookups(self, request, model_admin):
        '''List of available options in proper format.'''
        return utils.enum_to_char_field_args_translated(value_objects.ServiceOrderStatus)['choices']

    def queryset(self, request, queryset):
        '''Filter queryset according to the specified option.'''
        selected_option = self.value()
        if selected_option is not None:
            return queryset.filter(status=selected_option)
        return queryset


class OrderServiceTimeFilter(admin.SimpleListFilter):
    '''Custom filter on service_time field in ServiceOrder model.'''

    PAST = 'Past'
    PENDING = 'Pending'

    title = __('Service Time')
    parameter_name = 'service_time'

    def lookups(self, request, model_admin):
        '''List of available options in proper format.'''
        return [
            (self.PAST, __(self.PAST)),
            (self.PENDING, __(self.PENDING)),
        ]

    def queryset(self, request, queryset):
        '''Filter queryset according to the specified option.'''
        selected_option = self.value()
        now_minus_30_min = datetime.now() - timedelta(minutes=30)
        if selected_option == self.PAST:
            return queryset.filter(service_time__lte=now_minus_30_min)
        if selected_option == self.PENDING:
            return queryset.filter(service_time__gt=now_minus_30_min)
        return queryset
