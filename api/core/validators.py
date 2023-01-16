import datetime
from typing import Optional

from django.contrib.auth import models
from django.core import exceptions
from django.utils import deconstruct
from django.utils.translation import gettext_lazy as __


class PasswordLengthValidator:
    '''Validate if password is between 8 and 30 characters length.'''

    def validate(
        self, password: str, user: Optional[models.AbstractUser] = None  # pylint: disable=W0613
    ) -> str:
        error_message = __('Provide password that is between 8 and 30 characters length.')
        if password is not None:
            if len(password) < 8 or len(password) > 30:
                raise exceptions.ValidationError(error_message)
        return password

    def get_help_text(self) -> str:
        return __('Password must be between 8 and 30 characters length.')


@deconstruct.deconstructible
class FullOrHalfHourValidator:
    '''Validate if datetime is full or half hour.

    Methods __init__ and __eq__ needed only to make validator serializable.
    Migration generator was not able to serialize it. Another solution
    would be to create validator functions instead of classes, but it
    breaks the flow of django field validators.
    '''

    def __init__(self) -> None:
        self.dummy = 1

    def __call__(self, datetime: datetime.datetime) -> None:
        error_message = __('Provide datetime that is full or half hour.')
        if datetime is not None:
            minute = datetime.minute
            second = datetime.second
            microsecond = datetime.microsecond
            if minute not in (0, 30) or second != 0 or microsecond != 0:
                raise exceptions.ValidationError(error_message)

    def __eq__(self, other: object) -> bool:
        return self.dummy == other.dummy  # type:ignore


@deconstruct.deconstructible
class DateNotInThePastValidator:
    '''Validate if date is today or in the future.

    Methods __init__ and __eq__ needed only to make validator serializable.
    Migration generator was not able to serialize it. Another solution
    would be to create validator functions instead of classes, but it
    breaks the flow of django field validators.
    '''

    def __init__(self) -> None:
        self.dummy = 1

    def __call__(self, date: datetime.date) -> None:
        error_message = __('Provide date that is today or in the future.')
        if date is not None and date.today() > date:
            raise exceptions.ValidationError(error_message)

    def __eq__(self, other: object) -> bool:
        return self.dummy == other.dummy  # type:ignore
