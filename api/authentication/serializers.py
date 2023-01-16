from django.utils.translation import gettext_lazy as __
from rest_framework import exceptions, serializers as rest_serializers
from rest_framework_simplejwt import serializers as jwt_serializers, tokens

from authentication import models, value_objects
from core import validators


class RegisterUserSerializer(rest_serializers.ModelSerializer):
    class Meta:
        model = models.User
        fields = ('email', 'password', 'name', 'surname', 'account_type', 'accepted_newsletter')
        write_only_fields = ('password',)

    def validate_account_type(self, value: str) -> str:
        if value not in (
            value_objects.AccountType.BARBER.value,
            value_objects.AccountType.CUSTOMER.value,
        ):
            raise rest_serializers.ValidationError(__(f'"{value}" is not a valid choice.'))
        return value

    def validate_password(self, value: str) -> str:
        validators.PasswordLengthValidator().validate(value)
        return value

    def create(self, validated_data: dict) -> models.User:
        account_type = validated_data.pop('account_type')

        if account_type == value_objects.AccountType.BARBER.value:
            return models.User.objects.create_barber(**validated_data)
        return models.User.objects.create_customer(**validated_data)


class TokenObtainPairAdminSerializer(
    jwt_serializers.TokenObtainSerializer
):  # pylint: disable=W0223
    '''Create access and initial refresh admin tokens.'''

    token_class = tokens.RefreshToken

    def validate(self, attrs: dict) -> dict:
        data = super().validate(attrs)
        self._validate_if_admin()
        refresh = self.get_token(self.user)
        data['access'] = str(refresh.access_token)
        data['refresh'] = str(refresh)
        return data

    def get_token(self, user: models.User) -> tokens.RefreshToken:
        return self.token_class.for_user(user)

    def _validate_if_admin(self) -> None:
        if not self.user.is_admin:
            raise exceptions.AuthenticationFailed(
                self.error_messages['no_active_account'],
                'no_active_account',
            )


class TokenObtainPairBarberSerializer(
    jwt_serializers.TokenObtainSerializer
):  # pylint: disable=W0223
    '''Create access and initial refresh barber tokens.'''

    token_class = tokens.RefreshToken

    def validate(self, attrs: dict) -> dict:
        data = super().validate(attrs)
        self._validate_if_barber()
        refresh = self.get_token(self.user)
        data['access'] = str(refresh.access_token)
        data['refresh'] = str(refresh)
        return data

    def get_token(self, user: models.User) -> tokens.RefreshToken:
        return self.token_class.for_user(user)

    def _validate_if_barber(self) -> None:
        if self.user.account_type != value_objects.AccountType.BARBER.value:
            raise exceptions.AuthenticationFailed(
                self.error_messages['no_active_account'],
                'no_active_account',
            )


class TokenObtainPairCustomerSerializer(
    jwt_serializers.TokenObtainSerializer
):  # pylint: disable=W0223
    '''Create access and initial refresh customer tokens.'''

    token_class = tokens.RefreshToken

    def validate(self, attrs: dict) -> dict:
        data = super().validate(attrs)
        self._validate_if_customer()
        refresh = self.get_token(self.user)
        data['access'] = str(refresh.access_token)
        data['refresh'] = str(refresh)
        return data

    def get_token(self, user: models.User) -> tokens.RefreshToken:
        return self.token_class.for_user(user)

    def _validate_if_customer(self) -> None:
        if self.user.account_type != value_objects.AccountType.CUSTOMER.value:
            raise exceptions.AuthenticationFailed(
                self.error_messages['no_active_account'],
                'no_active_account',
            )
