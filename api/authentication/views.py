import uuid

from django import urls
from django.utils import timezone
from django.utils.translation import gettext_lazy as __
from rest_framework import request, response, status, views as rest_views
from rest_framework_simplejwt import views as jwt_views

from authentication import exceptions, models, serializers, value_objects
from tasks import email_tasks


class AccountActivationView(rest_views.APIView):
    def get(self, request: request.Request, token: str) -> response.Response:
        uuid_token = self._get_uuid_from_token(token)
        user = self._get_user_by_token(uuid_token)
        self._check_if_user_under_verification(user)
        self._check_if_activation_link_not_expired(user)
        user.account_status = value_objects.AccountStatus.ACTIVE.value
        user.save()
        return response.Response(
            {'detail': __('Account has been activated.')}, status=status.HTTP_200_OK
        )

    def _get_uuid_from_token(self, token: str) -> uuid.UUID:
        try:
            return uuid.UUID(token)
        except ValueError:
            raise exceptions.AccountActivationFailedException(__('Invalid link.'))

    def _get_user_by_token(self, token: uuid.UUID) -> models.User:
        user = models.User.objects.filter(email_confirmation_token=token).first()
        if user is None:
            raise exceptions.AccountActivationFailedException(__('Invalid link.'))
        return user

    def _check_if_user_under_verification(self, user: models.User) -> None:
        if user.account_status != value_objects.AccountStatus.UNDER_VERIFICATION.value:
            raise exceptions.AccountActivationFailedException(
                __('This account has already been activated.')
            )

    def _check_if_activation_link_not_expired(self, user: models.User) -> None:
        if user.email_confirmation_token_ttl < timezone.now():
            user.hard_delete()
            raise exceptions.AccountActivationFailedException(
                __('Account activation link has expired. Create account again.')
            )


class RegisterUserView(rest_views.APIView):
    def post(self, request: request.Request) -> response.Response:
        user_serializer = serializers.RegisterUserSerializer(data=request.data)
        if user_serializer.is_valid(raise_exception=True):
            user = user_serializer.create(user_serializer.validated_data)
            activation_link = self._generate_account_activation_link(
                request, str(user.email_confirmation_token)
            )
            self._send_account_activation_email(user, activation_link)
            response_message = (
                'Thank You for registering. An email with account activation '
                'link was sent to You. Check your mailbox.'
            )
        return response.Response({'detail': __(response_message)}, status=status.HTTP_201_CREATED)

    def _send_account_activation_email(self, user: models.User, activation_link: str) -> None:
        template_data = {
            'activation_link': activation_link,
            'user_email': user.email,
            'user_name': f'{user.name} {user.surname}',
        }
        email_tasks.send_email_with_account_activation_link.delay(user.email, template_data)

    def _generate_account_activation_link(self, request: request.Request, token: str) -> str:
        link_path = urls.reverse('account-activation-link', kwargs={'token': token})
        return request.build_absolute_uri(link_path)


class TokenObtainPairAdminView(jwt_views.TokenViewBase):

    serializer_class = serializers.TokenObtainPairAdminSerializer


class TokenObtainPairBarberView(jwt_views.TokenViewBase):

    serializer_class = serializers.TokenObtainPairBarberSerializer


class TokenObtainPairCustomerView(jwt_views.TokenViewBase):

    serializer_class = serializers.TokenObtainPairCustomerSerializer


class PingView(rest_views.APIView):

    def get(self, request: request.Request) -> response.Response:
        return response.Response({'ping': 'pong'})
