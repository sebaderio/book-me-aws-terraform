from django.contrib import admin
from django.core import exceptions
from django.utils import timezone
from django.utils.translation import gettext_lazy as __

from authentication import value_objects
from core import utils as core_utils
from core.config import utils as config_utils


def get_email_confirmation_token_expiration_time() -> timezone.datetime:
    '''Get email confirmation token expiration datetime from environment variable.'''
    env_var_name = 'EMAIL_CONFIRMATION_TOKEN_TTL'
    try:
        expiration_time = int(config_utils.get_env_value(env_var_name, '24'))
    except ValueError:
        exceptions.ImproperlyConfigured(f'Set int value for {env_var_name} environment variable.')
    if expiration_time <= 0:
        exceptions.ImproperlyConfigured(
            f'Set positive int value for {env_var_name} environment variable.'
        )
    return timezone.now() + timezone.timedelta(hours=expiration_time)


class AccountStatusFilter(admin.SimpleListFilter):
    '''Custom filter on account_status field in User model.'''

    title = __('Account Status')
    parameter_name = 'account_status'

    def lookups(self, request, model_admin):  # type:ignore
        '''List of available options in proper format.'''
        return core_utils.enum_to_char_field_args_translated(value_objects.AccountStatus)['choices']

    def queryset(self, request, queryset):  # type:ignore
        '''Filter queryset according to the specified option.'''
        selected_option = self.value()
        if selected_option is not None:
            return queryset.filter(account_status=selected_option)
        return queryset


class AccountTypeFilter(admin.SimpleListFilter):
    '''Custom filter on account_type field in User model.'''

    title = __('Account Type')
    parameter_name = 'account_type'

    def lookups(self, request, model_admin):  # type:ignore
        '''List of available options in proper format.'''
        return core_utils.enum_to_char_field_args_translated(value_objects.AccountType)['choices']

    def queryset(self, request, queryset):  # type:ignore
        '''Filter queryset according to the specified option.'''
        selected_option = self.value()
        if selected_option is not None:
            return queryset.filter(account_type=selected_option)
        return queryset
