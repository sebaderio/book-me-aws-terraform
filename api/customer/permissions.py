from django.views import generic
from rest_framework import permissions, request

from authentication import value_objects


class IsAuthenticatedCustomer(permissions.BasePermission):
    '''Allows access only to authenticated users with account type CUSTOMER.'''

    def has_permission(self, request: request.Request, view: generic.View) -> bool:
        return bool(
            request.user
            and request.user.is_authenticated
            and request.user.account_type == value_objects.AccountType.CUSTOMER.name
        )
