# type:ignore
from django.contrib import admin
from django.utils.translation import gettext_lazy as __

from barber import value_objects
from core import utils


class OfferStatusFilter(admin.SimpleListFilter):
    '''Custom filter on status field in ServiceOffer model.'''

    title = __('Offer Status')
    parameter_name = 'status'

    def lookups(self, request, model_admin):
        '''List of available options in proper format.'''
        return utils.enum_to_char_field_args_translated(value_objects.OfferStatus)['choices']

    def queryset(self, request, queryset):
        '''Filter queryset according to the specified option.'''
        selected_option = self.value()
        if selected_option is not None:
            return queryset.filter(status=selected_option)
        return queryset


class OpenHoursFilter(admin.SimpleListFilter):
    '''Custom filter on open_hours field in ServiceOffer model.'''

    title = __('Open Hours')
    parameter_name = 'open_hours'

    def lookups(self, request, model_admin):
        '''List of available options in proper format.'''
        return utils.enum_to_char_field_args_translated(value_objects.OpenHours)['choices']

    def queryset(self, request, queryset):
        '''Filter queryset according to the specified option.'''
        selected_option = self.value()
        if selected_option is not None:
            return queryset.filter(open_hours=selected_option)
        return queryset


class WorkingDaysFilter(admin.SimpleListFilter):
    '''Custom filter on working_days field in ServiceOffer model.'''

    title = __('Working Days')
    parameter_name = 'working_days'

    def lookups(self, request, model_admin):
        '''List of available options in proper format.'''
        return utils.enum_to_char_field_args_translated(value_objects.WorkingDays)['choices']

    def queryset(self, request, queryset):
        '''Filter queryset according to the specified option.'''
        selected_option = self.value()
        if selected_option is not None:
            return queryset.filter(working_days=selected_option)
        return queryset
