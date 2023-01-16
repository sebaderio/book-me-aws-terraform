import uuid

from django.contrib.auth import models as auth_models, password_validation
from django.core import validators
from django.db import models
from django.utils.translation import gettext_lazy as __
from django_prometheus import models as prom_models  # type: ignore

from authentication import utils as auth_utils, value_objects
from core import utils as core_utils


class UserManager(auth_models.BaseUserManager):
    '''Form for creating all types of users.'''

    def create_admin(self, email: str, name: str, password: str, surname: str) -> 'User':
        return self._create_user(
            accepted_newsletter=False,
            account_type=value_objects.AccountType.ADMIN,
            email=email,
            name=name,
            password=password,
            surname=surname,
        )

    def create_barber(  # pylint: disable=too-many-arguments
        self, accepted_newsletter: bool, email: str, name: str, password: str, surname: str
    ) -> 'User':
        return self._create_user(
            accepted_newsletter=accepted_newsletter,
            account_type=value_objects.AccountType.BARBER,
            email=email,
            name=name,
            password=password,
            surname=surname,
        )

    def create_customer(  # pylint: disable=too-many-arguments
        self, accepted_newsletter: bool, email: str, name: str, password: str, surname: str
    ) -> 'User':
        return self._create_user(
            accepted_newsletter=accepted_newsletter,
            account_type=value_objects.AccountType.CUSTOMER,
            email=email,
            name=name,
            password=password,
            surname=surname,
        )

    def create_superuser(self, email: str, name: str, password: str, surname: str) -> 'User':
        return self._create_user(
            accepted_newsletter=False,
            account_type=value_objects.AccountType.ADMIN,
            email=email,
            name=name,
            password=password,
            surname=surname,
        )

    def _create_user(  # pylint: disable=too-many-arguments
        self,
        accepted_newsletter: bool,
        account_type: value_objects.AccountType,
        email: str,
        name: str,
        password: str,
        surname: str,
    ) -> 'User':
        user = self.model(
            accepted_newsletter=accepted_newsletter,
            account_type=account_type.name,
            email=self.normalize_email(email),
            name=name,
            surname=surname,
        )
        password_validation.validate_password(password)
        user.set_password(password)
        user.save(using=self._db)
        return user


class User(
    prom_models.ExportModelOperationsMixin('authentication.user'), auth_models.AbstractBaseUser, auth_models.PermissionsMixin  # type: ignore
):
    id = models.AutoField(primary_key=True)
    email = models.EmailField(
        __('Email'),
        max_length=150,
        unique=True,
    )
    name = models.CharField(
        __('Name'),
        max_length=100,
        validators=[validators.MinLengthValidator(2)],
    )
    surname = models.CharField(
        __('Surname'),
        max_length=150,
        validators=[validators.MinLengthValidator(2)],
    )
    created_at = models.DateTimeField(__('Created at'), auto_now_add=True)
    updated_at = models.DateTimeField(__('Updated at'), auto_now=True)
    email_confirmation_token = models.UUIDField(__('Email Confirmation Token'), default=uuid.uuid4)
    email_confirmation_token_ttl = models.DateTimeField(
        __('Email Confirmation Token TTL'),
        default=auth_utils.get_email_confirmation_token_expiration_time,
    )
    account_status = models.CharField(
        __('Account Status'),
        default=value_objects.AccountStatus.UNDER_VERIFICATION.name,
        **core_utils.enum_to_char_field_args(value_objects.AccountStatus),
    )
    account_type = models.CharField(
        __('Account Type'), **core_utils.enum_to_char_field_args(value_objects.AccountType)
    )
    accepted_newsletter = models.BooleanField(__('Accepted Newsletter'), default=False)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['name', 'surname']

    objects = UserManager()

    def __str__(self) -> str:
        '''Human readable representation of object.'''

        return f'{self.name} {self.surname} {self.email}'

    @property
    def is_active(self) -> bool:  # type:ignore
        return (
            value_objects.AccountStatus(self.account_status) == value_objects.AccountStatus.ACTIVE
        )

    @property
    def is_admin(self) -> bool:
        return value_objects.AccountType(self.account_type) == value_objects.AccountType.ADMIN

    @property
    def is_staff(self) -> bool:
        return value_objects.AccountType.can_login_to_admin_panel(
            value_objects.AccountType(self.account_type)
        )

    @property
    def is_superuser(self) -> bool:  # type:ignore
        return value_objects.AccountType(self.account_type) == value_objects.AccountType.ADMIN

    def delete(self) -> None:  # type: ignore # pylint: disable=arguments-differ
        '''Override model delete method to soft delete User.'''
        if self.account_status not in (
            value_objects.AccountStatus.CLOSED.name,
            value_objects.AccountStatus.DELETED.name,
        ):
            self.account_status = value_objects.AccountStatus.CLOSED.name
            self.save()

    def hard_delete(self) -> None:
        super().delete()
