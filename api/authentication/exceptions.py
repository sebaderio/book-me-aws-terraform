from rest_framework import exceptions


class AccountActivationFailedException(exceptions.ParseError):
    pass
